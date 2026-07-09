import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/errors/failures.dart';
import '../../../core/providers/firebase_providers.dart';
import '../../../core/utils/result.dart';
import '../domain/entities/challenge.dart';

/// Persists and queries [Challenge] documents in Firestore.
class ChallengeRepository {
  ChallengeRepository(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _col =>
      _firestore.collection(AppConstants.challengesCollection);

  /// Reserves a document id ahead of image upload so storage paths are stable.
  String newId() => _col.doc().id;

  Future<Result<Challenge>> create(Challenge challenge) async {
    try {
      await _col.doc(challenge.id).set({
        ...challenge.toJson(),
        'createdAt': FieldValue.serverTimestamp(),
        'searchDay': _dayKey(DateTime.now()),
      });
      return Success(challenge);
    } on FirebaseException catch (e) {
      return Err(_map(e));
    } catch (_) {
      return const Err(UnknownFailure());
    }
  }

  Future<Result<Challenge>> getById(String id) async {
    try {
      final doc = await _col.doc(id).get();
      if (!doc.exists) return const Err(NotFoundFailure());
      return Success(Challenge.fromJson(doc.id, doc.data()!));
    } on FirebaseException catch (e) {
      return Err(_map(e));
    }
  }

  /// Global community feed, most recent first, paginated.
  Stream<List<Challenge>> watchFeed({int limit = 20}) {
    return _col
        .where('isPublic', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map(_mapDocs);
  }

  /// Trending: highest play counts in the recent window.
  Stream<List<Challenge>> watchTrending({int limit = 20}) {
    return _col
        .where('isPublic', isEqualTo: true)
        .orderBy('playCount', descending: true)
        .limit(limit)
        .snapshots()
        .map(_mapDocs);
  }

  /// "Challenge of the day" — public challenges created today ordered by likes.
  Stream<List<Challenge>> watchDaily({DateTime? day}) {
    final key = _dayKey(day ?? DateTime.now());
    return _col
        .where('searchDay', isEqualTo: key)
        .where('isPublic', isEqualTo: true)
        .orderBy('likeCount', descending: true)
        .limit(20)
        .snapshots()
        .map(_mapDocs);
  }

  Stream<List<Challenge>> watchByAuthor(String authorId) {
    return _col
        .where('authorId', isEqualTo: authorId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(_mapDocs);
  }

  Future<void> incrementPlayCount(String id) {
    return _col.doc(id).update({'playCount': FieldValue.increment(1)});
  }

  /// Records the outcome of a Discover round and refreshes the drawing's
  /// note atomically: the note is the share of seekers the drawing fooled.
  Future<void> recordSeekResult(String id, {required bool foundAll}) async {
    await _firestore.runTransaction((tx) async {
      final ref = _col.doc(id);
      final snap = await tx.get(ref);
      if (!snap.exists) return;
      final data = snap.data()!;
      final wins =
          ((data['seekWinCount'] as num?)?.toInt() ?? 0) + (foundAll ? 1 : 0);
      final fails =
          ((data['seekFailCount'] as num?)?.toInt() ?? 0) + (foundAll ? 0 : 1);
      tx.update(ref, {
        'seekWinCount': wins,
        'seekFailCount': fails,
        'ratingScore': Challenge.computeRatingScore(wins, fails),
      });
    });
  }

  /// Best-noted public drawings for the rankings tab.
  Stream<List<Challenge>> watchTopRated({int limit = 50}) {
    return _col
        .where('isPublic', isEqualTo: true)
        .orderBy('ratingScore', descending: true)
        .limit(limit)
        .snapshots()
        .map(_mapDocs);
  }

  /// Records a new best time transactionally when it beats the stored one.
  Future<void> recordBestTime(String id, int timeMs) async {
    await _firestore.runTransaction((tx) async {
      final ref = _col.doc(id);
      final snap = await tx.get(ref);
      final current = (snap.data()?['bestTimeMs'] as num?)?.toInt();
      if (current == null || timeMs < current) {
        tx.update(ref, {'bestTimeMs': timeMs});
      }
    });
  }

  Future<void> delete(String id) => _col.doc(id).delete();

  /// Flags a drawing for moderation. Once [AppConstants.reportHideThreshold]
  /// reports accumulate the drawing drops out of the feeds (client-side).
  Future<void> report(String id) {
    return _col.doc(id).update({'reportCount': FieldValue.increment(1)});
  }

  /// Maps documents and hides those the community has flagged past the
  /// moderation threshold, so reported content disappears from every feed.
  List<Challenge> _mapDocs(QuerySnapshot<Map<String, dynamic>> snap) =>
      snap.docs
          .map((d) => Challenge.fromJson(d.id, d.data()))
          .where((c) => c.reportCount < AppConstants.reportHideThreshold)
          .toList();

  String _dayKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Failure _map(FirebaseException e) => switch (e.code) {
        'permission-denied' => const PermissionFailure(),
        'unavailable' => const NetworkFailure(),
        'not-found' => const NotFoundFailure(),
        _ => UnknownFailure(e.message ?? 'Firestore error'),
      };
}

final challengeRepositoryProvider = Provider<ChallengeRepository>(
  (ref) => ChallengeRepository(ref.watch(firestoreProvider)),
);

/// How many drawings the feed currently requests. Grows as the player scrolls
/// (see [feedProvider]); reset when the feed screen is disposed.
final feedLimitProvider = StateProvider.autoDispose<int>((ref) => 20);

/// Feed stream provider consumed by the community screen. Re-subscribes with a
/// larger window whenever [feedLimitProvider] grows.
final feedProvider = StreamProvider.autoDispose<List<Challenge>>((ref) {
  final limit = ref.watch(feedLimitProvider);
  return ref.watch(challengeRepositoryProvider).watchFeed(limit: limit);
});

final trendingProvider = StreamProvider.autoDispose<List<Challenge>>(
  (ref) => ref.watch(challengeRepositoryProvider).watchTrending(),
);

final dailyChallengesProvider = StreamProvider.autoDispose<List<Challenge>>(
  (ref) => ref.watch(challengeRepositoryProvider).watchDaily(),
);

final challengeByIdProvider =
    FutureProvider.autoDispose.family<Challenge, String>(
  (ref, id) async {
    final result = await ref.watch(challengeRepositoryProvider).getById(id);
    return result.when(
      success: (c) => c,
      failure: (f) => throw f,
    );
  },
);

final challengesByAuthorProvider =
    StreamProvider.autoDispose.family<List<Challenge>, String>(
  (ref, authorId) =>
      ref.watch(challengeRepositoryProvider).watchByAuthor(authorId),
);

/// Drawings ranked by their note (share of seekers fooled).
final topRatedChallengesProvider = StreamProvider.autoDispose<List<Challenge>>(
  (ref) => ref.watch(challengeRepositoryProvider).watchTopRated(),
);

/// The pool of drawings served to the Discover (scroll & seek) mode.
final discoverChallengesProvider = StreamProvider.autoDispose<List<Challenge>>(
  (ref) => ref.watch(challengeRepositoryProvider).watchFeed(limit: 50),
);
