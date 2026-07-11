import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'entities/inkling_species.dart';

/// Geometry factory for Inkling silhouettes.
///
/// Every shape is defined inside a unit square (0..1) and scaled to the target
/// rect at paint time, so the same definition drives on-screen rendering, the
/// clip mask for camouflage strokes and the exported image. All designs are
/// original: rounded, friendly bodies with large eyes.
abstract class InklingShapes {
  /// Returns the outline [Path] for [species] sized to [rect].
  static Path body(InklingSpecies species, Rect rect) {
    final unit = _unitBody(species);
    final matrix = Matrix4.identity()
      ..translateByDouble(rect.left, rect.top, 0, 1)
      ..scaleByDouble(rect.width, rect.height, 1, 1);
    return unit.transform(matrix.storage);
  }

  /// Eye centres + radius (all normalised 0..1) for [species].
  static List<InklingEye> eyes(InklingSpecies species) {
    return switch (species) {
      InklingSpecies.classic => const [
          InklingEye(Offset(0.36, 0.42), 0.10),
          InklingEye(Offset(0.64, 0.42), 0.10),
        ],
      InklingSpecies.ghost => const [
          InklingEye(Offset(0.37, 0.40), 0.09),
          InklingEye(Offset(0.63, 0.40), 0.09),
        ],
      InklingSpecies.robot => const [
          InklingEye(Offset(0.35, 0.45), 0.11),
          InklingEye(Offset(0.65, 0.45), 0.11),
        ],
      InklingSpecies.dragon => const [
          InklingEye(Offset(0.38, 0.38), 0.08),
          InklingEye(Offset(0.62, 0.38), 0.08),
        ],
      InklingSpecies.alien => const [InklingEye(Offset(0.50, 0.44), 0.16)],
      InklingSpecies.animal => const [
          InklingEye(Offset(0.38, 0.46), 0.10),
          InklingEye(Offset(0.62, 0.46), 0.10),
        ],
      InklingSpecies.monster => const [
          InklingEye(Offset(0.34, 0.40), 0.12),
          InklingEye(Offset(0.60, 0.36), 0.09),
        ],
    };
  }

  static Path _unitBody(InklingSpecies species) {
    return switch (species) {
      InklingSpecies.classic => _blob(),
      InklingSpecies.ghost => _ghost(),
      InklingSpecies.robot => _robot(),
      InklingSpecies.dragon => _dragon(),
      InklingSpecies.alien => _alien(),
      InklingSpecies.animal => _animal(),
      InklingSpecies.monster => _monster(),
    };
  }

  // --- Unit shape definitions (all within 0..1) ---

  static Path _blob() {
    return Path()..addOval(const Rect.fromLTWH(0.08, 0.06, 0.84, 0.88));
  }

  static Path _ghost() {
    final p = Path()
      ..moveTo(0.12, 0.95)
      ..lineTo(0.12, 0.42)
      ..cubicTo(0.12, 0.10, 0.88, 0.10, 0.88, 0.42)
      ..lineTo(0.88, 0.95);
    // Wavy skirt.
    const waves = 4;
    for (var i = 0; i < waves; i++) {
      final x0 = 0.88 - (i * 0.76 / waves);
      final x1 = x0 - (0.76 / waves) / 2;
      final x2 = x0 - (0.76 / waves);
      p.quadraticBezierTo(x1, 0.80, x2, 0.95);
    }
    p.close();
    return p;
  }

  static Path _robot() {
    return Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(0.14, 0.16, 0.72, 0.74),
          const Radius.circular(0.18),
        ),
      )
      // Antenna.
      ..addOval(const Rect.fromLTWH(0.45, 0.02, 0.10, 0.10));
  }

  static Path _dragon() {
    final p = Path()..addOval(const Rect.fromLTWH(0.14, 0.16, 0.72, 0.78));
    // Ears / horns.
    p.addPolygon(
      const [Offset(0.22, 0.20), Offset(0.10, 0.02), Offset(0.36, 0.14)],
      true,
    );
    p.addPolygon(
      const [Offset(0.78, 0.20), Offset(0.90, 0.02), Offset(0.64, 0.14)],
      true,
    );
    return p;
  }

  static Path _alien() {
    // Tall rounded head.
    return Path()..addOval(const Rect.fromLTWH(0.18, 0.04, 0.64, 0.92));
  }

  static Path _animal() {
    final p = Path()..addOval(const Rect.fromLTWH(0.12, 0.20, 0.76, 0.74));
    // Round ears.
    p.addOval(const Rect.fromLTWH(0.14, 0.06, 0.24, 0.24));
    p.addOval(const Rect.fromLTWH(0.62, 0.06, 0.24, 0.24));
    return p;
  }

  static Path _monster() {
    // Lumpy asymmetric blob.
    final p = Path()..moveTo(0.10, 0.55);
    p.cubicTo(0.05, 0.20, 0.35, 0.05, 0.52, 0.10);
    p.cubicTo(0.70, 0.04, 0.98, 0.22, 0.90, 0.55);
    p.cubicTo(0.96, 0.85, 0.66, 0.98, 0.50, 0.92);
    p.cubicTo(0.30, 0.99, 0.04, 0.86, 0.10, 0.55);
    p.close();
    // Small spikes on top.
    for (var i = 0; i < 3; i++) {
      final x = 0.32 + i * 0.18;
      p.addPolygon(
        [Offset(x, 0.10), Offset(x + 0.05, -0.02), Offset(x + 0.10, 0.10)],
        true,
      );
    }
    return p;
  }
}

/// An eye descriptor: centre and radius in the Inkling's unit space.
class InklingEye {
  const InklingEye(this.center, this.radius);
  final Offset center;
  final double radius;
}

extension InklingEyeAccess on InklingSpecies {
  /// Convenience helper for a subtle idle "wobble" phase used in animations.
  double get wobbleSeed => (index + 1) * math.pi / 3;
}
