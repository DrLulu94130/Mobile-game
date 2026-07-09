import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../domain/masterpieces.dart';

/// Paints one of the [MasterpieceStyle] canvases at any size.
///
/// Every style is deterministic (seeded randomness) so the small preview in
/// the creation flow matches the full-resolution render sent to the editor.
class MasterpiecePainter extends CustomPainter {
  const MasterpiecePainter(this.style);

  final MasterpieceStyle style;

  /// Renders a style offscreen and returns PNG bytes for the editor, sized
  /// to the app's story-style canvas.
  static Future<Uint8List> render(
    MasterpieceStyle style, {
    int width = 1080,
    int height = 1920,
  }) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final size = Size(width.toDouble(), height.toDouble());
    MasterpiecePainter(style).paint(canvas, size);
    final image = await recorder.endRecording().toImage(width, height);
    try {
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      return data!.buffer.asUint8List();
    } finally {
      image.dispose();
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    canvas.clipRect(Offset.zero & size);
    switch (style) {
      case MasterpieceStyle.starryNight:
        _starryNight(canvas, size);
      case MasterpieceStyle.greatWave:
        _greatWave(canvas, size);
      case MasterpieceStyle.waterLilies:
        _waterLilies(canvas, size);
      case MasterpieceStyle.scream:
        _scream(canvas, size);
      case MasterpieceStyle.gridComposition:
        _gridComposition(canvas, size);
      case MasterpieceStyle.goldenGarden:
        _goldenGarden(canvas, size);
    }
  }

  // --- Swirling night sky over a sleeping village. ---
  void _starryNight(Canvas canvas, Size s) {
    final rand = math.Random(7);
    final sky = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF0B1D51), Color(0xFF1D3E8A), Color(0xFF2A5CAD)],
      ).createShader(Offset.zero & s);
    canvas.drawRect(Offset.zero & s, sky);

    // Wind swirls: short curved strokes following circular flows.
    final swirlCentres = [
      Offset(s.width * 0.35, s.height * 0.22),
      Offset(s.width * 0.72, s.height * 0.34),
      Offset(s.width * 0.18, s.height * 0.42),
    ];
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    const swirlColors = [
      Color(0xFF8FB8E8),
      Color(0xFFCBDCF5),
      Color(0xFFF4E58A),
      Color(0xFF4F7DC4),
    ];
    for (final centre in swirlCentres) {
      for (var i = 0; i < 220; i++) {
        final radius = (0.02 + rand.nextDouble() * 0.16) * s.width;
        final start = rand.nextDouble() * 2 * math.pi;
        final sweep = 0.5 + rand.nextDouble() * 1.2;
        stroke
          ..color = swirlColors[rand.nextInt(swirlColors.length)]
              .withValues(alpha: 0.5 + rand.nextDouble() * 0.5)
          ..strokeWidth = (0.004 + rand.nextDouble() * 0.006) * s.width;
        canvas.drawArc(
          Rect.fromCircle(center: centre, radius: radius),
          start,
          sweep,
          false,
          stroke,
        );
      }
    }
    // Horizontal wind streaks between the swirls.
    for (var i = 0; i < 260; i++) {
      final y = rand.nextDouble() * s.height * 0.6;
      final x = rand.nextDouble() * s.width;
      stroke
        ..color = swirlColors[rand.nextInt(swirlColors.length)]
            .withValues(alpha: 0.25 + rand.nextDouble() * 0.4)
        ..strokeWidth = (0.003 + rand.nextDouble() * 0.005) * s.width;
      final wave = Path()..moveTo(x, y);
      wave.quadraticBezierTo(
        x + s.width * 0.05,
        y - s.width * 0.015,
        x + s.width * 0.1,
        y,
      );
      canvas.drawPath(wave, stroke);
    }

    // Crescent moon and stars with glowing halos.
    void glow(Offset c, double r, Color color) {
      canvas.drawCircle(
        c,
        r * 2.2,
        Paint()..color = color.withValues(alpha: 0.25),
      );
      canvas.drawCircle(
        c,
        r * 1.5,
        Paint()..color = color.withValues(alpha: 0.45),
      );
      canvas.drawCircle(c, r, Paint()..color = color);
    }

    glow(
      Offset(s.width * 0.85, s.height * 0.1),
      s.width * 0.06,
      const Color(0xFFF7E27A),
    );
    for (var i = 0; i < 11; i++) {
      glow(
        Offset(rand.nextDouble() * s.width, rand.nextDouble() * s.height * 0.5),
        (0.008 + rand.nextDouble() * 0.014) * s.width,
        const Color(0xFFF4EBB0),
      );
    }

    // Rolling hills and a village with lit windows.
    final hills = Paint()..color = const Color(0xFF16294F);
    final hillPath = Path()
      ..moveTo(0, s.height * 0.72)
      ..quadraticBezierTo(
        s.width * 0.3,
        s.height * 0.64,
        s.width * 0.55,
        s.height * 0.72,
      )
      ..quadraticBezierTo(
        s.width * 0.8,
        s.height * 0.8,
        s.width,
        s.height * 0.7,
      )
      ..lineTo(s.width, s.height)
      ..lineTo(0, s.height)
      ..close();
    canvas.drawPath(hillPath, hills);
    final house = Paint()..color = const Color(0xFF0D1B38);
    final window = Paint()..color = const Color(0xFFF2CD5C);
    for (var i = 0; i < 9; i++) {
      final x = s.width * (0.06 + i * 0.1);
      final y = s.height * (0.78 + rand.nextDouble() * 0.12);
      final w = s.width * 0.07;
      final h = s.width * 0.06;
      canvas.drawRect(Rect.fromLTWH(x, y, w, h), house);
      canvas.drawRect(
        Rect.fromLTWH(x + w * 0.3, y + h * 0.3, w * 0.18, h * 0.3),
        window,
      );
    }

    // The flame-like cypress in the foreground.
    final cypress = Paint()..color = const Color(0xFF0A1526);
    final tree = Path()..moveTo(s.width * 0.12, s.height);
    for (var i = 0; i < 6; i++) {
      final t = i / 6.0;
      tree.quadraticBezierTo(
        s.width * (0.2 - 0.08 * t + (i.isEven ? 0.05 : -0.02)),
        s.height * (0.95 - t * 0.45),
        s.width * (0.14 - 0.02 * t),
        s.height * (0.88 - t * 0.5),
      );
    }
    tree
      ..lineTo(s.width * 0.1, s.height * 0.42)
      ..lineTo(s.width * 0.07, s.height)
      ..close();
    canvas.drawPath(tree, cypress);
  }

  // --- A towering claw of a wave over small boats. ---
  void _greatWave(Canvas canvas, Size s) {
    final rand = math.Random(11);
    canvas.drawRect(
      Offset.zero & s,
      Paint()..color = const Color(0xFFE8DCC0),
    );
    // Distant mountain.
    final mountain = Path()
      ..moveTo(s.width * 0.42, s.height * 0.5)
      ..lineTo(s.width * 0.58, s.height * 0.38)
      ..lineTo(s.width * 0.74, s.height * 0.5)
      ..close();
    canvas.drawPath(mountain, Paint()..color = const Color(0xFF7A6A55));
    canvas.drawPath(
      Path()
        ..moveTo(s.width * 0.53, s.height * 0.42)
        ..lineTo(s.width * 0.58, s.height * 0.38)
        ..lineTo(s.width * 0.63, s.height * 0.42)
        ..close(),
      Paint()..color = Colors.white,
    );

    // Layered rollers in deep prussian blue.
    const blues = [Color(0xFF12395B), Color(0xFF1D4E75), Color(0xFF2A6591)];
    for (var layer = 0; layer < 5; layer++) {
      final baseY = s.height * (0.52 + layer * 0.1);
      final path = Path()..moveTo(0, baseY);
      for (var x = 0.0; x <= s.width; x += s.width / 8) {
        path.quadraticBezierTo(
          x + s.width / 16,
          baseY - s.height * (0.03 + rand.nextDouble() * 0.03),
          x + s.width / 8,
          baseY,
        );
      }
      path
        ..lineTo(s.width, s.height)
        ..lineTo(0, s.height)
        ..close();
      canvas.drawPath(path, Paint()..color = blues[layer % blues.length]);
    }

    // The great claw wave.
    final wave = Path()
      ..moveTo(-s.width * 0.1, s.height * 0.75)
      ..cubicTo(
        s.width * 0.05,
        s.height * 0.35,
        s.width * 0.3,
        s.height * 0.18,
        s.width * 0.62,
        s.height * 0.22,
      )
      ..cubicTo(
        s.width * 0.5,
        s.height * 0.26,
        s.width * 0.42,
        s.height * 0.34,
        s.width * 0.46,
        s.height * 0.42,
      )
      ..cubicTo(
        s.width * 0.3,
        s.height * 0.42,
        s.width * 0.2,
        s.height * 0.6,
        s.width * 0.35,
        s.height * 0.8,
      )
      ..lineTo(-s.width * 0.1, s.height * 0.9)
      ..close();
    canvas.drawPath(wave, Paint()..color = const Color(0xFF12395B));

    // Foam claws along the crest.
    final foam = Paint()..color = const Color(0xFFF4EFE2);
    for (var i = 0; i < 26; i++) {
      final t = i / 26.0;
      final cx = s.width * (0.08 + t * 0.55);
      final cy = s.height * (0.22 + math.sin(t * math.pi) * -0.02 + t * 0.16);
      canvas.drawCircle(
        Offset(cx, cy),
        (0.008 + rand.nextDouble() * 0.02) * s.width,
        foam,
      );
    }
    for (var i = 0; i < 130; i++) {
      canvas.drawCircle(
        Offset(
          rand.nextDouble() * s.width,
          s.height * (0.5 + rand.nextDouble() * 0.45),
        ),
        (0.003 + rand.nextDouble() * 0.008) * s.width,
        foam..color = foam.color.withValues(alpha: 0.9),
      );
    }

    // Two slender boats riding the swell.
    final boat = Paint()..color = const Color(0xFF5C4630);
    for (final f in const [0.55, 0.75]) {
      final y = s.height * (f + 0.08);
      final hull = Path()
        ..moveTo(s.width * (f - 0.18), y)
        ..quadraticBezierTo(
          s.width * f,
          y + s.height * 0.035,
          s.width * (f + 0.18),
          y - s.height * 0.01,
        )
        ..quadraticBezierTo(
          s.width * f,
          y + s.height * 0.015,
          s.width * (f - 0.18),
          y,
        )
        ..close();
      canvas.drawPath(hull, boat);
    }
  }

  // --- A pond of drifting lilies, all dabs and reflections. ---
  void _waterLilies(Canvas canvas, Size s) {
    final rand = math.Random(23);
    final water = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF3E7D6C), Color(0xFF2C5E75), Color(0xFF1F4560)],
      ).createShader(Offset.zero & s);
    canvas.drawRect(Offset.zero & s, water);

    // Vertical reflection streaks (willows and sky).
    final streak = Paint()..strokeCap = StrokeCap.round;
    const reflections = [
      Color(0xFF6FAF8E),
      Color(0xFF4E8C9E),
      Color(0xFFB9CBA0),
      Color(0xFF35688A),
    ];
    for (var i = 0; i < 420; i++) {
      final x = rand.nextDouble() * s.width;
      final y = rand.nextDouble() * s.height;
      streak
        ..color = reflections[rand.nextInt(reflections.length)]
            .withValues(alpha: 0.25 + rand.nextDouble() * 0.35)
        ..strokeWidth = (0.004 + rand.nextDouble() * 0.007) * s.width;
      canvas.drawLine(
        Offset(x, y),
        Offset(x, y + (0.03 + rand.nextDouble() * 0.08) * s.height),
        streak,
      );
    }

    // Lily pads in loose horizontal clusters.
    for (var cluster = 0; cluster < 7; cluster++) {
      final cy = s.height * (0.1 + cluster * 0.13 + rand.nextDouble() * 0.04);
      final cx = s.width * rand.nextDouble();
      for (var i = 0; i < 14; i++) {
        final pad = Offset(
          (cx + (rand.nextDouble() - 0.5) * s.width * 0.7) % s.width,
          cy + (rand.nextDouble() - 0.5) * s.height * 0.05,
        );
        final w = (0.05 + rand.nextDouble() * 0.06) * s.width;
        canvas.drawOval(
          Rect.fromCenter(center: pad, width: w, height: w * 0.36),
          Paint()
            ..color = Color.lerp(
              const Color(0xFF5E9E6F),
              const Color(0xFF2F6B4F),
              rand.nextDouble(),
            )!
                .withValues(alpha: 0.9),
        );
        // A blossom on some pads.
        if (rand.nextDouble() < 0.3) {
          final blossom = Color.lerp(
            const Color(0xFFF3C6D8),
            const Color(0xFFE86A9B),
            rand.nextDouble(),
          )!;
          canvas.drawOval(
            Rect.fromCenter(
              center: pad.translate(0, -w * 0.08),
              width: w * 0.35,
              height: w * 0.22,
            ),
            Paint()..color = blossom,
          );
          canvas.drawCircle(
            pad.translate(0, -w * 0.1),
            w * 0.05,
            Paint()..color = const Color(0xFFF7E27A),
          );
        }
      }
    }
  }

  // --- A blazing wavy sky over a dark fjord and a plunging walkway. ---
  void _scream(Canvas canvas, Size s) {
    final rand = math.Random(31);
    // Wavy sky bands.
    const skyColors = [
      Color(0xFFE8542E),
      Color(0xFFF07B32),
      Color(0xFFF2A93B),
      Color(0xFFE8542E),
      Color(0xFFC94A56),
    ];
    for (var band = 0; band < skyColors.length; band++) {
      final top = s.height * 0.42 * band / skyColors.length;
      final path = Path()..moveTo(0, top);
      for (var x = 0.0; x <= s.width; x += s.width / 6) {
        path.quadraticBezierTo(
          x + s.width / 12,
          top + math.sin(x / s.width * math.pi * 2 + band) * s.height * 0.02,
          x + s.width / 6,
          top,
        );
      }
      path
        ..lineTo(s.width, s.height * 0.55)
        ..lineTo(0, s.height * 0.55)
        ..close();
      canvas.drawPath(path, Paint()..color = skyColors[band]);
    }

    // Swirling dark fjord.
    final fjord = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF27405C), Color(0xFF12233B)],
      ).createShader(
        Rect.fromLTWH(0, s.height * 0.35, s.width, s.height * 0.65),
      );
    canvas.drawRect(
      Rect.fromLTWH(0, s.height * 0.35, s.width, s.height * 0.65),
      fjord,
    );
    final ripple = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 180; i++) {
      final y = s.height * (0.36 + rand.nextDouble() * 0.35);
      final x = rand.nextDouble() * s.width * 0.8;
      ripple
        ..color = Color.lerp(
          const Color(0xFF4A6E96),
          const Color(0xFF83A3C4),
          rand.nextDouble(),
        )!
            .withValues(alpha: 0.6)
        ..strokeWidth = (0.003 + rand.nextDouble() * 0.005) * s.width;
      final wave = Path()..moveTo(x, y);
      wave.quadraticBezierTo(
        x + s.width * 0.08,
        y - s.height * 0.008,
        x + s.width * 0.16,
        y,
      );
      canvas.drawPath(wave, ripple);
    }

    // The walkway plunging in from the right, with its railing.
    final deck = Path()
      ..moveTo(s.width, s.height * 0.55)
      ..lineTo(s.width * 0.25, s.height)
      ..lineTo(s.width, s.height)
      ..close();
    canvas.drawPath(deck, Paint()..color = const Color(0xFF6B4A33));
    final rail = Paint()
      ..color = const Color(0xFF3C2A1E)
      ..strokeWidth = s.width * 0.015
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(s.width, s.height * 0.5),
      Offset(s.width * 0.3, s.height * 0.92),
      rail,
    );
    canvas.drawLine(
      Offset(s.width, s.height * 0.62),
      Offset(s.width * 0.42, s.height),
      rail,
    );
  }

  // --- Primary-colour grid, ruler-straight. ---
  void _gridComposition(Canvas canvas, Size s) {
    canvas.drawRect(Offset.zero & s, Paint()..color = const Color(0xFFF6F1E7));
    final xs = [0.0, 0.18, 0.42, 0.68, 0.85, 1.0];
    final ys = [0.0, 0.14, 0.3, 0.52, 0.66, 0.84, 1.0];
    // A handful of filled cells.
    const fills = {
      (0, 1): Color(0xFFD8262C), // red
      (3, 0): Color(0xFF1D50A2), // blue
      (1, 4): Color(0xFFF2C233), // yellow
      (4, 5): Color(0xFFD8262C),
      (2, 2): Color(0xFFF6F1E7),
      (0, 5): Color(0xFF1D50A2),
      (3, 3): Color(0xFFF2C233),
    };
    for (final entry in fills.entries) {
      final (cx, cy) = entry.key;
      if (cx + 1 >= xs.length || cy + 1 >= ys.length) continue;
      canvas.drawRect(
        Rect.fromLTRB(
          xs[cx] * s.width,
          ys[cy] * s.height,
          xs[cx + 1] * s.width,
          ys[cy + 1] * s.height,
        ),
        Paint()..color = entry.value,
      );
    }
    // Black grid lines on top.
    final line = Paint()
      ..color = const Color(0xFF17150F)
      ..strokeWidth = s.width * 0.022;
    for (final x in xs.sublist(1, xs.length - 1)) {
      canvas.drawLine(
        Offset(x * s.width, 0),
        Offset(x * s.width, s.height),
        line,
      );
    }
    for (final y in ys.sublist(1, ys.length - 1)) {
      canvas.drawLine(
        Offset(0, y * s.height),
        Offset(s.width, y * s.height),
        line,
      );
    }
  }

  // --- A shimmering golden field strewn with ornaments and blossoms. ---
  void _goldenGarden(Canvas canvas, Size s) {
    final rand = math.Random(43);
    final gold = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFC9962B), Color(0xFFE0B84C), Color(0xFFA87A1F)],
      ).createShader(Offset.zero & s);
    canvas.drawRect(Offset.zero & s, gold);

    // Golden texture: tiny rectangles like leaf gilding.
    for (var i = 0; i < 700; i++) {
      canvas.drawRect(
        Rect.fromLTWH(
          rand.nextDouble() * s.width,
          rand.nextDouble() * s.height,
          (0.006 + rand.nextDouble() * 0.02) * s.width,
          (0.004 + rand.nextDouble() * 0.012) * s.width,
        ),
        Paint()
          ..color = Color.lerp(
            const Color(0xFFF2D06B),
            const Color(0xFF8C6414),
            rand.nextDouble(),
          )!
              .withValues(alpha: 0.5),
      );
    }

    // Ornamental spirals.
    final spiral = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 26; i++) {
      final centre = Offset(
        rand.nextDouble() * s.width,
        rand.nextDouble() * s.height,
      );
      spiral
        ..color = const Color(0xFF6B4A12)
            .withValues(alpha: 0.5 + rand.nextDouble() * 0.4)
        ..strokeWidth = (0.004 + rand.nextDouble() * 0.004) * s.width;
      final path = Path()..moveTo(centre.dx, centre.dy);
      var radius = 0.0;
      for (var a = 0.0; a < math.pi * 4; a += 0.4) {
        radius += (0.0016 + rand.nextDouble() * 0.001) * s.width;
        path.lineTo(
          centre.dx + math.cos(a) * radius,
          centre.dy + math.sin(a) * radius,
        );
      }
      canvas.drawPath(path, spiral);
    }

    // Bright blossom dots drifting down the canvas.
    const petals = [
      Color(0xFFD8455B),
      Color(0xFF4E79B8),
      Color(0xFF67A66A),
      Color(0xFFF0EAD8),
    ];
    for (var i = 0; i < 90; i++) {
      canvas.drawCircle(
        Offset(rand.nextDouble() * s.width, rand.nextDouble() * s.height),
        (0.008 + rand.nextDouble() * 0.02) * s.width,
        Paint()..color = petals[rand.nextInt(petals.length)],
      );
    }
  }

  @override
  bool shouldRepaint(covariant MasterpiecePainter oldDelegate) =>
      oldDelegate.style != style;
}
