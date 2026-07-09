import 'dart:math' as math;

import '../../challenge/domain/entities/challenge.dart';

/// Pure ordering logic for the Discover feed, isolated for unit testing.
abstract class DiscoverFeed {
  /// Orders the pool served to the seeker:
  ///  * the seeker's own drawings and empty ones are dropped (they know the
  ///    answer / there is nothing to find);
  ///  * the featured daily drawing, when present, always comes first;
  ///  * the rest are shuffled with a per-session [seed] but weighted toward
  ///    least-played drawings, so fresh creations get exposure instead of the
  ///    same popular few dominating every session.
  static List<Challenge> order(
    List<Challenge> pool, {
    required String? viewerId,
    String? dailyId,
    int seed = 0,
  }) {
    final playable = pool
        .where((c) => c.authorId != viewerId && c.inklings.isNotEmpty)
        .toList();

    Challenge? daily;
    final rest = <Challenge>[];
    for (final c in playable) {
      if (dailyId != null && c.id == dailyId && daily == null) {
        daily = c;
      } else {
        rest.add(c);
      }
    }

    final rand = math.Random(seed);
    // Weighted shuffle: each drawing gets a sort key blended from randomness
    // and an exposure boost (fewer plays → smaller key → served earlier).
    rest.sort((a, b) {
      final ka = _key(a, rand.nextDouble());
      final kb = _key(b, rand.nextDouble());
      return ka.compareTo(kb);
    });

    return [if (daily != null) daily, ...rest];
  }

  static double _key(Challenge c, double noise) {
    // Exposure factor in [0,1): brand-new drawings ≈ 0, very-played ≈ 1.
    final exposure = c.playCount / (c.playCount + 12.0);
    // 70% chance-driven, 30% exposure-driven.
    return noise * 0.7 + exposure * 0.3;
  }
}
