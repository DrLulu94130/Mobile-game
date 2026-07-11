import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/detection_engine.dart';

/// Submits finished play sessions to the `submitAttempt` Cloud Function.
///
/// The server is authoritative: it re-runs detection against the challenge's
/// ground truth, recomputes the score, stores the attempt and pays out
/// progression (XP, streak, badges). The client only ships its raw taps and
/// claimed duration, so nothing reward-bearing can be fabricated locally.
class PlayResultService {
  PlayResultService(this._functions);

  final FirebaseFunctions _functions;

  /// Best-effort submission — an offline round still shows its local result,
  /// there is simply nothing recorded server-side to roll back.
  Future<void> submit({
    required String challengeId,
    required PlaySession session,
  }) async {
    try {
      await _functions.httpsCallable('submitAttempt').call<dynamic>({
        'challengeId': challengeId,
        'taps': session.taps.expand((o) => [o.dx, o.dy]).toList(),
        'durationMs': session.elapsed.inMilliseconds,
      });
    } catch (_) {
      // Progression is server-owned; a failed call awards nothing and the
      // player can simply play on.
    }
  }
}

final playResultServiceProvider = Provider<PlayResultService>(
  (ref) => PlayResultService(FirebaseFunctions.instance),
);
