import 'package:flutter/material.dart';

import '../../../../core/theme/sportify_theme.dart';
import '../models/home_media_item.dart';
import 'music_card.dart';
import 'section_header.dart';

class HorizontalMusicSection extends StatelessWidget {
  const HorizontalMusicSection({
    super.key,
    required this.title,
    required this.items,
    this.onItemTap,
    this.onSeeAll,
  });

  final String title;
  final List<HomeMediaItem> items;
  final ValueChanged<HomeMediaItem>? onItemTap;
  final VoidCallback? onSeeAll;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const SizedBox.shrink();
    }
    return Column(
      children: <Widget>[
        SectionHeader(
          title: title,
          onSeeAll: onSeeAll,
        ),
        SizedBox(
          height: 210,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: SportifySpacing.md),
            itemCount: items.length,
            separatorBuilder: (_, _) =>
                const SizedBox(width: SportifySpacing.md),
            itemBuilder: (context, index) {
              final item = items[index];
              return MusicCard(
                item: item,
                onTap: onItemTap == null ? null : () => onItemTap!(item),
              );
            },
          ),
        ),
      ],
    );
  }
}
