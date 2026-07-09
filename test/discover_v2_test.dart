import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inkognito/core/constants/app_constants.dart';
import 'package:inkognito/features/challenge/domain/entities/challenge.dart';
import 'package:inkognito/features/discover/domain/discover_feed.dart';
import 'package:inkognito/features/editor/domain/entities/inkling_species.dart';
import 'package:inkognito/features/editor/domain/entities/placed_inkling.dart';

PlacedInkling _ink(String id) => PlacedInkling(
      id: id,
      species: InklingSpecies.classic,
      variantId: 'default',
      center: const Offset(0.5, 0.5),
      size: 0.2,
      rotation: 0,
    );

Challenge _challenge(
  String id, {
  String authorId = 'author',
  int playCount = 0,
  int inklings = 1,
  int reportCount = 0,
}) {
  return Challenge(
    id: id,
    authorId: authorId,
    authorName: 'A',
    title: id,
    camouflagedImageUrl: 'u',
    revealedImageUrl: 'u',
    inklings: [for (var i = 0; i < inklings; i++) _ink('$id-$i')],
    canvasAspectRatio: 0.5625,
    createdAt: DateTime.utc(2026, 1, 1),
    playCount: playCount,
    reportCount: reportCount,
  );
}

void main() {
  group('DiscoverFeed.order', () {
    test('drops the viewer own drawings and empty ones', () {
      final pool = [
        _challenge('mine', authorId: 'me'),
        _challenge('empty', authorId: 'other', inklings: 0),
        _challenge('ok', authorId: 'other'),
      ];
      final ordered = DiscoverFeed.order(pool, viewerId: 'me');
      expect(ordered.map((c) => c.id), ['ok']);
    });

    test('daily drawing always leads the feed', () {
      final pool = [
        for (var i = 0; i < 5; i++) _challenge('c$i', authorId: 'other'),
        _challenge('daily', authorId: 'other'),
      ];
      final ordered = DiscoverFeed.order(
        pool,
        viewerId: 'me',
        dailyId: 'daily',
        seed: 3,
      );
      expect(ordered.first.id, 'daily');
      expect(ordered.length, 6);
    });

    test('is deterministic for a given seed', () {
      final pool = [
        for (var i = 0; i < 10; i++)
          _challenge('c$i', authorId: 'other', playCount: i * 3),
      ];
      final a = DiscoverFeed.order(pool, viewerId: 'me', seed: 42);
      final b = DiscoverFeed.order(pool, viewerId: 'me', seed: 42);
      expect(a.map((c) => c.id), b.map((c) => c.id));
    });

    test('keeps every playable drawing exactly once', () {
      final pool = [
        for (var i = 0; i < 20; i++) _challenge('c$i', authorId: 'other'),
      ];
      final ordered = DiscoverFeed.order(pool, viewerId: 'me', seed: 7);
      expect(ordered.map((c) => c.id).toSet().length, 20);
    });
  });

  group('Discover clock scaling', () {
    test('baseline drawings get the base duration', () {
      expect(
        AppConstants.discoverSecondsFor(1),
        AppConstants.discoverRoundSeconds,
      );
      expect(
        AppConstants.discoverSecondsFor(AppConstants.discoverBaselineInklings),
        AppConstants.discoverRoundSeconds,
      );
    });

    test('extra creatures grant extra time', () {
      final base = AppConstants.discoverSecondsFor(3);
      final bigger = AppConstants.discoverSecondsFor(5);
      expect(
        bigger,
        base + 2 * AppConstants.discoverExtraSecondsPerInkling,
      );
    });

    test('premium always gets a bonus on top', () {
      expect(
        AppConstants.discoverSecondsFor(3, premium: true),
        AppConstants.discoverRoundSeconds +
            AppConstants.premiumDiscoverBonusSeconds,
      );
    });
  });

  group('Discover win combo', () {
    test('first win pays the base bonus', () {
      expect(
        AppConstants.discoverWinBonus(1),
        AppConstants.tokensPerDiscoverWin,
      );
    });

    test('the bonus grows with the streak but is capped', () {
      expect(
        AppConstants.discoverWinBonus(3),
        AppConstants.tokensPerDiscoverWin + 2,
      );
      // Capped at +3 above the base regardless of how long the streak runs.
      expect(
        AppConstants.discoverWinBonus(50),
        AppConstants.tokensPerDiscoverWin + 3,
      );
    });
  });

  group('Report moderation threshold', () {
    test('drawings under the threshold stay visible', () {
      final c =
          _challenge('c', reportCount: AppConstants.reportHideThreshold - 1);
      expect(c.reportCount < AppConstants.reportHideThreshold, isTrue);
    });

    test('reaching the threshold hides the drawing', () {
      final c = _challenge('c', reportCount: AppConstants.reportHideThreshold);
      expect(c.reportCount < AppConstants.reportHideThreshold, isFalse);
    });

    test('reportCount round-trips through JSON', () {
      final c = _challenge('c', reportCount: 2);
      expect(Challenge.fromJson('c', c.toJson()).reportCount, 2);
    });
  });
}
