import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sportify/features/home/presentation/views/home_screen.dart';

void main() {
  testWidgets('HomeScreen renders Spotify-like sections', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: HomeScreen()));

    await tester.pumpAndSettle(const Duration(milliseconds: 900));

    expect(find.text('Recently Played'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Made For You'),
      320,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Made For You'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Genres / Moods'),
      320,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Genres / Moods'), findsOneWidget);
  });
}
