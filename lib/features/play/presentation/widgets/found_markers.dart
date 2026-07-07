import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../editor/domain/entities/placed_inkling.dart';

/// Draws a success ring over each found Inkling and a fading miss indicator at
/// the last incorrect tap.
class FoundMarkersPainter extends CustomPainter {
  const FoundMarkersPainter({
    required this.inklings,
    required this.foundIds,
    this.lastMiss,
  });

  final List<PlacedInkling> inklings;
  final Set<String> foundIds;
  final Offset? lastMiss;

  @override
  void paint(Canvas canvas, Size size) {
    for (final inkling in inklings) {
      if (!foundIds.contains(inkling.id)) continue;
      final center = Offset(
        inkling.center.dx * size.width,
        inkling.center.dy * size.height,
      );
      final radius = inkling.size / 2 * size.shortestSide + 8;
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4
          ..color = AppColors.success,
      );
      // Check tick.
      final tickPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round
        ..color = AppColors.success;
      final path = Path()
        ..moveTo(center.dx - radius * 0.3, center.dy)
        ..lineTo(center.dx - radius * 0.05, center.dy + radius * 0.28)
        ..lineTo(center.dx + radius * 0.35, center.dy - radius * 0.3);
      canvas.drawPath(path, tickPaint);
    }

    if (lastMiss != null) {
      final p = Offset(lastMiss!.dx * size.width, lastMiss!.dy * size.height);
      canvas.drawCircle(
        p,
        18,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..color = AppColors.coral,
      );
    }
  }

  @override
  bool shouldRepaint(covariant FoundMarkersPainter old) =>
      old.foundIds.length != foundIds.length || old.lastMiss != lastMiss;
}
