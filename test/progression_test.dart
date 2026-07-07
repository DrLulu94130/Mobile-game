import 'package:flutter_test/flutter_test.dart';
import 'package:inkognito/core/constants/app_constants.dart';
import 'package:inkognito/features/progression/data/progression_service.dart';
import 'package:inkognito/features/progression/domain/entities/badge.dart';

void main() {
  group('Levelling', () {
    test('level 1 at zero XP', () {
      expect(ProgressionService.levelForXp(0), 1);
    });

    test('level increases monotonically with XP', () {
      var previous = 1;
      for (var xp = 0; xp < 50000; xp += 500) {
        final level = ProgressionService.levelForXp(xp);
        expect(level, greaterThanOrEqualTo(previous));
        previous = level;
      }
    });

    test('crossing a threshold levels the player up', () {
      final threshold = AppConstants.xpForLevel(1);
      expect(ProgressionService.levelForXp(threshold - 1), 1);
      expect(ProgressionService.levelForXp(threshold), 2);
    });

    test('progress is within 0..1', () {
      final p = ProgressionService.levelProgress(120, 2);
      expect(p, inInclusiveRange(0.0, 1.0));
    });
  });

  group('Badges', () {
    test('first challenge earns the First Hide badge', () {
      const ctx = BadgeContext(
        challengesCreated: 1,
        challengesSolved: 0,
        streakDays: 0,
        level: 1,
        perfectSolves: 0,
        totalLikes: 0,
      );
      expect(BadgeCatalog.earned(ctx), contains('first_hide'));
    });

    test('no badges for a brand-new account', () {
      const ctx = BadgeContext(
        challengesCreated: 0,
        challengesSolved: 0,
        streakDays: 0,
        level: 1,
        perfectSolves: 0,
        totalLikes: 0,
      );
      expect(BadgeCatalog.earned(ctx), isEmpty);
    });
  });
}
