import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inkognito/features/challenge/domain/entities/challenge.dart';
import 'package:inkognito/features/editor/domain/entities/draw_stroke.dart';
import 'package:inkognito/features/editor/domain/entities/inkling_species.dart';
import 'package:inkognito/features/editor/domain/entities/placed_inkling.dart';

void main() {
  test('DrawStroke round-trips through JSON', () {
    const stroke = DrawStroke(
      points: [Offset(0.1, 0.2), Offset(0.3, 0.4)],
      color: Color(0xFF123456),
      width: 0.08,
      isEraser: true,
    );
    final restored = DrawStroke.fromJson(stroke.toJson());
    expect(restored.points, stroke.points);
    expect(restored.color.value, stroke.color.value);
    expect(restored.width, closeTo(stroke.width, 1e-9));
    expect(restored.isEraser, isTrue);
  });

  test('PlacedInkling round-trips through JSON', () {
    const inkling = PlacedInkling(
      id: 'x1',
      species: InklingSpecies.dragon,
      variantId: 'default',
      center: Offset(0.4, 0.6),
      size: 0.3,
      rotation: 1.2,
      strokes: [
        DrawStroke(points: [Offset(0, 0)], color: Colors.red, width: 0.05),
      ],
    );
    final restored = PlacedInkling.fromJson(inkling.toJson());
    expect(restored.id, 'x1');
    expect(restored.species, InklingSpecies.dragon);
    expect(restored.center, inkling.center);
    expect(restored.rotation, closeTo(1.2, 1e-9));
    expect(restored.strokes.length, 1);
  });

  test('PlacedInkling.rectFor centres on the canvas', () {
    const inkling = PlacedInkling(
      id: 'x',
      species: InklingSpecies.classic,
      variantId: 'default',
      center: Offset(0.5, 0.5),
      size: 0.5,
      rotation: 0,
    );
    final rect = inkling.rectFor(const Size(200, 400));
    expect(rect.center, const Offset(100, 200));
    // Diameter uses the shortest side (200) * size (0.5) = 100.
    expect(rect.width, 100);
  });

  test('Challenge round-trips through JSON', () {
    final challenge = Challenge(
      id: 'c1',
      authorId: 'u1',
      authorName: 'Ada',
      title: 'Spot six',
      camouflagedImageUrl: 'https://x/c.jpg',
      revealedImageUrl: 'https://x/r.jpg',
      inklings: const [],
      canvasAspectRatio: 0.75,
      createdAt: DateTime.utc(2026, 1, 1),
      likeCount: 3,
    );
    final restored = Challenge.fromJson('c1', challenge.toJson());
    expect(restored.title, 'Spot six');
    expect(restored.likeCount, 3);
    expect(restored.canvasAspectRatio, 0.75);
  });
}
