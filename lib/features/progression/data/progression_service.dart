import '../../../core/constants/app_constants.dart';

/// Client-side progression helpers for display purposes only.
///
/// XP, levels, streaks and badge awards are computed and written
/// server-side (the `submitAttempt` callable and the `onChallengeCreated`
/// trigger); the client merely renders what the server decided. These
/// static formulas mirror the server's and exist for progress bars and
/// level labels.
abstract class ProgressionService {
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
}
