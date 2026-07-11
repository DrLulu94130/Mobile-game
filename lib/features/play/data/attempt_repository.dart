import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/providers/firebase_providers.dart';
import '../domain/entities/attempt.dart';

/// Reads play attempts (written server-side by the `submitAttempt`
/// Cloud Function) and exposes per-challenge leaderboards.
class AttemptRepository {
  AttemptRepository(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _col =>
      _firestore.collection(AppConstants.attemptsCollection);

  /// Top attempts for a challenge, ranked by score.
  Stream<List<Attempt>> watchLeaderboard(String challengeId, {int limit = 20}) {
    return _col
        .where('challengeId', isEqualTo: challengeId)
        .orderBy('score', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (s) => s.docs.map((d) => Attempt.fromJson(d.id, d.data())).toList(),
        );
  }
}

final attemptRepositoryProvider = Provider<AttemptRepository>(
  (ref) => AttemptRepository(ref.watch(firestoreProvider)),
);

final challengeLeaderboardProvider =
    StreamProvider.autoDispose.family<List<Attempt>, String>(
  (ref, challengeId) =>
      ref.watch(attemptRepositoryProvider).watchLeaderboard(challengeId),
);
