import 'package:flutter/material.dart';

/// Brand palette for Inkognito.
///
/// The identity is playful, ink-inspired and works in both light and dark
/// themes. Colours are intentionally original to the app.
abstract class AppColors {
  // Brand
  static const Color ink = Color(0xFF6C5CE7); // primary violet
  static const Color inkDeep = Color(0xFF4834D4);
  static const Color splash = Color(0xFF00CEC9); // teal accent
  static const Color glow = Color(0xFFFFC048); // amber highlight
  static const Color coral = Color(0xFFFF6B6B);

  // Surfaces
  static const Color lightBg = Color(0xFFF6F5FB);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceAlt = Color(0xFFEFEDF7);

  // Neutrals
  static const Color textStrong = Color(0xFF1B1A2E);
  static const Color textMuted = Color(0xFF6E6C86);

  static const Color success = Color(0xFF00B894);
  static const Color warning = Color(0xFFFDAA5D);
  static const Color error = Color(0xFFE74C3C);

  /// The signature white body colour of an Inkling creature.
  static const Color inklingBody = Color(0xFFFDFDFF);

  static const LinearGradient brandGradient = LinearGradient(
    colors: [ink, splash],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
