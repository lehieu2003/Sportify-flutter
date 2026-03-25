import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/theme/sportify_theme.dart';
import 'features/auth/presentation/viewmodels/auth_view_model.dart';
import 'features/home/presentation/viewmodels/home_view_model.dart';
import 'navigation/presentation/screens/app_gate.dart';

class SportifyApp extends StatelessWidget {
  const SportifyApp({
    super.key,
    required this.homeViewModel,
    required this.authViewModel,
  });

  final HomeViewModel homeViewModel;
  final AuthViewModel authViewModel;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<HomeViewModel>.value(value: homeViewModel),
        ChangeNotifierProvider<AuthViewModel>.value(value: authViewModel),
      ],
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
