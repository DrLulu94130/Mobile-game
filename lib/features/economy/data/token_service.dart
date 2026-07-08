import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/providers/firebase_providers.dart';

/// Owns the "jetons" balance stored on the user document. Seekers earn
/// tokens by scrolling the Discover feed; publishing a drawing spends them.
class TokenService {
  TokenService(this._firestore);

  final FirebaseFirestore _firestore;

  DocumentReference<Map<String, dynamic>> _userDoc(String uid) =>
      _firestore.collection(AppConstants.usersCollection).doc(uid);

  /// Credits [amount] tokens (no-op for non-positive amounts).
  Future<void> earn(String uid, int amount) async {
    if (amount <= 0) return;
    await _userDoc(uid).set(
      {'tokens': FieldValue.increment(amount)},
      SetOptions(merge: true),
    );
  }

  /// Debits [amount] tokens transactionally. Returns `false` (and leaves the
  /// balance untouched) when the user cannot afford it.
  Future<bool> trySpend(String uid, int amount) async {
    if (amount <= 0) return true;
    return _firestore.runTransaction((tx) async {
      final ref = _userDoc(uid);
      final snap = await tx.get(ref);
      // Profiles created before the token economy hold the starting grant.
      final balance = (snap.data()?['tokens'] as num?)?.toInt() ??
          AppConstants.startingTokens;
      if (balance < amount) return false;
      tx.set(
        ref,
        {'tokens': balance - amount},
        SetOptions(merge: true),
      );
      return true;
    });
  }
}

final tokenServiceProvider = Provider<TokenService>(
  (ref) => TokenService(ref.watch(firestoreProvider)),
);
