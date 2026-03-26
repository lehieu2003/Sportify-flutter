import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/sportify_theme.dart';
import '../../../features/library/presentation/viewmodels/library_view_model.dart';
import 'create_playlist_name_sheet.dart';

class CreateMenuSheet extends StatefulWidget {
  const CreateMenuSheet({super.key});

  @override
  State<CreateMenuSheet> createState() => _CreateMenuSheetState();
}

class _CreateMenuSheetState extends State<CreateMenuSheet> {
  Future<void> _onPlaylistTap() async {
    final created = await showCreatePlaylistNameSheet(context);
    if (created == null || !mounted) return;
    final libraryVm = context.read<LibraryViewModel>();
    await libraryVm.loadSavedTracks();
    if (!mounted) return;
    Navigator.of(context).pop(created);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.all(SportifySpacing.md),
        padding: const EdgeInsets.symmetric(
          vertical: SportifySpacing.md,
          horizontal: SportifySpacing.sm,
        ),
        decoration: BoxDecoration(
          color: const Color(0xFF232323),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            _ActionTile(
              icon: Icons.music_note_outlined,
              title: 'Playlist',
              subtitle: 'Build a playlist with songs, or episodes',
              onTap: _onPlaylistTap,
            ),
            const _ActionTile(
              icon: Icons.groups_outlined,
              title: 'Collaborative Playlist',
              subtitle: 'Invite friends and create something together',
              onTap: null,
            ),
            const _ActionTile(
              icon: Icons.blur_circular_outlined,
              title: 'Blend',
              subtitle: 'Combine tastes in a shared playlist with friends',
              onTap: null,
            ),
            const _ActionTile(
              icon: Icons.waves_outlined,
              title: 'Jam',
              subtitle: 'Listen together from anywhere',
              onTap: null,
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        radius: 24,
        backgroundColor: const Color(0xFF4A4A4A),
        child: Icon(icon, color: SportifyColors.textPrimary),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w700,
          color: SportifyColors.textPrimary,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(color: SportifyColors.textSecondary),
      ),
      onTap: onTap,
    );
  }
}
