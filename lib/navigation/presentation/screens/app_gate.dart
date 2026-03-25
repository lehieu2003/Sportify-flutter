import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_shell.dart';
import 'auth_layout.dart';

class AppGate extends StatefulWidget {
  const AppGate({super.key});

  @override
  State<AppGate> createState() => _AppGateState();
}

class _AppGateState extends State<AppGate> {
  static const _loggedInKey = 'auth.is_logged_in';

  bool _isBootstrapping = true;
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    bootstrap();
  }

  Future<void> bootstrap() async {
    final prefs = await SharedPreferences.getInstance();
    final restoredLoggedIn = prefs.getBool(_loggedInKey) ?? false;
    if (!mounted) return;
    setState(() {
      _isLoggedIn = restoredLoggedIn;
      _isBootstrapping = false;
    });
  }

  Future<void> _setAuth(bool isLoggedIn) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_loggedInKey, isLoggedIn);
    if (!mounted) return;
    setState(() {
      _isLoggedIn = isLoggedIn;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isBootstrapping) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_isLoggedIn) {
      return MainLayout(onLogout: () => _setAuth(false));
    }

    return AuthLayout(onLoginSuccess: () => _setAuth(true));
  }
}
