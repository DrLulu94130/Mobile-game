import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Central theme definition. The game ships a single hand-tuned light look;
/// gameplay screens (editor, play, Discover) draw on their own dark stages.
abstract class AppTheme {
  static const double radius = 20;
  static const double radiusSmall = 12;

  static ThemeData get light => _base(
        scheme: const ColorScheme.light(
          primary: AppColors.ink,
          secondary: AppColors.splash,
          tertiary: AppColors.glow,
          surface: AppColors.lightSurface,
          error: AppColors.error,
          onPrimary: Colors.white,
          onSurface: AppColors.textStrong,
        ),
        scaffold: AppColors.lightBg,
        surfaceAlt: AppColors.lightSurfaceAlt,
      );

  static ThemeData _base({
    required ColorScheme scheme,
    required Color scaffold,
    required Color surfaceAlt,
  }) {
    final textTheme = GoogleFonts.plusJakartaSansTextTheme(
      ThemeData.light().textTheme,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: scheme,
      scaffoldBackgroundColor: scaffold,
      textTheme: textTheme,
      splashFactory: InkSparkle.splashFactory,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w800,
        ),
      ),
      cardTheme: CardThemeData(
        color: scheme.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius),
        ),
        clipBehavior: Clip.antiAlias,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(54),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radius),
          ),
          textStyle: textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(54),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radius),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceAlt,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSmall),
          borderSide: BorderSide.none,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius),
        ),
        side: BorderSide.none,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: scheme.surface,
        selectedItemColor: scheme.primary,
        unselectedItemColor: AppColors.textMuted,
        type: BottomNavigationBarType.fixed,
      ),
      extensions: <ThemeExtension<dynamic>>[
        AppSurfaces(surfaceAlt: surfaceAlt),
      ],
    );
  }
}

/// Custom theme extension exposing an alternate surface colour used by cards,
/// inputs and the editor toolbar.
class AppSurfaces extends ThemeExtension<AppSurfaces> {
  const AppSurfaces({required this.surfaceAlt});

  final Color surfaceAlt;

  @override
  ThemeExtension<AppSurfaces> copyWith({Color? surfaceAlt}) =>
      AppSurfaces(surfaceAlt: surfaceAlt ?? this.surfaceAlt);

  @override
  ThemeExtension<AppSurfaces> lerp(
    covariant ThemeExtension<AppSurfaces>? other,
    double t,
  ) {
    if (other is! AppSurfaces) return this;
    return AppSurfaces(
      surfaceAlt: Color.lerp(surfaceAlt, other.surfaceAlt, t)!,
    );
  }
}
