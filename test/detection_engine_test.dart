import 'package:flutter_test/flutter_test.dart';
import 'package:inkognito/features/editor/domain/entities/inkling_species.dart';
import 'package:inkognito/features/editor/domain/entities/placed_inkling.dart';
import 'package:inkognito/features/play/domain/detection_engine.dart';

PlacedInkling _inkling(String id, Offset center, {double size = 0.2}) {
  return PlacedInkling(
    id: id,
    species: InklingSpecies.classic,
    variantId: 'default',
    center: center,
    size: size,
    rotation: 0,
  );
}

void main() {
  group('DetectionEngine.hitTest', () {
    final inklings = [
      _inkling('a', const Offset(0.25, 0.25)),
      _inkling('b', const Offset(0.75, 0.75)),
    ];

    test('registers a hit near an Inkling centre', () {
      final result = DetectionEngine.hitTest(
        tap: const Offset(0.26, 0.24),
        inklings: inklings,
        alreadyFound: {},
      );
      expect(result.hit, isTrue);
      expect(result.inklingId, 'a');
    });

    test('misses when tapping far away', () {
      final result = DetectionEngine.hitTest(
        tap: const Offset(0.5, 0.5),
        inklings: inklings,
        alreadyFound: {},
      );
      expect(result.hit, isFalse);
    });

    test('ignores already-found Inklings', () {
      final result = DetectionEngine.hitTest(
        tap: const Offset(0.25, 0.25),
        inklings: inklings,
        alreadyFound: {'a'},
      );
      expect(result.hit, isFalse);
    });

    test('picks the closest of two overlapping candidates', () {
      final overlapping = [
        _inkling('near', const Offset(0.5, 0.5), size: 0.4),
        _inkling('far', const Offset(0.55, 0.55), size: 0.4),
      ];
      final result = DetectionEngine.hitTest(
        tap: const Offset(0.5, 0.5),
        inklings: overlapping,
        alreadyFound: {},
      );
      expect(result.inklingId, 'near');
    });
  });

  group('PlaySession scoring', () {
    test('perfect solve scores higher than a partial one', () {
      final inklings = [
        _inkling('a', const Offset(0.2, 0.2)),
        _inkling('b', const Offset(0.8, 0.8)),
      ];

      final perfect = PlaySession(inklings: inklings)
        ..tap(const Offset(0.2, 0.2))
        ..tap(const Offset(0.8, 0.8));

      final partial = PlaySession(inklings: inklings)
        ..tap(const Offset(0.2, 0.2))
        ..tap(const Offset(0.5, 0.5)); // miss

      expect(perfect.isComplete, isTrue);
      expect(perfect.computeScore(), greaterThan(partial.computeScore()));
    });

    test('found set never exceeds total', () {
      final inklings = [_inkling('a', const Offset(0.5, 0.5))];
      final session = PlaySession(inklings: inklings)
        ..tap(const Offset(0.5, 0.5))
        ..tap(const Offset(0.5, 0.5));
      expect(session.foundCount, 1);
    });
  });
}
