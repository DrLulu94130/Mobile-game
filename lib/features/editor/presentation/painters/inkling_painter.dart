import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/placed_inkling.dart';
import '../../domain/inkling_shapes.dart';

/// Renders a single [PlacedInkling]: its white body, large eyes, and the
/// camouflage strokes clipped strictly inside the silhouette.
///
/// The painter operates in the Inkling's *local* space — callers apply the
/// translate/scale/rotate transform via a [Transform] or canvas save/restore,
/// so this class only needs a local [size].
class InklingPainter extends CustomPainter {
  const InklingPainter({
    required this.inkling,
    this.showBody = true,
    this.selected = false,
    this.wobble = 0,
  });

  final PlacedInkling inkling;

  /// When false, only the camouflage strokes are drawn (used to preview how
  /// well the creature blends into the photo behind it).
  final bool showBody;

  final bool selected;

  /// Idle animation phase (radians) for a subtle squash-and-stretch.
  final double wobble;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final bodyPath = InklingShapes.body(inkling.species, rect);

    // Clip everything to the silhouette so camouflage never bleeds out.
    canvas.save();
    canvas.clipPath(bodyPath);

    if (showBody) {
      _paintBody(canvas, rect, bodyPath);
    }
    _paintStrokes(canvas, size);
    canvas.restore();

    if (showBody) {
      _paintEyes(canvas, size);
      _paintOutline(canvas, bodyPath);
    }
    if (selected) {
      _paintSelection(canvas, bodyPath);
    }
  }

  void _paintBody(Canvas canvas, Rect rect, Path bodyPath) {
    final base = Paint()..color = AppColors.inklingBody;
    canvas.drawPath(bodyPath, base);

    // Soft inner shading gives the creature volume.
    final shade = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.3, -0.4),
        radius: 1.1,
        colors: [
          Colors.white.withValues(alpha: 0),
          const Color(0xFFDCDAEC).withValues(alpha: 0.55),
        ],
      ).createShader(rect);
    canvas.drawPath(bodyPath, shade);
  }

  void _paintStrokes(Canvas canvas, Size size) {
    for (final stroke in inkling.strokes) {
      if (stroke.points.isEmpty) continue;
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..strokeWidth = stroke.width * size.shortestSide
        ..color = stroke.color;

      if (stroke.isEraser) {
        // Erase reveals the white body beneath by compositing.
        paint
          ..blendMode = BlendMode.srcOver
          ..color = AppColors.inklingBody;
      }

      final path = Path();
      final first = _denorm(stroke.points.first, size);
      path.moveTo(first.dx, first.dy);
      if (stroke.points.length == 1) {
        // A single tap becomes a dot.
        canvas.drawCircle(first, paint.strokeWidth / 2, paint..style = PaintingStyle.fill);
        paint.style = PaintingStyle.stroke;
        continue;
      }
      for (var i = 1; i < stroke.points.length; i++) {
        final p = _denorm(stroke.points[i], size);
        path.lineTo(p.dx, p.dy);
      }
      canvas.drawPath(path, paint);
    }
  }

  void _paintEyes(Canvas canvas, Size size) {
    final eyes = InklingShapes.eyes(inkling.species);
    for (final eye in eyes) {
      final center = _denorm(eye.center, size);
      final r = eye.radius * size.shortestSide;
      // White of the eye.
      canvas.drawCircle(center, r, Paint()..color = Colors.white);
      canvas.drawCircle(
        center,
        r,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = r * 0.14
          ..color = const Color(0xFF2A2740),
      );
      // Pupil, offset slightly for a curious gaze plus wobble life.
      final pupil = center +
          Offset(r * 0.18, r * 0.20) +
          Offset(0, wobble * r * 0.12);
      canvas.drawCircle(pupil, r * 0.5, Paint()..color = const Color(0xFF15132A));
      // Catch-light.
      canvas.drawCircle(
        pupil - Offset(r * 0.18, r * 0.18),
        r * 0.16,
        Paint()..color = Colors.white,
      );
    }
  }

  void _paintOutline(Canvas canvas, Path bodyPath) {
    canvas.drawPath(
      bodyPath,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..color = const Color(0x33000000),
    );
  }

  void _paintSelection(Canvas canvas, Path bodyPath) {
    canvas.drawPath(
      bodyPath,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = AppColors.splash,
    );
  }

  Offset _denorm(Offset p, Size size) =>
      Offset(p.dx * size.width, p.dy * size.height);

  @override
  bool shouldRepaint(covariant InklingPainter old) {
    return old.inkling != inkling ||
        old.showBody != showBody ||
        old.selected != selected ||
        old.wobble != wobble;
  }
}
