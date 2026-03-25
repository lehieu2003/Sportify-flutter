import 'package:flutter/material.dart';

import '../../../../core/theme/sportify_theme.dart';

class SectionHeader extends StatelessWidget {
  const SectionHeader({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        SportifySpacing.md,
        SportifySpacing.xl,
        SportifySpacing.md,
        SportifySpacing.sm,
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: SportifyColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          TextButton(onPressed: () {}, child: const Text('See all')),
        ],
      ),
    );
  }
}
