import 'package:flutter/material.dart';

class SportifyColors {
  static const Color primary = Color(0xFF1DB954);
  static const Color primaryHover = Color(0xFF1ED760);

  static const Color background = Color(0xFF121212);
  static const Color surface = Color(0xFF181818);
  static const Color card = Color(0xFF282828);
  static const Color border = Color(0xFF2A2A2A);

  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB3B3B3);
  static const Color textDisabled = Color(0xFF535353);

  static const Color error = Color(0xFFE22134);
  static const Color success = Color(0xFF1DB954);
  static const Color warning = Color(0xFFFFA42B);
}

class SportifySpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 40;
  static const double xxxl = 48;
}

class SportifyTypography {
  static const TextStyle display = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    color: SportifyColors.textPrimary,
  );

  static const TextStyle heading = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    color: SportifyColors.textPrimary,
  );

  static const TextStyle subheading = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w500,
    color: SportifyColors.textPrimary,
  );

  static const TextStyle body = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: SportifyColors.textSecondary,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w300,
    color: SportifyColors.textDisabled,
  );
}

class SportifyTheme {
  static ThemeData get dark {
    final scheme = const ColorScheme.dark(
      primary: SportifyColors.primary,
      onPrimary: Colors.white,
      secondary: SportifyColors.primaryHover,
      onSecondary: Colors.white,
      surface: SportifyColors.surface,
      onSurface: SportifyColors.textPrimary,
      error: SportifyColors.error,
      onError: Colors.white,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      fontFamilyFallback: const <String>['Inter', 'SF Pro Text', 'Roboto'],
      colorScheme: scheme,
      scaffoldBackgroundColor: SportifyColors.background,
      canvasColor: SportifyColors.surface,
      cardColor: SportifyColors.card,
      dividerColor: SportifyColors.border,
      disabledColor: SportifyColors.textDisabled,
      shadowColor: Colors.transparent,
      appBarTheme: const AppBarTheme(
        backgroundColor: SportifyColors.background,
        foregroundColor: SportifyColors.textPrimary,
        elevation: 0,
      ),
      drawerTheme: const DrawerThemeData(
        backgroundColor: SportifyColors.surface,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        color: SportifyColors.card,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(SportifySpacing.md),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: SportifyColors.surface,
        indicatorColor: SportifyColors.primary.withValues(alpha: 0.18),
        labelTextStyle: WidgetStateProperty.resolveWith<TextStyle>((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              color: SportifyColors.textPrimary,
              fontWeight: FontWeight.w600,
            );
          }
          return const TextStyle(color: SportifyColors.textSecondary);
        }),
        iconTheme: WidgetStateProperty.resolveWith<IconThemeData>((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: SportifyColors.primary);
          }
          return const IconThemeData(color: SportifyColors.textSecondary);
        }),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: SportifyColors.primary,
      ),
      sliderTheme: const SliderThemeData(
        activeTrackColor: SportifyColors.primary,
        thumbColor: SportifyColors.primary,
      ),
      listTileTheme: const ListTileThemeData(
        iconColor: SportifyColors.textSecondary,
        textColor: SportifyColors.textPrimary,
      ),
      textTheme: const TextTheme(
        displayLarge: SportifyTypography.display,
        headlineMedium: SportifyTypography.heading,
        titleMedium: SportifyTypography.subheading,
        bodyMedium: SportifyTypography.body,
        bodySmall: SportifyTypography.caption,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: SportifyColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(
            horizontal: SportifySpacing.lg,
            vertical: SportifySpacing.sm,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          disabledBackgroundColor: SportifyColors.textDisabled,
          disabledForegroundColor: SportifyColors.textSecondary,
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: SportifyColors.border,
        thickness: 1,
      ),
      iconTheme: const IconThemeData(color: SportifyColors.textSecondary),
    );
  }
}
