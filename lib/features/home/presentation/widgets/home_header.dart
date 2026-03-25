import 'package:flutter/material.dart';

import '../../../../core/theme/sportify_theme.dart';

class HomeHeader extends StatelessWidget {
  const HomeHeader({super.key, this.userName});

  final String? userName;

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 18) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        SportifySpacing.md,
        SportifySpacing.md,
        SportifySpacing.md,
        SportifySpacing.sm,
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  _greeting(),
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                if (userName != null && userName!.trim().isNotEmpty)
                  Text(
                    userName!,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
              ],
            ),
          ),
          const _HeaderIconButton(icon: Icons.notifications_outlined),
          const SizedBox(width: SportifySpacing.xs),
          const _HeaderIconButton(icon: Icons.history),
          const SizedBox(width: SportifySpacing.xs),
          const _HeaderIconButton(icon: Icons.settings_outlined),
          const SizedBox(width: SportifySpacing.sm),
          const CircleAvatar(
            radius: 16,
            backgroundColor: SportifyColors.card,
            child: Icon(Icons.person_outline, size: 18),
          ),
        ],
      ),
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  const _HeaderIconButton({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: SportifyColors.card,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: () {},
        child: SizedBox(width: 32, height: 32, child: Icon(icon, size: 18)),
      ),
    );
  }
}
