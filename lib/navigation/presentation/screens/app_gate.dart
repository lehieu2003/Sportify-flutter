import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../features/auth/presentation/viewmodels/auth_view_model.dart';
import '../../../features/player/presentation/viewmodels/player_view_model.dart';
import 'app_shell.dart';
import 'auth_layout.dart';

class AppGate extends StatefulWidget {
  const AppGate({super.key});

  @override
  State<AppGate> createState() => _AppGateState();
}

class _AppGateState extends State<AppGate> {
  bool _hasRestoredPlayback = false;
  bool _hasClearedPlayback = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<AuthViewModel>().bootstrap();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthViewModel>(
      builder: (context, authVm, _) {
        final state = authVm.state;

        if (state.isBootstrapping) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (state.isAuthenticated) {
          if (!_hasRestoredPlayback) {
            _hasRestoredPlayback = true;
            _hasClearedPlayback = false;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              context.read<PlayerViewModel>().restoreSession();
            });
          }
          return MainLayout(onLogout: authVm.signout);
        }

        if (!_hasClearedPlayback) {
          _hasClearedPlayback = true;
          _hasRestoredPlayback = false;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            context.read<PlayerViewModel>().clearLocalState();
          });
        }

        return const AuthLayout();
      },
    );
  }
}
