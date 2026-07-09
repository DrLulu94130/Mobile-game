import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/providers/firebase_providers.dart';
import '../../auth/domain/entities/app_user.dart';

/// Global leaderboard ordered by XP (top players).
final topPlayersProvider = StreamProvider.autoDispose<List<AppUser>>((ref) {
  final firestore = ref.watch(firestoreProvider);
  return firestore
      .collection(AppConstants.usersCollection)
      .orderBy('xp', descending: true)
      .limit(50)
      .snapshots()
      .map((s) => s.docs.map((d) => AppUser.fromJson(d.id, d.data())).toList());
});

/// Popular creators ordered by follower count.
final popularCreatorsProvider =
    StreamProvider.autoDispose<List<AppUser>>((ref) {
  final firestore = ref.watch(firestoreProvider);
  return firestore
      .collection(AppConstants.usersCollection)
      .orderBy('challengesCreated', descending: true)
      .limit(20)
      .snapshots()
      .map((s) => s.docs.map((d) => AppUser.fromJson(d.id, d.data())).toList());
});

/// A single creator's public profile, streamed by uid.
final userByIdProvider =
    StreamProvider.autoDispose.family<AppUser?, String>((ref, uid) {
  final firestore = ref.watch(firestoreProvider);
  return firestore
      .collection(AppConstants.usersCollection)
      .doc(uid)
      .snapshots()
      .map((d) => d.exists ? AppUser.fromJson(d.id, d.data()!) : null);
});
