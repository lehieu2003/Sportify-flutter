import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/sportify_theme.dart';
import '../../data/models/user_device_session.dart';
import '../viewmodels/auth_view_model.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<AuthViewModel>().loadDeviceSessions();
    });
  }

  bool _isValidImageUrl(String value) {
    final normalized = value.trim();
    if (normalized.isEmpty) return true;
    final uri = Uri.tryParse(normalized);
    return uri != null && uri.hasScheme && uri.hasAuthority;
  }

  Future<void> _showEditProfileDialog(BuildContext context, AuthViewModel vm) async {
    final user = vm.state.user;
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: user?.fullName ?? '');
    final imageController = TextEditingController(text: user?.imageUrl ?? '');
    String previewUrl = imageController.text.trim();

    await showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Edit profile'),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: SportifyColors.card,
                      backgroundImage: _isValidImageUrl(previewUrl) && previewUrl.isNotEmpty
                          ? NetworkImage(previewUrl)
                          : null,
                      child: previewUrl.isEmpty
                          ? Text(
                              (nameController.text.trim().isNotEmpty
                                      ? nameController.text.trim()[0]
                                      : 'U')
                                  .toUpperCase(),
                            )
                          : null,
                    ),
                    const SizedBox(height: SportifySpacing.md),
                    TextFormField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: 'Full name'),
                      validator: (value) {
                        final normalized = (value ?? '').trim();
                        if (normalized.isEmpty) return 'Full name is required';
                        if (normalized.length < 2) return 'Full name is too short';
                        return null;
                      },
                      onChanged: (_) => setDialogState(() {}),
                    ),
                    const SizedBox(height: SportifySpacing.sm),
                    TextFormField(
                      controller: imageController,
                      decoration: const InputDecoration(labelText: 'Avatar URL'),
                      validator: (value) {
                        final normalized = (value ?? '').trim();
                        if (normalized.isEmpty) return null;
                        return _isValidImageUrl(normalized)
                            ? null
                            : 'Avatar URL is invalid';
                      },
                      onChanged: (value) {
                        setDialogState(() {
                          previewUrl = value.trim();
                        });
                      },
                    ),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: vm.state.isSubmitting
                      ? null
                      : () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: vm.state.isSubmitting
                      ? null
                      : () async {
                          if (!(formKey.currentState?.validate() ?? false)) {
                            return;
                          }
                          await vm.updateProfile(
                            fullName: nameController.text.trim(),
                            imageUrl: imageController.text.trim(),
                          );
                          if (!context.mounted) return;
                          Navigator.of(context).pop();
                        },
                  child: vm.state.isSubmitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  String _sessionSubtitle(UserDeviceSession session) {
    final created = session.createdAt?.toLocal();
    final createdText = created != null
        ? '${created.year}-${created.month.toString().padLeft(2, '0')}-${created.day.toString().padLeft(2, '0')}'
        : 'Unknown date';
    final ip = session.ip.trim().isEmpty ? 'Unknown IP' : session.ip;
    return '$ip • $createdText';
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthViewModel>(
      builder: (context, vm, _) {
        final user = vm.state.user;
        final sessions = vm.state.deviceSessions;
        return Scaffold(
          appBar: AppBar(title: const Text('Profile')),
          body: ListView(
            padding: const EdgeInsets.all(SportifySpacing.md),
            children: <Widget>[
              CircleAvatar(
                radius: 36,
                backgroundColor: SportifyColors.card,
                backgroundImage: (user?.imageUrl.trim().isNotEmpty == true)
                    ? NetworkImage(user!.imageUrl)
                    : null,
                child: (user?.imageUrl.trim().isNotEmpty == true)
                    ? null
                    : Text(
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
              const SizedBox(height: SportifySpacing.lg),
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      'Logged in devices',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ),
                  IconButton(
                    onPressed: vm.state.isLoadingSessions ? null : vm.loadDeviceSessions,
                    icon: const Icon(Icons.refresh),
                  ),
                ],
              ),
              if (vm.state.isLoadingSessions)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: SportifySpacing.sm),
                  child: LinearProgressIndicator(),
                ),
              if (!vm.state.isLoadingSessions && sessions.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: SportifySpacing.sm),
                  child: Text(
                    'No active devices found.',
                    style: TextStyle(color: SportifyColors.textSecondary),
                  ),
                ),
              ...sessions.map(
                (session) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    session.isCurrent ? Icons.phone_android : Icons.devices,
                  ),
                  title: Text(
                    session.userAgent.trim().isEmpty
                        ? 'Unknown device'
                        : session.userAgent,
                  ),
                  subtitle: Text(_sessionSubtitle(session)),
                  trailing: session.isCurrent
                      ? const Chip(label: Text('Current'))
                      : TextButton(
                          onPressed: vm.state.isLoadingSessions
                              ? null
                              : () => vm.revokeDeviceSession(session.id),
                          child: const Text('Sign out'),
                        ),
                ),
              ),
              if (vm.state.errorMessage != null) ...<Widget>[
                const SizedBox(height: SportifySpacing.md),
                Text(
                  vm.state.errorMessage!,
                  style: const TextStyle(color: SportifyColors.error),
                ),
              ],
              if (vm.state.sessionsErrorMessage != null) ...<Widget>[
                const SizedBox(height: SportifySpacing.sm),
                Text(
                  vm.state.sessionsErrorMessage!,
                  style: const TextStyle(color: SportifyColors.error),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
