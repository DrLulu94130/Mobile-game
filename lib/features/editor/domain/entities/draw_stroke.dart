import 'package:flutter/material.dart';

/// A single freehand stroke drawn *inside* an Inkling's silhouette.
///
/// Points are stored in the Inkling's **local, normalised** coordinate space
/// (0..1 on both axes) so a stroke survives moving, scaling and rotating the
/// creature, and can be re-rendered at any output resolution.
@immutable
class DrawStroke {
  const DrawStroke({
    required this.points,
    required this.color,
    required this.width,
    this.isEraser = false,
  });

  /// Normalised points within the Inkling's local bounding box.
  final List<Offset> points;

  final Color color;

  /// Stroke width as a fraction of the Inkling's local size (0..1), keeping
  /// brushes visually consistent regardless of on-screen scale.
  final double width;

  final bool isEraser;

  DrawStroke copyWith({
    List<Offset>? points,
    Color? color,
    double? width,
    bool? isEraser,
  }) {
    return DrawStroke(
      points: points ?? this.points,
      color: color ?? this.color,
      width: width ?? this.width,
      isEraser: isEraser ?? this.isEraser,
    );
  }

  Map<String, dynamic> toJson() => {
        'p': points.expand((o) => [o.dx, o.dy]).toList(),
        'c': color.toARGB32(),
        'w': width,
        'e': isEraser,
      };

  factory DrawStroke.fromJson(Map<String, dynamic> json) {
    final flat = (json['p'] as List).cast<num>();
    final points = <Offset>[
      for (var i = 0; i + 1 < flat.length; i += 2)
        Offset(flat[i].toDouble(), flat[i + 1].toDouble()),
    ];
    return DrawStroke(
      points: points,
      color: Color((json['c'] as num).toInt()),
      width: (json['w'] as num).toDouble(),
      isEraser: json['e'] as bool? ?? false,
    );
  }
}
