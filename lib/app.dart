import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/theme/sportify_theme.dart';
import 'features/home/presentation/viewmodels/home_view_model.dart';
import 'navigation/presentation/screens/app_gate.dart';

class SportifyApp extends StatelessWidget {
  const SportifyApp({super.key, required this.homeViewModel});

  final HomeViewModel homeViewModel;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<HomeViewModel>.value(
      value: homeViewModel,
      child: MaterialApp(
        title: 'Sportify Mobile',
        debugShowCheckedModeBanner: false,
        theme: SportifyTheme.dark,
        themeMode: ThemeMode.dark,
        home: const AppGate(),
      ),
    );
  }
}
