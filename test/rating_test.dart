import 'package:flutter_test/flutter_test.dart';
import 'package:inkognito/core/constants/app_constants.dart';
import 'package:inkognito/features/challenge/domain/entities/challenge.dart';

Challenge _challenge({int wins = 0, int fails = 0}) {
  return Challenge(
    id: 'c1',
    authorId: 'u1',
    authorName: 'Ada',
    title: 'Spot six',
    camouflagedImageUrl: 'https://x/c.jpg',
    revealedImageUrl: 'https://x/r.jpg',
    inklings: const [],
    canvasAspectRatio: 0.75,
    createdAt: DateTime.utc(2026, 1, 1),
    seekWinCount: wins,
    seekFailCount: fails,
    ratingScore: Challenge.computeRatingScore(wins, fails),
  );
}

void main() {
  group('Challenge.computeRatingScore', () {
    test('is 0 with no attempts', () {
      expect(Challenge.computeRatingScore(0, 0), 0);
    });

    test('is the share of seekers fooled', () {
      expect(Challenge.computeRatingScore(0, 4), 100);
      expect(Challenge.computeRatingScore(4, 0), 0);
      expect(Challenge.computeRatingScore(2, 2), 50);
      expect(Challenge.computeRatingScore(1, 3), 75);
    });

    test('rounds to the nearest integer', () {
      expect(Challenge.computeRatingScore(2, 1), 33);
      expect(Challenge.computeRatingScore(1, 2), 67);
    });
  });

  group('Challenge rating helpers', () {
    test('note is hidden until enough seek attempts', () {
      final unrated = _challenge(wins: 1, fails: 1);
      expect(unrated.hasRating, isFalse);

      final rated = _challenge(
        wins: 0,
        fails: AppConstants.minSeekAttemptsForRating,
      );
      expect(rated.hasRating, isTrue);
    });

    test('ratingStars maps 0..100 onto 0..5', () {
      expect(_challenge(wins: 0, fails: 4).ratingStars, 5.0);
      expect(_challenge(wins: 2, fails: 2).ratingStars, 2.5);
      expect(_challenge(wins: 4, fails: 0).ratingStars, 0.0);
    });

    test('seek counters round-trip through JSON', () {
      final challenge = _challenge(wins: 3, fails: 9);
      final restored = Challenge.fromJson('c1', challenge.toJson());
      expect(restored.seekWinCount, 3);
      expect(restored.seekFailCount, 9);
      expect(restored.ratingScore, 75);
      expect(restored.seekAttempts, 12);
    });

    test('legacy documents default to an unrated drawing', () {
      final json = _challenge().toJson()
        ..remove('seekWinCount')
        ..remove('seekFailCount')
        ..remove('ratingScore');
      final restored = Challenge.fromJson('c1', json);
      expect(restored.seekWinCount, 0);
      expect(restored.seekFailCount, 0);
      expect(restored.ratingScore, 0);
      expect(restored.hasRating, isFalse);
    });
  });
}
