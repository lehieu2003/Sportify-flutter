import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/sportify_theme.dart';
import '../viewmodels/auth_view_model.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Future<void> _showEditProfileDialog(BuildContext context, AuthViewModel vm) async {
    final user = vm.state.user;
    final nameController = TextEditingController(text: user?.fullName ?? '');
    final imageController = TextEditingController(text: user?.imageUrl ?? '');

    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit profile'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Full name'),
              ),
              const SizedBox(height: SportifySpacing.sm),
              TextField(
                controller: imageController,
                decoration: const InputDecoration(labelText: 'Avatar URL'),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                await vm.updateProfile(
                  fullName: nameController.text.trim(),
                  imageUrl: imageController.text.trim(),
                );
                if (!context.mounted) return;
                Navigator.of(context).pop();
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

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
            FilledButton(
              onPressed: vm.state.isSubmitting
                  ? null
                  : () => _showEditProfileDialog(context, vm),
              child: const Text('Edit profile'),
            ),
            const SizedBox(height: SportifySpacing.sm),
            FilledButton.tonal(
              onPressed: vm.state.isSubmitting ? null : vm.signoutAll,
              child: const Text('Sign out all devices'),
            ),
            if (vm.state.errorMessage != null) ...<Widget>[
              const SizedBox(height: SportifySpacing.md),
              Text(
                vm.state.errorMessage!,
                style: const TextStyle(color: SportifyColors.error),
              ),
            ],
          ],
        );
      },
    );
  }
}
