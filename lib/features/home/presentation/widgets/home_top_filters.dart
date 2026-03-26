import 'package:flutter/material.dart';

import '../../../../core/theme/sportify_theme.dart';

class HomeTopFilters extends StatefulWidget {
  const HomeTopFilters({super.key, this.userInitial = 'H'});

  final String userInitial;

  @override
  State<HomeTopFilters> createState() => _HomeTopFiltersState();
}

class _HomeTopFiltersState extends State<HomeTopFilters> {
  int _selectedIndex = 0;
  static const _labels = <String>['Tất cả', 'Nhạc', 'Podcasts'];

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
          CircleAvatar(
            radius: 20,
            backgroundColor: SportifyColors.primary,
            child: Text(
              widget.userInitial,
              style: const TextStyle(
                color: SportifyColors.background,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: SportifySpacing.md),
          Expanded(
            child: SizedBox(
              height: 38,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _labels.length,
                separatorBuilder: (_, _) => const SizedBox(width: SportifySpacing.sm),
                itemBuilder: (context, index) {
                  final selected = index == _selectedIndex;
                  return Material(
                    color: Colors.transparent,
                    child: ChoiceChip(
                      selected: selected,
                      label: Text(_labels[index]),
                      labelStyle: TextStyle(
                        color: selected ? SportifyColors.background : SportifyColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                      side: BorderSide.none,
                      selectedColor: SportifyColors.primary,
                      backgroundColor: SportifyColors.card,
                      showCheckmark: false,
                      onSelected: (_) {
                        setState(() {
                          _selectedIndex = index;
                        });
                      },
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
