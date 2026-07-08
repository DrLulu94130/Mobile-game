import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:inkognito/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/app_widgets.dart';
import '../../../auth/data/auth_repository.dart';
import '../../../auth/domain/entities/app_user.dart';
import '../../../challenge/data/challenge_repository.dart';
import '../../../progression/data/progression_service.dart';
import '../../../progression/domain/entities/badge.dart' as domain;

/// The signed-in user's profile: identity, progression, badges and their
/// created challenges.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(currentUserProvider);
    return Scaffold(
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => StateMessage(
          icon: Icons.error_outline,
          title: 'Could not load profile',
          subtitle: '$e',
        ),
        data: (user) {
          if (user == null) {
            return const Center(child: CircularProgressIndicator());
          }
          return _ProfileView(user: user);
        },
      ),
    );
  }
}

class _ProfileView extends ConsumerWidget {
  const _ProfileView({required this.user});
  final AppUser user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final progress = ProgressionService.levelProgress(user.xp, user.level);
    final challenges = ref.watch(challengesByAuthorProvider(user.uid));

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          pinned: true,
          title: Text(l.navProfile,
              style: const TextStyle(fontWeight: FontWeight.w900)),
          actions: [
            IconButton(
              icon: const Icon(Icons.settings_outlined),
              onPressed: () => context.push(Routes.settings),
            ),
          ],
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 34,
                      backgroundColor: AppColors.ink.withValues(alpha: 0.2),
                      backgroundImage: user.avatarUrl != null
                          ? CachedNetworkImageProvider(user.avatarUrl!)
                          : null,
                      child: user.avatarUrl == null
                          ? Text(
                              user.displayName.characters.first.toUpperCase(),
                              style: const TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.w800,
                                color: AppColors.ink,
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user.displayName,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          if (user.isPremium)
                            const Row(
                              children: [
                                Icon(Icons.workspace_premium,
                                    size: 16, color: AppColors.glow),
                                SizedBox(width: 4),
                                Text('Premium member'),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _LevelCard(user: user, progress: progress),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    StatPill(
                      value: '${user.challengesCreated}',
                      label: l.created,
                      icon: Icons.brush,
                    ),
                    StatPill(
                      value: '${user.challengesSolved}',
                      label: l.solved,
                      icon: Icons.visibility,
                    ),
                    StatPill(
                      value: '${user.streakDays}',
                      label: l.dayStreak,
                      icon: Icons.local_fire_department,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        SliverToBoxAdapter(child: _BadgeStrip(user: user)),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
            child: Text(
              l.yourChallenges,
              style:
                  const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
            ),
          ),
        ),
        challenges.when(
          loading: () => const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            ),
          ),
          error: (e, _) => SliverToBoxAdapter(child: Text('$e')),
          data: (list) => list.isEmpty
              ? SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(l.noChallengesYet),
                  ),
                )
              : SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverGrid.count(
                    crossAxisCount: 2,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    children: [
                      for (final c in list)
                        GestureDetector(
                          onTap: () =>
                              context.push(Routes.challengePath(c.id)),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: CachedNetworkImage(
                              imageUrl: c.camouflagedImageUrl,
                              fit: BoxFit.cover,
                              placeholder: (_, __) =>
                                  const ColoredBox(color: Colors.black12),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 80)),
      ],
    );
  }
}

class _LevelCard extends StatelessWidget {
  const _LevelCard({required this.user, required this.progress});
  final AppUser user;
  final double progress;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: AppColors.brandGradient,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l.level(user.level),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                l.xpValue(user.xp),
                style: const TextStyle(color: Colors.white70),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              backgroundColor: Colors.white24,
              valueColor: const AlwaysStoppedAnimation(Colors.white),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            l.toNextLevel(((1 - progress) * 100).round(), user.level + 1),
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _BadgeStrip extends StatelessWidget {
  const _BadgeStrip({required this.user});
  final AppUser user;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  AppLocalizations.of(context).badges,
                  style: const TextStyle(
                      fontWeight: FontWeight.w800, fontSize: 16),
                ),
                TextButton(
                  onPressed: () => context.push(Routes.badges),
                  child: Text(AppLocalizations.of(context).seeAll),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 84,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                for (final badge in domain.BadgeCatalog.all)
                  _BadgeChip(
                    badge: badge,
                    earned: user.badgeIds.contains(badge.id),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BadgeChip extends StatelessWidget {
  const _BadgeChip({required this.badge, required this.earned});
  final domain.Badge badge;
  final bool earned;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: earned
                  ? badge.color.withValues(alpha: 0.18)
                  : AppColors.textMuted.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              badge.icon,
              color: earned ? badge.color : AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 4),
          SizedBox(
            width: 64,
            child: Text(
              badge.name,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }
}
