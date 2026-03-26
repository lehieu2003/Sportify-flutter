import 'package:flutter_test/flutter_test.dart';

import 'package:sportify/features/home/data/models/home_feed.dart';
import 'package:sportify/features/home/data/models/track.dart';
import 'package:sportify/features/home/data/repositories/home_repository.dart';
import 'package:sportify/features/home/presentation/viewmodels/home_view_model.dart';

class _FakeHomeRepository implements HomeTracksRepository {
  _FakeHomeRepository(this._feed);

  final HomeFeed _feed;

  @override
  Stream<HomeFeed> watchHomeFeed() async* {
    yield _feed;
  }
}

void main() {
  test('HomeViewModel keeps only valid album entries for album-first sections', () async {
    final feed = HomeFeed(
      quickAccess: const <Track>[
        Track(
          id: 'invalid',
          title: 'No Album',
          subtitle: 'Artist',
          thumbnailUrl: '',
          audioUrl: '',
          albumId: '',
        ),
        Track(
          id: 'valid',
          title: 'Album A',
          subtitle: 'Artist',
          thumbnailUrl: '',
          audioUrl: '',
          albumId: 'album-a',
        ),
      ],
      recentlyPlayed: const <Track>[],
      madeForYou: const <Track>[],
      trending: const <Track>[],
      newReleases: const <Track>[],
      genres: const <Track>[],
    );
    final vm = HomeViewModel(repository: _FakeHomeRepository(feed));

    await vm.loadHomeFeed();

    expect(vm.state.quickAccess.length, 1);
    expect(vm.state.quickAccess.first.albumId, 'album-a');
  });
}
