import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:inkognito/l10n/app_localizations.dart';

import '../../../../core/router/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/app_widgets.dart';
import '../../../auth/domain/entities/app_user.dart';
import '../../../challenge/data/challenge_repository.dart';
import '../../../challenge/domain/entities/challenge.dart';
import '../../data/leaderboard_providers.dart';

/// Rankings hub with three tabs: top players (by XP), popular creators and
/// the best-noted drawings.
class LeaderboardScreen extends ConsumerWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            l.rankings,
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
          bottom: TabBar(
            tabs: [
              Tab(text: l.topPlayers),
              Tab(text: l.creators),
              Tab(text: l.topDrawings),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _PlayerList(provider: topPlayersProvider, metric: _Metric.xp),
            _PlayerList(
              provider: popularCreatorsProvider,
              metric: _Metric.created,
            ),
            const _DrawingList(),
          ],
        ),
      ),
    );
  }
}

enum _Metric { xp, created }

class _PlayerList extends ConsumerWidget {
  const _PlayerList({required this.provider, required this.metric});
  final AutoDisposeStreamProvider<List<AppUser>> provider;
  final _Metric metric;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(provider);
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => StateMessage(
        icon: Icons.error_outline,
        title: 'Could not load rankings',
        subtitle: '$e',
      ),
      data: (users) {
        if (users.isEmpty) {
          return const StateMessage(
            icon: Icons.emoji_events_outlined,
            title: 'No rankings yet',
            subtitle: 'Play and create to climb the board!',
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.only(bottom: 80),
          itemCount: users.length,
          itemBuilder: (_, i) => _RankRow(
            rank: i + 1,
            user: users[i],
            metric: metric,
          ),
        );
      },
    );
  }
}

/// Drawings ranked by their note — how often they fool seekers in Discover.
class _DrawingList extends ConsumerWidget {
  const _DrawingList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final async = ref.watch(topRatedChallengesProvider);
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => StateMessage(
        icon: Icons.error_outline,
        title: 'Could not load rankings',
        subtitle: '$e',
      ),
      data: (all) {
        // Only drawings with enough rounds have a meaningful note.
        final rated = all.where((c) => c.hasRating).toList();
        if (rated.isEmpty) {
          return StateMessage(
            icon: Icons.brush_outlined,
            title: l.noRatingYet,
            subtitle: l.discoverSwipeNext,
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.only(bottom: 80),
          itemCount: rated.length,
          itemBuilder: (_, i) => _DrawingRow(rank: i + 1, challenge: rated[i]),
        );
      },
    );
  }
}

class _DrawingRow extends StatelessWidget {
  const _DrawingRow({required this.rank, required this.challenge});
  final int rank;
  final Challenge challenge;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final medal = switch (rank) {
      1 => '🥇',
      2 => '🥈',
      3 => '🥉',
      _ => '$rank',
    };
    return ListTile(
      onTap: () => context.push(Routes.playPath(challenge.id)),
      leading: SizedBox(
        width: 36,
        child: Center(
          child: Text(
            medal,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
        ),
      ),
      title: Text(
        challenge.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
      subtitle: Text(
        '${challenge.authorName} · '
        '${l.seekStats(challenge.seekWinCount, challenge.seekFailCount)}',
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star_rounded, size: 18, color: AppColors.glow),
          const SizedBox(width: 2),
          Text(
            challenge.ratingStars.toStringAsFixed(1),
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(width: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: CachedNetworkImage(
              imageUrl: challenge.camouflagedImageUrl,
              width: 48,
              height: 48,
              fit: BoxFit.cover,
              placeholder: (_, __) => const ColoredBox(color: Colors.black12),
              errorWidget: (_, __, ___) =>
                  const Icon(Icons.broken_image_outlined),
            ),
          ),
        ],
      ),
      minLeadingWidth: 0,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
    );
  }
}

class _RankRow extends StatelessWidget {
  const _RankRow({
    required this.rank,
    required this.user,
    required this.metric,
  });
  final int rank;
  final AppUser user;
  final _Metric metric;

  @override
  Widget build(BuildContext context) {
    final medal = switch (rank) {
      1 => '🥇',
      2 => '🥈',
      3 => '🥉',
      _ => '$rank',
    };
    final value = metric == _Metric.xp
        ? '${user.xp} XP'
        : '${user.challengesCreated} made';
    return ListTile(
      leading: SizedBox(
        width: 36,
        child: Center(
          child: Text(
            medal,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
        ),
      ),
      title: Text(
        user.displayName,
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
      subtitle: Text('Level ${user.level} · ${user.streakDays}🔥'),
      trailing: Text(
        value,
        style: const TextStyle(
          fontWeight: FontWeight.w800,
          color: AppColors.ink,
        ),
      ),
      leadingAndTrailingTextStyle: const TextStyle(color: AppColors.textMuted),
      minLeadingWidth: 0,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      // Avatar behind the rank number.
      onTap: null,
    );
  }
}
