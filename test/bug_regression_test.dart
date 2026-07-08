import 'package:flutter_test/flutter_test.dart';
import 'package:inkognito/core/constants/app_constants.dart';
import 'package:inkognito/features/auth/domain/entities/app_user.dart';
import 'package:inkognito/features/editor/domain/entities/placed_inkling.dart';
import 'package:inkognito/features/editor/domain/entities/inkling_species.dart';
import 'package:inkognito/features/play/domain/detection_engine.dart';
import 'package:inkognito/features/play/domain/entities/attempt.dart';
import 'package:inkognito/features/progression/data/progression_service.dart';
import 'package:inkognito/features/progression/domain/entities/badge.dart';

PlacedInkling _inkling({
  String id = 'i1',
  Offset center = const Offset(0.5, 0.5),
  double size = 0.2,
}) {
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
  group('Daily streak', () {
    final today = DateTime(2026, 7, 8);

    test('first ever activity starts a streak of 1', () {
      expect(ProgressionService.computeStreak(null, 0, now: today), 1);
    });

    test('corrupt stored date resets safely to 1', () {
      expect(
        ProgressionService.computeStreak('not-a-date', 5, now: today),
        1,
      );
    });

    test('same-day activity keeps the streak', () {
      expect(
        ProgressionService.computeStreak('2026-07-08', 4, now: today),
        4,
      );
    });

    test('same-day activity with a zero streak still counts as day 1', () {
      expect(
        ProgressionService.computeStreak('2026-07-08', 0, now: today),
        1,
      );
    });

    test('consecutive day extends the streak', () {
      expect(
        ProgressionService.computeStreak('2026-07-07', 4, now: today),
        5,
      );
    });

    test('a missed day breaks the streak', () {
      expect(
        ProgressionService.computeStreak('2026-07-06', 9, now: today),
        1,
      );
    });
  });

  group('Badge permanence', () {
    // A player who earned the 7-day streak badge, then broke their streak.
    const afterBreak = BadgeContext(
      challengesCreated: 5,
      challengesSolved: 0,
      streakDays: 1,
      level: 3,
      perfectSolves: 0,
      totalLikes: 0,
    );

    test('earned badges survive a stat regression', () {
      final badges = ProgressionService.mergedBadges(['on_fire'], afterBreak);
      expect(badges, contains('on_fire'));
    });

    test('newly earned badges are added exactly once', () {
      final badges =
          ProgressionService.mergedBadges(['first_hide'], afterBreak);
      expect(badges.where((b) => b == 'first_hide').length, 1);
    });

    test('likes now count toward Crowd Favourite', () {
      const ctx = BadgeContext(
        challengesCreated: 0,
        challengesSolved: 0,
        streakDays: 0,
        level: 1,
        perfectSolves: 0,
        totalLikes: 100,
      );
      expect(BadgeCatalog.earned(ctx), contains('crowd_favourite'));
    });
  });

  group('Levelling edges', () {
    test('progress is exactly 0 right after levelling up', () {
      final threshold = AppConstants.xpForLevel(1);
      final level = ProgressionService.levelForXp(threshold);
      expect(level, 2);
      expect(ProgressionService.levelProgress(threshold, level), 0.0);
    });

    test('progress approaches 1 just below the next threshold', () {
      final nextThreshold = AppConstants.xpForLevel(2);
      final p = ProgressionService.levelProgress(nextThreshold - 1, 2);
      expect(p, greaterThan(0.9));
      expect(p, lessThan(1.0));
    });
  });

  group('Detection boundaries', () {
    test('a tap exactly on the tolerance edge still hits', () {
      final inkling = _inkling();
      final radius = inkling.size / 2 + AppConstants.detectionToleranceFactor;
      final result = DetectionEngine.hitTest(
        tap: Offset(0.5 + radius, 0.5),
        inklings: [inkling],
        alreadyFound: {},
      );
      expect(result.hit, isTrue);
    });

    test('a tap just beyond the tolerance edge misses', () {
      final inkling = _inkling();
      final radius = inkling.size / 2 + AppConstants.detectionToleranceFactor;
      final result = DetectionEngine.hitTest(
        tap: Offset(0.5 + radius + 0.001, 0.5),
        inklings: [inkling],
        alreadyFound: {},
      );
      expect(result.hit, isFalse);
    });
  });

  group('PlaySession scoring edges', () {
    test('an empty challenge scores 0 and cannot award a perfect bonus', () {
      final session = PlaySession(inklings: const []);
      expect(session.computeScore(), 0);
    });

    test('giving up without finding anything scores 0', () {
      final session = PlaySession(inklings: [_inkling()]);
      session.tap(const Offset(0.05, 0.05)); // one miss
      expect(session.foundCount, 0);
      expect(session.computeScore(), 0);
    });

    test('a fresh session starts from a clean slate (replay)', () {
      final first = PlaySession(inklings: [_inkling()]);
      first.tap(const Offset(0.5, 0.5));
      expect(first.isComplete, isTrue);

      final replay = PlaySession(inklings: [_inkling()]);
      expect(replay.foundCount, 0);
      expect(replay.taps, isEmpty);
      expect(replay.elapsed, Duration.zero);
    });
  });

  group('AppUser tokens', () {
    test('new players start with the publishing grant', () {
      const user = AppUser(uid: 'u1', displayName: 'Ada');
      expect(user.tokens, AppConstants.startingTokens);
    });

    test('legacy profiles without the field receive the starting grant', () {
      final user = AppUser.fromJson('u1', {'displayName': 'Ada'});
      expect(user.tokens, AppConstants.startingTokens);
    });

    test('tokens round-trip through JSON', () {
      const user = AppUser(uid: 'u1', displayName: 'Ada', tokens: 42);
      final restored = AppUser.fromJson('u1', user.toJson());
      expect(restored.tokens, 42);
    });

    test('copyWith updates the balance without touching other fields', () {
      const user = AppUser(uid: 'u1', displayName: 'Ada', xp: 10);
      final updated = user.copyWith(tokens: 3);
      expect(updated.tokens, 3);
      expect(updated.xp, 10);
      expect(updated.displayName, 'Ada');
    });
  });

  group('Attempt serialisation', () {
    test('taps round-trip through the flattened JSON encoding', () {
      final attempt = Attempt(
        id: 'a1',
        challengeId: 'c1',
        playerId: 'u1',
        foundCount: 2,
        totalInklings: 3,
        durationMs: 8000,
        score: 900,
        taps: const [Offset(0.1, 0.2), Offset(0.3, 0.4)],
        createdAt: DateTime.utc(2026, 7, 8),
      );
      final restored = Attempt.fromJson('a1', attempt.toJson());
      expect(restored.taps, attempt.taps);
      expect(restored.isPerfect, isFalse);
      expect(restored.accuracy, closeTo(2 / 2, 1e-9));
    });

    test('a malformed odd-length tap list does not crash', () {
      final restored = Attempt.fromJson('a1', {
        'challengeId': 'c1',
        'playerId': 'u1',
        'taps': [0.1, 0.2, 0.3],
      });
      expect(restored.taps.length, 1);
    });
  });
}
