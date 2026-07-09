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

  /// Credits one scroll token, but only while the player is under the daily
  /// scroll cap — swiping without playing can't bankroll unlimited posts.
  /// Returns the amount actually credited (0 when the cap is reached).
  Future<int> earnScrollToken(String uid, {DateTime? now}) async {
    return _firestore.runTransaction((tx) async {
      final ref = _userDoc(uid);
      final snap = await tx.get(ref);
      final data = snap.data() ?? {};
      final today = _dayKey(now ?? DateTime.now());
      final storedDay = data['scrollTokensDay'] as String?;
      final usedToday = storedDay == today
          ? (data['scrollTokensToday'] as num?)?.toInt() ?? 0
          : 0;
      if (usedToday >= AppConstants.maxDailyScrollTokens) return 0;
      const amount = AppConstants.tokensPerDiscoverScroll;
      tx.set(
        ref,
        {
          'tokens': FieldValue.increment(amount),
          'scrollTokensDay': today,
          'scrollTokensToday': usedToday + amount,
        },
        SetOptions(merge: true),
      );
      return amount;
    });
  }

  static String _dayKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

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
