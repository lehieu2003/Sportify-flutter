import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:sportify/features/home/presentation/views/home_screen.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('home screen shows core sections', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: HomeScreen()));

    await tester.pumpAndSettle(const Duration(milliseconds: 900));

    expect(find.text('Recently Played'), findsOneWidget);
    expect(find.text('Made For You'), findsOneWidget);
  });
}
