import 'package:flutter/material.dart';

import 'draw_stroke.dart';
import 'inkling_species.dart';

/// An Inkling instance placed on the challenge canvas.
///
/// Position and size are stored in **normalised** canvas coordinates (0..1)
/// so the same challenge renders identically across screen sizes and at the
/// high resolution used when exporting the final image.
@immutable
class PlacedInkling {
  const PlacedInkling({
    required this.id,
    required this.species,
    required this.variantId,
    required this.center,
    required this.size,
    required this.rotation,
    this.strokes = const [],
  });

  final String id;
  final InklingSpecies species;
  final String variantId;

  /// Centre of the Inkling in normalised canvas space (0..1, 0..1).
  final Offset center;

  /// Diameter of the Inkling as a fraction of the canvas's shortest side.
  final double size;

  /// Rotation in radians.
  final double rotation;

  /// Camouflage strokes drawn inside this Inkling, in its local space.
  final List<DrawStroke> strokes;

  PlacedInkling copyWith({
    Offset? center,
    double? size,
    double? rotation,
    List<DrawStroke>? strokes,
  }) {
    return PlacedInkling(
      id: id,
      species: species,
      variantId: variantId,
      center: center ?? this.center,
      size: size ?? this.size,
      rotation: rotation ?? this.rotation,
      strokes: strokes ?? this.strokes,
    );
  }

  /// Resolves the Inkling's on-screen rectangle for a given canvas [size].
  Rect rectFor(Size canvas) {
    final shortest = canvas.shortestSide;
    final diameter = size * shortest;
    final cx = center.dx * canvas.width;
    final cy = center.dy * canvas.height;
    return Rect.fromCenter(
      center: Offset(cx, cy),
      width: diameter,
      height: diameter,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'species': species.name,
        'variantId': variantId,
        'cx': center.dx,
        'cy': center.dy,
        'size': size,
        'rotation': rotation,
        'strokes': strokes.map((s) => s.toJson()).toList(),
      };

  factory PlacedInkling.fromJson(Map<String, dynamic> json) {
    return PlacedInkling(
      id: json['id'] as String,
      species: InklingSpecies.fromName(json['species'] as String?),
      variantId: json['variantId'] as String? ?? 'default',
      center: Offset(
        (json['cx'] as num).toDouble(),
        (json['cy'] as num).toDouble(),
      ),
      size: (json['size'] as num).toDouble(),
      rotation: (json['rotation'] as num).toDouble(),
      strokes: (json['strokes'] as List? ?? [])
          .map((e) => DrawStroke.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
