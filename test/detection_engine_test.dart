import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inkognito/core/constants/app_constants.dart';
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

  group('PlaySession XP', () {
    final inklings = [
      _inkling('a', const Offset(0.2, 0.2)),
      _inkling('b', const Offset(0.8, 0.8)),
    ];

    test('giving up without finding anything earns no XP', () {
      final session = PlaySession(inklings: inklings);
      expect(session.computeXp(firstAttempt: true), 0);
    });

    test('partial finds pay per Inkling but no solve bonus', () {
      final session = PlaySession(inklings: inklings)
        ..tap(const Offset(0.2, 0.2));
      final xp = session.computeXp(firstAttempt: true);
      expect(xp, AppConstants.xpPerInklingFound);
    });

    test('a complete solve earns the solve bonus on top of finds', () {
      final session = PlaySession(inklings: inklings)
        ..tap(const Offset(0.2, 0.2))
        ..tap(const Offset(0.8, 0.8));
      expect(
        session.computeXp(firstAttempt: true),
        2 * AppConstants.xpPerInklingFound + AppConstants.xpPerChallengeSolved,
      );
    });

    test('repeat attempts earn nothing, even when complete', () {
      final session = PlaySession(inklings: inklings)
        ..tap(const Offset(0.2, 0.2))
        ..tap(const Offset(0.8, 0.8));
      expect(session.isComplete, isTrue);
      expect(session.computeXp(firstAttempt: false), 0);
    });
  });

  group('PlaySession flawless runs', () {
    final inklings = [
      _inkling('a', const Offset(0.2, 0.2)),
      _inkling('b', const Offset(0.8, 0.8)),
    ];

    test('complete without a single miss is flawless', () {
      final session = PlaySession(inklings: inklings)
        ..tap(const Offset(0.2, 0.2))
        ..tap(const Offset(0.8, 0.8));
      expect(session.isFlawless, isTrue);
    });

    test('a wasted tap forfeits the flawless run', () {
      final session = PlaySession(inklings: inklings)
        ..tap(const Offset(0.5, 0.5)) // miss
        ..tap(const Offset(0.2, 0.2))
        ..tap(const Offset(0.8, 0.8));
      expect(session.isComplete, isTrue);
      expect(session.isFlawless, isFalse);
    });

    test('an incomplete run is never flawless', () {
      final session = PlaySession(inklings: inklings)
        ..tap(const Offset(0.2, 0.2));
      expect(session.isFlawless, isFalse);
    });
  });

  group('PlaySession reset', () {
    test('clears finds, taps and the clock for a fresh replay', () {
      final inklings = [_inkling('a', const Offset(0.5, 0.5))];
      final session = PlaySession(inklings: inklings)
        ..tap(const Offset(0.1, 0.1)) // miss
        ..tap(const Offset(0.5, 0.5));
      expect(session.isComplete, isTrue);

      session.reset();

      expect(session.foundCount, 0);
      expect(session.taps, isEmpty);
      expect(session.isComplete, isFalse);
      expect(session.elapsed, Duration.zero);
    });
  });
}
