import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sportify/features/home/data/models/track.dart';
import 'package:sportify/features/home/data/repositories/home_repository.dart';
import 'package:sportify/features/home/presentation/viewmodels/home_view_model.dart';
import 'package:sportify/features/home/presentation/views/home_screen.dart';

class _FakeRepository implements HomeTracksRepository {
  @override
  Stream<List<Track>> watchTrendingTracks() async* {
    yield const <Track>[
      Track(
        id: '1',
        title: 'First Track',
        artist: 'Artist A',
        thumbnailUrl: '',
      ),
    ];
  }
}

void main() {
  testWidgets('HomeScreen renders track list from ViewModel', (tester) async {
    final vm = HomeViewModel(repository: _FakeRepository());

    await tester.pumpWidget(
      ChangeNotifierProvider<HomeViewModel>.value(
        value: vm,
        child: const MaterialApp(home: HomeScreen()),
      ),
    );

    await tester.pump();

    expect(find.text('First Track'), findsOneWidget);
    expect(find.text('Artist A'), findsOneWidget);
  });
}
