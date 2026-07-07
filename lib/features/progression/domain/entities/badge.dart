import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// An unlockable achievement badge.
class Badge {
  const Badge({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.color,
    required this.requirement,
  });

  final String id;
  final String name;
  final String description;
  final IconData icon;
  final Color color;

  /// Evaluated against a [BadgeContext] to decide if the badge is earned.
  final bool Function(BadgeContext ctx) requirement;
}

/// Snapshot of the values a badge requirement may inspect.
class BadgeContext {
  const BadgeContext({
    required this.challengesCreated,
    required this.challengesSolved,
    required this.streakDays,
    required this.level,
    required this.perfectSolves,
    required this.totalLikes,
  });

  final int challengesCreated;
  final int challengesSolved;
  final int streakDays;
  final int level;
  final int perfectSolves;
  final int totalLikes;
}

/// The canonical catalogue of badges available in the game.
abstract class BadgeCatalog {
  static final List<Badge> all = [
    Badge(
      id: 'first_hide',
      name: 'First Hide',
      description: 'Create your first challenge',
      icon: Icons.auto_awesome,
      color: AppColors.ink,
      requirement: (c) => c.challengesCreated >= 1,
    ),
    Badge(
      id: 'sharp_eyes',
      name: 'Sharp Eyes',
      description: 'Solve 10 challenges',
      icon: Icons.visibility,
      color: AppColors.splash,
      requirement: (c) => c.challengesSolved >= 10,
    ),
    Badge(
      id: 'flawless',
      name: 'Flawless',
      description: 'Find every Inkling in 5 challenges',
      icon: Icons.stars,
      color: AppColors.glow,
      requirement: (c) => c.perfectSolves >= 5,
    ),
    Badge(
      id: 'on_fire',
      name: 'On Fire',
      description: 'Keep a 7-day streak',
      icon: Icons.local_fire_department,
      color: AppColors.coral,
      requirement: (c) => c.streakDays >= 7,
    ),
    Badge(
      id: 'crowd_favourite',
      name: 'Crowd Favourite',
      description: 'Earn 100 likes',
      icon: Icons.favorite,
      color: AppColors.error,
      requirement: (c) => c.totalLikes >= 100,
    ),
    Badge(
      id: 'master',
      name: 'Ink Master',
      description: 'Reach level 20',
      icon: Icons.workspace_premium,
      color: AppColors.inkDeep,
      requirement: (c) => c.level >= 20,
    ),
  ];

  static Badge? byId(String id) {
    for (final b in all) {
      if (b.id == id) return b;
    }
    return null;
  }

  /// Returns the ids of every badge earned for the given [ctx].
  static List<String> earned(BadgeContext ctx) =>
      all.where((b) => b.requirement(ctx)).map((b) => b.id).toList();
}
