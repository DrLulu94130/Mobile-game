import 'package:flutter/material.dart';
import 'package:inkognito/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/app_widgets.dart';
import '../../../challenge/data/challenge_repository.dart';
import '../../../editor/domain/entities/inkling_species.dart';
import '../../../../shared/widgets/inkling_avatar.dart';
import '../widgets/challenge_card.dart';

/// The community feed: a scrollable list of the newest public challenges plus
/// a trending strip and "popular creators".
class FeedScreen extends ConsumerWidget {
  const FeedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feed = ref.watch(feedProvider);
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(feedProvider),
        child: CustomScrollView(
          slivers: [
            const SliverAppBar(
              floating: true,
              titleSpacing: 20,
              title: Text(
                'Inkognito',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 24),
              ),
              actions: [
                Padding(
                  padding: EdgeInsets.only(right: 12),
                  child: _PremiumChip(),
                ),
              ],
            ),
            const SliverToBoxAdapter(child: _TrendingStrip()),
            feed.when(
              loading: () => const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => SliverFillRemaining(
                child: StateMessage(
                  icon: Icons.wifi_off,
                  title: AppLocalizations.of(context).feedEmptyTitle,
                  subtitle: '$e',
                ),
              ),
              data: (challenges) {
                if (challenges.isEmpty) {
                  final l = AppLocalizations.of(context);
                  return SliverFillRemaining(
                    child: StateMessage(
                      icon: Icons.explore_off_outlined,
                      title: l.feedEmptyTitle,
                      subtitle: l.feedEmptyBody,
                      action: FilledButton.icon(
                        onPressed: () => context.push(Routes.create),
                        icon: const Icon(Icons.add),
                        label: Text(l.createOne),
                      ),
                    ),
                  );
                }
                return SliverList.builder(
                  itemCount: challenges.length,
                  itemBuilder: (_, i) =>
                      ChallengeCard(challenge: challenges[i]),
                );
              },
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 80)),
          ],
        ),
      ),
    );
  }
}

class _PremiumChip extends StatelessWidget {
  const _PremiumChip();

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      avatar: const Icon(Icons.workspace_premium, size: 18, color: AppColors.glow),
      label: Text(AppLocalizations.of(context).premium),
      onPressed: () => context.push(Routes.premium),
    );
  }
}

/// Horizontal strip of trending challenges (by play count).
class _TrendingStrip extends ConsumerWidget {
  const _TrendingStrip();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trending = ref.watch(trendingProvider);
    return trending.maybeWhen(
      data: (list) {
        if (list.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
              child: Text(
                AppLocalizations.of(context).feedTrending,
                style:
                    const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
              ),
            ),
            SizedBox(
              height: 96,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: list.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (_, i) {
                  final c = list[i];
                  return GestureDetector(
                    onTap: () => context.push(Routes.playPath(c.id)),
                    child: Column(
                      children: [
                        const InklingAvatar(
                          species: InklingSpecies.classic,
                          size: 56,
                        ),
                        const SizedBox(height: 4),
                        SizedBox(
                          width: 70,
                          child: Text(
                            c.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
      orElse: () => const SizedBox.shrink(),
    );
  }
}
