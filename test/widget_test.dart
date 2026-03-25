import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sportify/features/home/data/models/home_feed.dart';
import 'package:sportify/features/home/data/models/track.dart';
import 'package:sportify/features/home/data/repositories/home_repository.dart';
import 'package:sportify/features/home/presentation/views/home_screen.dart';
import 'package:sportify/features/home/presentation/viewmodels/home_view_model.dart';

class _FakeHomeRepository implements HomeTracksRepository {
  @override
  Stream<HomeFeed> watchHomeFeed() async* {
    yield const HomeFeed(
      quickAccess: <Track>[
        Track(id: '1', title: 'Liked Songs', subtitle: 'Library', thumbnailUrl: ''),
      ],
      recentlyPlayed: <Track>[
        Track(id: '2', title: 'Recently Played', subtitle: 'Artist', thumbnailUrl: ''),
      ],
      madeForYou: <Track>[
        Track(id: '3', title: 'Made For You', subtitle: 'Artist', thumbnailUrl: ''),
      ],
      trending: <Track>[
        Track(id: '4', title: 'Trending', subtitle: 'Artist', thumbnailUrl: ''),
      ],
      newReleases: <Track>[
        Track(id: '5', title: 'New', subtitle: 'Artist', thumbnailUrl: ''),
      ],
      genres: <Track>[
        Track(id: '6', title: 'Pop', subtitle: '10 tracks', thumbnailUrl: ''),
      ],
    );
  }
}

void main() {
  testWidgets('HomeScreen renders Spotify-like sections', (tester) async {
    final vm = HomeViewModel(repository: _FakeHomeRepository());
    await tester.pumpWidget(
      ChangeNotifierProvider<HomeViewModel>.value(
        value: vm,
        child: const MaterialApp(home: HomeScreen()),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Recently Played'), findsWidgets);
    expect(find.text('Made For You'), findsWidgets);
  });
}
