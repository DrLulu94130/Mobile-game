import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// The Inkognito wordmark, rendered as a chunky cartoon logo.
///
/// Draws the title twice — a dark rounded outline behind a white fill with a
/// coloured glow — for a crisp, game-like look. Uses the bundled `LuckiestGuy`
/// font so the title never "pops in" while a web font downloads.
class AppLogoTitle extends StatelessWidget {
  const AppLogoTitle({
    this.fontSize = 46,
    this.letterSpacing = 3,
    super.key,
  });

  final double fontSize;
  final double letterSpacing;

  static const String _word = 'INKOGNITO';
  static const Color _outline = Color(0xFF2B1B7E);

  @override
  Widget build(BuildContext context) {
    final base = TextStyle(
      fontFamily: 'LuckiestGuy',
      fontSize: fontSize,
      letterSpacing: letterSpacing,
      height: 1,
    );

    return Semantics(
      label: _word,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Rounded dark outline drawn behind the fill.
          Text(
            _word,
            style: base.copyWith(
              foreground: Paint()
                ..style = PaintingStyle.stroke
                ..strokeWidth = fontSize * 0.13
                ..strokeJoin = StrokeJoin.round
                ..color = _outline,
            ),
          ),
          // White fill with a hard drop shadow and a soft teal glow.
          Text(
            _word,
            style: base.copyWith(
              color: Colors.white,
              shadows: [
                const Shadow(
                  color: _outline,
                  offset: Offset(0, 4),
                  blurRadius: 0,
                ),
                Shadow(
                  color: AppColors.splash.withValues(alpha: 0.6),
                  offset: const Offset(0, 9),
                  blurRadius: 22,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
