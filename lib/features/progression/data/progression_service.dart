import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/providers/firebase_providers.dart';
import '../../auth/domain/entities/app_user.dart';
import '../domain/entities/badge.dart';

/// Result of applying an XP change: exposes whether the user levelled up or
/// earned new badges so the UI can celebrate.
class ProgressionUpdate {
  const ProgressionUpdate({
    required this.newXp,
    required this.newLevel,
    required this.leveledUp,
    required this.newBadgeIds,
    required this.streakDays,
  });

  final int newXp;
  final int newLevel;
  final bool leveledUp;
  final List<String> newBadgeIds;
  final int streakDays;
}

/// Owns XP, levelling, daily streaks and badge unlocks. All writes are made
/// transactionally against the user document.
class ProgressionService {
  ProgressionService(this._firestore);

  final FirebaseFirestore _firestore;

  DocumentReference<Map<String, dynamic>> _userDoc(String uid) =>
      _firestore.collection(AppConstants.usersCollection).doc(uid);

  /// Awards [xpDelta] and recomputes level, streak and badges atomically.
  Future<ProgressionUpdate> awardXp({
    required String uid,
    required int xpDelta,
    int challengesCreatedDelta = 0,
    int challengesSolvedDelta = 0,
    int perfectSolvesDelta = 0,
    int totalLikesDelta = 0,
  }) async {
    late ProgressionUpdate update;
    await _firestore.runTransaction((tx) async {
      final ref = _userDoc(uid);
      final snap = await tx.get(ref);
      final data = snap.data() ?? {};
      final user = AppUser.fromJson(uid, data);

      final newXp = user.xp + xpDelta;
      final newLevel = levelForXp(newXp);
      final leveledUp = newLevel > user.level;

      final streak = computeStreak(user.lastActiveDay, user.streakDays);
      final today = _todayKey();

      final ctx = BadgeContext(
        challengesCreated: user.challengesCreated + challengesCreatedDelta,
        challengesSolved: user.challengesSolved + challengesSolvedDelta,
        streakDays: streak,
        level: newLevel,
        perfectSolves: ((data['perfectSolves'] as num?)?.toInt() ?? 0) +
            perfectSolvesDelta,
        totalLikes:
            ((data['totalLikes'] as num?)?.toInt() ?? 0) + totalLikesDelta,
      );
      final badges = mergedBadges(user.badgeIds, ctx);
      final newBadges =
          badges.where((id) => !user.badgeIds.contains(id)).toList();

      tx.set(
        ref,
        {
          'xp': newXp,
          'level': newLevel,
          'streakDays': streak,
          'lastActiveDay': today,
          'challengesCreated': FieldValue.increment(challengesCreatedDelta),
          'challengesSolved': FieldValue.increment(challengesSolvedDelta),
          'perfectSolves': FieldValue.increment(perfectSolvesDelta),
          'totalLikes': FieldValue.increment(totalLikesDelta),
          'badgeIds': badges,
        },
        SetOptions(merge: true),
      );

      update = ProgressionUpdate(
        newXp: newXp,
        newLevel: newLevel,
        leveledUp: leveledUp,
        newBadgeIds: newBadges,
        streakDays: streak,
      );
    });
    return update;
  }

  /// Smallest level whose cumulative XP threshold is not yet exceeded.
  static int levelForXp(int xp) {
    var level = 1;
    while (xp >= AppConstants.xpForLevel(level)) {
      level++;
    }
    return level;
  }

  /// XP progress (0..1) within the current level.
  static double levelProgress(int xp, int level) {
    final floor = level > 1 ? AppConstants.xpForLevel(level - 1) : 0;
    final ceil = AppConstants.xpForLevel(level);
    if (ceil == floor) return 0;
    return ((xp - floor) / (ceil - floor)).clamp(0.0, 1.0);
  }

  /// Badges are permanent: once earned they are never revoked, even when the
  /// underlying stat later regresses (e.g. a broken streak).
  static List<String> mergedBadges(List<String> existing, BadgeContext ctx) =>
      {...existing, ...BadgeCatalog.earned(ctx)}.toList();

  /// Given the last active day and the streak stored on that day, returns the
  /// streak value for [now] (defaults to today).
  static int computeStreak(
    String? lastActiveDay,
    int storedStreak, {
    DateTime? now,
  }) {
    if (lastActiveDay == null) return 1;
    final last = DateTime.tryParse(lastActiveDay);
    if (last == null) return 1;
    final ref = now ?? DateTime.now();
    final diff = DateTime(ref.year, ref.month, ref.day)
        .difference(DateTime(last.year, last.month, last.day))
        .inDays;
    if (diff <= 0) return storedStreak == 0 ? 1 : storedStreak; // same day
    if (diff == 1) return storedStreak + 1; // consecutive day
    return 1; // streak broken
  }

  String _todayKey() {
    final d = DateTime.now();
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }
}

final progressionServiceProvider = Provider<ProgressionService>(
  (ref) => ProgressionService(ref.watch(firestoreProvider)),
);
