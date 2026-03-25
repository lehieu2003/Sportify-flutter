import 'package:flutter_test/flutter_test.dart';
import 'package:sportify/features/home/data/models/home_feed.dart';
import 'package:sportify/features/home/data/models/home_section_payload.dart';
import 'package:sportify/features/home/data/models/track.dart';
import 'package:sportify/features/home/data/repositories/home_repository.dart';
import 'package:sportify/features/home/data/services/home_api_service.dart';

class _FakeRemoteDataSource implements HomeRemoteDataSource {
  _FakeRemoteDataSource(this._payload);

  final HomeSectionPayload _payload;

  @override
  Future<HomeSectionPayload> fetchHomePayload() async => _payload;
}

class _InMemoryCacheStore implements HomeCacheStore {
  _InMemoryCacheStore({HomeFeed? initial})
    : _cache = initial ?? HomeFeed.empty();

  HomeFeed _cache;

  @override
  Future<HomeFeed> readFeed() async => _cache;

  @override
  Future<void> writeFeed(HomeFeed feed) async {
    _cache = feed;
  }
}

void main() {
  test('emits cache first then remote and updates cache', () async {
    final cache = _InMemoryCacheStore(
      initial: const HomeFeed(
        quickAccess: <Track>[],
        recentlyPlayed: <Track>[],
        madeForYou: <Track>[],
        trending: <Track>[
          Track(
            id: 'cache-1',
            title: 'Cached',
            subtitle: 'Local',
            thumbnailUrl: '',
          ),
        ],
        newReleases: <Track>[],
        genres: <Track>[],
      ),
    );
    final remote = _FakeRemoteDataSource(
      const HomeSectionPayload(
        quickAccess: <Map<String, dynamic>>[],
        recentlyPlayed: <Map<String, dynamic>>[],
        madeForYou: <Map<String, dynamic>>[],
        trending: <Map<String, dynamic>>[
          <String, dynamic>{'id': '1', 'title': 'Remote One', 'artist': 'Remote Artist'},
        ],
        newReleases: <Map<String, dynamic>>[],
        genres: <Map<String, dynamic>>[],
      ),
    );

    final repository = HomeRepository(service: remote, cacheStore: cache);
    final events = await repository.watchHomeFeed().toList();

    expect(events.length, 2);
    expect(events.first.trending.first.title, 'Cached');
    expect(events.last.trending.first.title, 'Remote One');

    final stored = await cache.readFeed();
    expect(stored.trending.first.title, 'Remote One');
  });
}
