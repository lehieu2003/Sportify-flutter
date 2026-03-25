import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
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
        id: '10',
        title: 'Integration Song',
        artist: 'Tester',
        thumbnailUrl: '',
      ),
    ];
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('home screen displays loaded tracks', (tester) async {
    final vm = HomeViewModel(repository: _FakeRepository());

    await tester.pumpWidget(
      ChangeNotifierProvider<HomeViewModel>.value(
        value: vm,
        child: const MaterialApp(home: HomeScreen()),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Integration Song'), findsOneWidget);
    expect(find.text('Tester'), findsOneWidget);
  });
}
