import 'package:flutter/material.dart';

import '../../../../core/theme/sportify_theme.dart';

class HomeSkeleton extends StatelessWidget {
  const HomeSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: <Widget>[
        const SizedBox(height: SportifySpacing.md),
        const _SkeletonBlock(
          height: 28,
          width: 200,
          margin: EdgeInsets.symmetric(horizontal: SportifySpacing.md),
        ),
        const SizedBox(height: SportifySpacing.md),
        const _SkeletonGrid(),
        for (var i = 0; i < 4; i++) ...<Widget>[
          const SizedBox(height: SportifySpacing.xl),
          const _SkeletonBlock(
            height: 20,
            width: 180,
            margin: EdgeInsets.symmetric(horizontal: SportifySpacing.md),
          ),
          const SizedBox(height: SportifySpacing.sm),
          SizedBox(
            height: 190,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(
                horizontal: SportifySpacing.md,
              ),
              itemBuilder: (_, __) => const _SkeletonCard(),
              separatorBuilder: (_, __) =>
                  const SizedBox(width: SportifySpacing.md),
              itemCount: 4,
            ),
          ),
        ],
        const SizedBox(height: SportifySpacing.xl),
      ],
    );
  }
}

class _SkeletonGrid extends StatelessWidget {
  const _SkeletonGrid();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: SportifySpacing.md),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 6,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: SportifySpacing.sm,
          mainAxisSpacing: SportifySpacing.sm,
          childAspectRatio: 2.8,
        ),
        itemBuilder: (_, __) => const _SkeletonBlock(height: 62),
      ),
    );
  }
}

class _SkeletonCard extends StatelessWidget {
  const _SkeletonCard();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 140,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _SkeletonBlock(height: 140),
          SizedBox(height: SportifySpacing.sm),
          _SkeletonBlock(height: 12),
          SizedBox(height: SportifySpacing.xs),
          _SkeletonBlock(height: 10, width: 100),
        ],
      ),
    );
  }
}

class _SkeletonBlock extends StatelessWidget {
  const _SkeletonBlock({
    required this.height,
    this.width,
    this.margin = EdgeInsets.zero,
  });

  final double height;
  final double? width;
  final EdgeInsetsGeometry margin;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: SportifyColors.card,
        borderRadius: BorderRadius.circular(10),
      ),
    );
  }
}
