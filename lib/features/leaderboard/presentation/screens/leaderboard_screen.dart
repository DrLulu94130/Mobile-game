import 'package:flutter/material.dart';
import 'package:inkognito/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/app_widgets.dart';
import '../../../auth/domain/entities/app_user.dart';
import '../../data/leaderboard_providers.dart';

/// Rankings hub with two tabs: top players (by XP) and popular creators.
class LeaderboardScreen extends ConsumerWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l.rankings,
              style: const TextStyle(fontWeight: FontWeight.w900)),
          bottom: TabBar(
            tabs: [Tab(text: l.topPlayers), Tab(text: l.creators)],
          ),
        ),
        body: TabBarView(
          children: [
            _PlayerList(provider: topPlayersProvider, metric: _Metric.xp),
            _PlayerList(
              provider: popularCreatorsProvider,
              metric: _Metric.created,
            ),
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
