/// Application-wide constants and tuning parameters.
abstract class AppConstants {
  static const String appName = 'Inkognito';

  // Free-tier limits (lifted for Premium members).
  static const int freeDailyChallenges = 3;
  static const int freeMaxInklingsPerChallenge = 3;
  static const int premiumMaxInklingsPerChallenge = 12;

  // Progression tuning.
  static const int xpPerChallengeCreated = 50;
  static const int xpPerChallengeSolved = 30;
  static const int xpPerInklingFound = 10;
  static const int xpPerLike = 2;

  // Token economy ("jetons"): scrolling the Discover feed earns tokens,
  // publishing a drawing costs them. Premium members publish for free.
  static const int startingTokens = 15;
  static const int tokensPerDiscoverScroll = 1;
  static const int tokensPerDiscoverWin = 2;
  static const int tokensToPublish = 15;
  static const int tokensPerRewardedAd = 5;

  /// Scroll tokens are capped per day so swiping without playing cannot
  /// bankroll unlimited posts; win bonuses stay uncapped.
  static const int maxDailyScrollTokens = 30;

  // Discover mode: the seeker has this long to find every Inkling before the
  // drawing wins the round. Bigger drawings grant extra time; Premium always
  // enjoys a small bonus.
  static const int discoverRoundSeconds = 10;
  static const int discoverBaselineInklings = 3;
  static const int discoverExtraSecondsPerInkling = 2;
  static const int premiumDiscoverBonusSeconds = 5;

  /// Seconds allowed for a Discover round with [inklingCount] creatures.
  static int discoverSecondsFor(int inklingCount, {bool premium = false}) {
    final extra = (inklingCount - discoverBaselineInklings).clamp(0, 9);
    return discoverRoundSeconds +
        extra * discoverExtraSecondsPerInkling +
        (premium ? premiumDiscoverBonusSeconds : 0);
  }

  /// Win bonus grows with the current win streak (capped at +3 extra).
  static int discoverWinBonus(int winStreak) =>
      tokensPerDiscoverWin + (winStreak - 1).clamp(0, 3);

  /// The daily featured drawing pays double when beaten.
  static const int dailyChallengeBonusMultiplier = 2;

  // A drawing needs this many seek attempts before its note is shown/ranked.
  static const int minSeekAttemptsForRating = 3;

  /// Drawings reported at least this many times are hidden from feeds until
  /// a moderator reviews them.
  static const int reportHideThreshold = 3;

  /// XP required to reach level `n` follows a smooth quadratic curve.
  static int xpForLevel(int level) => (level * level * 40) + (level * 60);

  // Detection tuning: how close (fraction of the shortest screen side) a tap
  // must be to an Inkling centre to count as a find.
  static const double detectionToleranceFactor = 0.09;

  // Firestore collections.
  static const String usersCollection = 'users';
  static const String challengesCollection = 'challenges';
  static const String attemptsCollection = 'attempts';
  static const String commentsCollection = 'comments';
  static const String likesCollection = 'likes';

  // Storage paths.
  static String challengeImagePath(String challengeId) =>
      'challenges/$challengeId/camouflaged.jpg';
  static String challengeRevealPath(String challengeId) =>
      'challenges/$challengeId/revealed.jpg';
  static String avatarPath(String uid) => 'avatars/$uid.jpg';
}
