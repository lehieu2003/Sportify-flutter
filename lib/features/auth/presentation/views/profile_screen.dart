import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/sportify_theme.dart';
import '../viewmodels/auth_view_model.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthViewModel>(
      builder: (context, vm, _) {
        final user = vm.state.user;
        return ListView(
          padding: const EdgeInsets.all(SportifySpacing.md),
          children: <Widget>[
            CircleAvatar(
              radius: 36,
              child: Text(
                (user?.fullName.isNotEmpty == true)
                    ? user!.fullName.substring(0, 1).toUpperCase()
                    : 'U',
              ),
            ),
            const SizedBox(height: SportifySpacing.md),
            Text(
              user?.fullName ?? 'Unknown User',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: SportifySpacing.xs),
            Text(
              user?.email ?? '',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: SportifySpacing.lg),
            FilledButton.tonal(
              onPressed: vm.signoutAll,
              child: const Text('Sign out all devices'),
            ),
          ],
        );
      },
    );
  }
}
