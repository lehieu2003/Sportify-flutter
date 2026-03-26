import 'package:flutter/material.dart';

import '../../../../core/theme/sportify_theme.dart';
import '../models/home_media_item.dart';
import 'artwork_box.dart';

class QuickAccessGrid extends StatelessWidget {
  const QuickAccessGrid({
    super.key,
    required this.items,
    this.onItemTap,
  });

  final List<HomeMediaItem> items;
  final ValueChanged<HomeMediaItem>? onItemTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: SportifySpacing.md),
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        itemCount: items.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: SportifySpacing.sm,
          mainAxisSpacing: SportifySpacing.sm,
          childAspectRatio: 2.35,
        ),
        itemBuilder: (context, index) {
          final item = items[index];
          return Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: onItemTap == null ? null : () => onItemTap!(item),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF232323),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: <Widget>[
                    ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(8),
                        bottomLeft: Radius.circular(8),
                      ),
                      child: ArtworkBox(
                        seed: item.title,
                        size: 56,
                        borderRadius: 0,
                      ),
                    ),
                    const SizedBox(width: SportifySpacing.sm),
                    Expanded(
                      child: Text(
                        item.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: SportifyColors.textPrimary,
                          fontWeight: FontWeight.w700,
                          height: 1.15,
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.more_horiz,
                      size: 18,
                      color: SportifyColors.textSecondary,
                    ),
                    const SizedBox(width: SportifySpacing.xs),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
