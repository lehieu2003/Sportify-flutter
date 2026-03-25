import 'package:flutter/material.dart';

import '../../../../core/theme/sportify_theme.dart';

class ArtworkBox extends StatelessWidget {
  const ArtworkBox({
    super.key,
    required this.seed,
    this.size,
    this.borderRadius = 10,
  });

  final String seed;
  final double? size;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final palette = _paletteFor(seed);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: palette,
        ),
      ),
      child: const Center(
        child: Icon(
          Icons.music_note_rounded,
          color: SportifyColors.textPrimary,
          size: 22,
        ),
      ),
    );
  }

  List<Color> _paletteFor(String value) {
    const palettes = <List<Color>>[
      <Color>[Color(0xFF264653), Color(0xFF2A9D8F)],
      <Color>[Color(0xFF3A0CA3), Color(0xFF4361EE)],
      <Color>[Color(0xFF9D0208), Color(0xFFD00000)],
      <Color>[Color(0xFF2B2D42), Color(0xFF8D99AE)],
      <Color>[Color(0xFF6A040F), Color(0xFFDC2F02)],
      <Color>[Color(0xFF1B4332), Color(0xFF2D6A4F)],
    ];
    final index = value.hashCode.abs() % palettes.length;
    return palettes[index];
  }
}
