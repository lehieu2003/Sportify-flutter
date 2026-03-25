import 'package:flutter_test/flutter_test.dart';
import 'package:sportify/features/home/data/models/track.dart';
import 'package:sportify/features/home/data/repositories/home_repository.dart';
import 'package:sportify/features/home/data/services/home_api_service.dart';

class _FakeRemoteDataSource implements HomeRemoteDataSource {
  _FakeRemoteDataSource(this._payload);

  final List<Map<String, dynamic>> _payload;

  @override
  Future<List<Map<String, dynamic>>> fetchTrendingRaw() async => _payload;
}

class _InMemoryCacheStore implements HomeCacheStore {
  _InMemoryCacheStore({List<Track>? initial}) : _cache = initial ?? <Track>[];

  List<Track> _cache;

  @override
  Future<List<Track>> readTracks() async => _cache;

  @override
  Future<void> writeTracks(List<Track> tracks) async {
    _cache = tracks;
  }
}

void main() {
  test('emits cache first then remote and updates cache', () async {
    final cache = _InMemoryCacheStore(
      initial: const <Track>[
        Track(
          id: 'cache-1',
          title: 'Cached',
          artist: 'Local',
          thumbnailUrl: '',
        ),
      ],
    );
    final remote = _FakeRemoteDataSource(<Map<String, dynamic>>[
      <String, dynamic>{'id': 1, 'title': 'Remote One'},
    ]);

    final repository = HomeRepository(service: remote, cacheStore: cache);
    final events = await repository.watchTrendingTracks().toList();

    expect(events.length, 2);
    expect(events.first.first.title, 'Cached');
    expect(events.last.first.title, 'Remote One');

    final stored = await cache.readTracks();
    expect(stored.first.title, 'Remote One');
  });
}
