import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/providers/firebase_providers.dart';
import '../domain/entities/comment.dart';

/// Handles social interactions: likes and comments on challenges.
class CommunityRepository {
  CommunityRepository(this._firestore);

  final FirebaseFirestore _firestore;

  DocumentReference<Map<String, dynamic>> _challenge(String id) =>
      _firestore.collection(AppConstants.challengesCollection).doc(id);

  /// Whether [uid] has liked [challengeId].
  Stream<bool> watchLiked(String challengeId, String uid) {
    return _challenge(challengeId)
        .collection(AppConstants.likesCollection)
        .doc(uid)
        .snapshots()
        .map((d) => d.exists);
  }

  /// Toggles a like using a transaction so the denormalised count stays exact.
  Future<void> toggleLike(String challengeId, String uid) async {
    final likeRef = _challenge(challengeId)
        .collection(AppConstants.likesCollection)
        .doc(uid);
    await _firestore.runTransaction((tx) async {
      final challengeRef = _challenge(challengeId);
      final likeSnap = await tx.get(likeRef);
      if (likeSnap.exists) {
        tx.delete(likeRef);
        tx.update(challengeRef, {'likeCount': FieldValue.increment(-1)});
      } else {
        tx.set(likeRef, {'createdAt': FieldValue.serverTimestamp()});
        tx.update(challengeRef, {'likeCount': FieldValue.increment(1)});
      }
    });
  }

  Stream<List<Comment>> watchComments(String challengeId) {
    return _challenge(challengeId)
        .collection(AppConstants.commentsCollection)
        .orderBy('createdAt', descending: true)
        .limit(100)
        .snapshots()
        .map(
          (s) => s.docs.map((d) => Comment.fromJson(d.id, d.data())).toList(),
        );
  }

  Future<void> addComment(Comment comment) async {
    final ref = _challenge(comment.challengeId)
        .collection(AppConstants.commentsCollection)
        .doc();
    await _firestore.runTransaction((tx) async {
      tx.set(ref, {
        ...comment.toJson(),
        'createdAt': FieldValue.serverTimestamp(),
      });
      tx.update(
        _challenge(comment.challengeId),
        {'commentCount': FieldValue.increment(1)},
      );
    });
  }
}

final communityRepositoryProvider = Provider<CommunityRepository>(
  (ref) => CommunityRepository(ref.watch(firestoreProvider)),
);

final commentsProvider =
    StreamProvider.autoDispose.family<List<Comment>, String>(
  (ref, challengeId) =>
      ref.watch(communityRepositoryProvider).watchComments(challengeId),
);

final likedProvider =
    StreamProvider.autoDispose.family<bool, ({String challengeId, String uid})>(
  (ref, args) => ref
      .watch(communityRepositoryProvider)
      .watchLiked(args.challengeId, args.uid),
);
