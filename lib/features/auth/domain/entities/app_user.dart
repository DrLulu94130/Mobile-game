import '../../../../core/constants/app_constants.dart';

/// The authenticated user and their gameplay/progression profile.
class AppUser {
  const AppUser({
    required this.uid,
    required this.displayName,
    this.email,
    this.avatarUrl,
    this.isAnonymous = false,
    this.isPremium = false,
    this.xp = 0,
    this.level = 1,
    this.streakDays = 0,
    this.lastActiveDay,
    this.challengesCreated = 0,
    this.challengesSolved = 0,
    this.badgeIds = const [],
    this.followerCount = 0,
    this.tokens = AppConstants.startingTokens,
    this.createdAt,
  });

  final String uid;
  final String displayName;
  final String? email;
  final String? avatarUrl;
  final bool isAnonymous;
  final bool isPremium;

  // Progression
  final int xp;
  final int level;
  final int streakDays;

  /// yyyy-mm-dd of the last day the user was active, for streak tracking.
  final String? lastActiveDay;

  final int challengesCreated;
  final int challengesSolved;
  final List<String> badgeIds;
  final int followerCount;

  /// Spendable "jetons" earned by seeking; publishing a drawing costs some.
  final int tokens;

  final DateTime? createdAt;

  AppUser copyWith({
    String? displayName,
    String? avatarUrl,
    bool? isPremium,
    int? xp,
    int? level,
    int? streakDays,
    String? lastActiveDay,
    int? challengesCreated,
    int? challengesSolved,
    List<String>? badgeIds,
    int? followerCount,
    int? tokens,
  }) {
    return AppUser(
      uid: uid,
      displayName: displayName ?? this.displayName,
      email: email,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      isAnonymous: isAnonymous,
      isPremium: isPremium ?? this.isPremium,
      xp: xp ?? this.xp,
      level: level ?? this.level,
      streakDays: streakDays ?? this.streakDays,
      lastActiveDay: lastActiveDay ?? this.lastActiveDay,
      challengesCreated: challengesCreated ?? this.challengesCreated,
      challengesSolved: challengesSolved ?? this.challengesSolved,
      badgeIds: badgeIds ?? this.badgeIds,
      followerCount: followerCount ?? this.followerCount,
      tokens: tokens ?? this.tokens,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'displayName': displayName,
        'email': email,
        'avatarUrl': avatarUrl,
        'isAnonymous': isAnonymous,
        'isPremium': isPremium,
        'xp': xp,
        'level': level,
        'streakDays': streakDays,
        'lastActiveDay': lastActiveDay,
        'challengesCreated': challengesCreated,
        'challengesSolved': challengesSolved,
        'badgeIds': badgeIds,
        'followerCount': followerCount,
        'tokens': tokens,
      };

  factory AppUser.fromJson(String uid, Map<String, dynamic> json) {
    return AppUser(
      uid: uid,
      displayName: json['displayName'] as String? ?? 'Player',
      email: json['email'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
      isAnonymous: json['isAnonymous'] as bool? ?? false,
      isPremium: json['isPremium'] as bool? ?? false,
      xp: (json['xp'] as num?)?.toInt() ?? 0,
      level: (json['level'] as num?)?.toInt() ?? 1,
      streakDays: (json['streakDays'] as num?)?.toInt() ?? 0,
      lastActiveDay: json['lastActiveDay'] as String?,
      challengesCreated: (json['challengesCreated'] as num?)?.toInt() ?? 0,
      challengesSolved: (json['challengesSolved'] as num?)?.toInt() ?? 0,
      badgeIds: (json['badgeIds'] as List? ?? []).cast<String>(),
      followerCount: (json['followerCount'] as num?)?.toInt() ?? 0,
      // Profiles created before the token economy start with the same grant
      // as new players.
      tokens: (json['tokens'] as num?)?.toInt() ?? AppConstants.startingTokens,
    );
  }

  static AppUser guest() => const AppUser(
        uid: '',
        displayName: 'Guest',
        isAnonymous: true,
      );
}
