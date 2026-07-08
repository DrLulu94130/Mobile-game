import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';

/// A big, bouncy, game-feel button: squashes on press, springs back on
/// release, and fires a light haptic. Two looks:
///  * [JuicyButton.primary] — glowing amber, the "do the fun thing" CTA.
///  * [JuicyButton.ghost] — frosted outline for secondary actions.
class JuicyButton extends StatefulWidget {
  const JuicyButton.primary({
    required this.title,
    required this.onPressed,
    this.subtitle,
    this.icon,
    super.key,
  }) : _ghost = false;

  const JuicyButton.ghost({
    required this.title,
    required this.onPressed,
    this.subtitle,
    this.icon,
    super.key,
  }) : _ghost = true;

  final String title;
  final String? subtitle;
  final IconData? icon;
  final VoidCallback onPressed;
  final bool _ghost;

  @override
  State<JuicyButton> createState() => _JuicyButtonState();
}

class _JuicyButtonState extends State<JuicyButton> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed == value) return;
    setState(() => _pressed = value);
    if (value) HapticFeedback.lightImpact();
  }

  @override
  Widget build(BuildContext context) {
    final ghost = widget._ghost;

    final decoration = ghost
        ? BoxDecoration(
            color: Colors.white.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(26),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.55),
              width: 2,
            ),
          )
        : BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFFD36E), AppColors.glow, Color(0xFFFFA928)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(26),
            boxShadow: [
              BoxShadow(
                color: AppColors.glow.withValues(alpha: _pressed ? 0.25 : 0.55),
                blurRadius: _pressed ? 12 : 26,
                offset: const Offset(0, 6),
              ),
            ],
          );

    final foreground = ghost ? Colors.white : const Color(0xFF3D2E00);

    return GestureDetector(
      onTapDown: (_) => _setPressed(true),
      onTapCancel: () => _setPressed(false),
      onTapUp: (_) => _setPressed(false),
      onTap: () {
        HapticFeedback.selectionClick();
        widget.onPressed();
      },
      child: AnimatedScale(
        scale: _pressed ? 0.93 : 1,
        duration: const Duration(milliseconds: 240),
        curve: Curves.elasticOut,
        child: Container(
          height: 84,
          padding: const EdgeInsets.symmetric(horizontal: 22),
          decoration: decoration,
          child: Row(
            children: [
              if (widget.icon != null) ...[
                Icon(widget.icon, size: 34, color: foreground),
                const SizedBox(width: 16),
              ],
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: TextStyle(
                        color: foreground,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.3,
                      ),
                    ),
                    if (widget.subtitle != null)
                      Text(
                        widget.subtitle!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: foreground.withValues(alpha: 0.75),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, size: 30, color: foreground),
            ],
          ),
        ),
      ),
    );
  }
}
