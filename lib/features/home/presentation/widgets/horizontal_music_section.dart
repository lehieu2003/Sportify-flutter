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
  });

  final String title;
  final List<HomeMediaItem> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        SectionHeader(title: title),
        SizedBox(
          height: 210,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: SportifySpacing.md),
            itemCount: items.length,
            separatorBuilder: (_, _) =>
                const SizedBox(width: SportifySpacing.md),
            itemBuilder: (context, index) {
              return MusicCard(item: items[index]);
            },
          ),
        ),
      ],
    );
  }
}
