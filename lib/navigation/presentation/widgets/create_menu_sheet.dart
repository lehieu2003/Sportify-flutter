import 'package:flutter/material.dart';

import '../../../core/theme/sportify_theme.dart';

class CreateMenuSheet extends StatelessWidget {
  const CreateMenuSheet({super.key});

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
          children: const <Widget>[
            _ActionTile(
              icon: Icons.music_note_outlined,
              title: 'Playlist',
              subtitle: 'Build a playlist with songs, or episodes',
            ),
            _ActionTile(
              icon: Icons.groups_outlined,
              title: 'Collaborative Playlist',
              subtitle: 'Invite friends and create something together',
            ),
            _ActionTile(
              icon: Icons.blur_circular_outlined,
              title: 'Blend',
              subtitle: 'Combine tastes in a shared playlist with friends',
            ),
            _ActionTile(
              icon: Icons.waves_outlined,
              title: 'Jam',
              subtitle: 'Listen together from anywhere',
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
  });

  final IconData icon;
  final String title;
  final String subtitle;

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
      onTap: () {},
    );
  }
}
