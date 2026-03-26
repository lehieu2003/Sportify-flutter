import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import 'package:sportify/features/home/data/models/home_feed.dart';
import 'package:sportify/features/home/data/models/track.dart';
import 'package:sportify/features/home/data/repositories/home_repository.dart';
import 'package:sportify/features/home/presentation/viewmodels/home_view_model.dart';
import 'package:sportify/features/home/presentation/views/home_screen.dart';

class _FakeHomeRepository implements HomeTracksRepository {
  _FakeHomeRepository(this._feed);

  final HomeFeed _feed;

  @override
  Stream<HomeFeed> watchHomeFeed() async* {
    yield _feed;
  }
}

Widget _buildTestApp(HomeFeed feed) {
  final vm = HomeViewModel(repository: _FakeHomeRepository(feed));
  return MultiProvider(
    providers: <SingleChildWidget>[
      ChangeNotifierProvider<HomeViewModel>.value(value: vm),
    ],
    child: const MaterialApp(
      home: Scaffold(
        body: HomeScreen(),
      ),
    ),
  );
}

void main() {
  testWidgets('HomeScreen hides empty sections and keeps non-empty section', (tester) async {
    final feed = HomeFeed(
      quickAccess: const <Track>[],
      recentlyPlayed: const <Track>[],
      madeForYou: const <Track>[],
      trending: const <Track>[
        Track(
          id: 't1',
          title: 'Trending Album',
          subtitle: 'Artist',
          thumbnailUrl: '',
          audioUrl: '',
          albumId: 'a1',
          albumTitle: 'Trending Album',
        ),
      ],
      newReleases: const <Track>[],
      genres: const <Track>[],
    );

    await tester.pumpWidget(_buildTestApp(feed));
    await tester.pumpAndSettle();

    expect(find.text('Popular / Trending'), findsOneWidget);
    expect(find.text('Recently Played'), findsNothing);
    expect(find.text('Made For You'), findsNothing);
  });

  testWidgets('HomeScreen shows empty state when all album sections are empty', (tester) async {
    final feed = HomeFeed.empty();

    await tester.pumpWidget(_buildTestApp(feed));
    await tester.pumpAndSettle();

    expect(find.text('No albums yet'), findsOneWidget);
    expect(find.text('Refresh'), findsOneWidget);
  });
}
