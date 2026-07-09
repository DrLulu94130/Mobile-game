import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:inkognito/l10n/app_localizations.dart';

import '../../../../core/router/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/app_widgets.dart';
import '../../../challenge/data/challenge_repository.dart';
import '../../../challenge/domain/entities/challenge.dart';
import '../../../community/presentation/widgets/challenge_card.dart';
import '../../../leaderboard/data/leaderboard_providers.dart';

/// A creator's public page: identity, headline stats and a grid of every
/// public drawing they've published.
class CreatorProfileScreen extends ConsumerWidget {
  const CreatorProfileScreen({required this.creatorId, super.key});
  final String creatorId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final user = ref.watch(userByIdProvider(creatorId));
    final drawings = ref.watch(challengesByAuthorProvider(creatorId));

    return Scaffold(
      appBar: AppBar(title: Text(l.creatorProfile)),
      body: user.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => StateMessage(
          icon: Icons.error_outline,
          title: l.creatorProfile,
          subtitle: '$e',
        ),
        data: (profile) {
          final name = profile?.displayName ?? 'Player';
          final avatar = profile?.avatarUrl;
          return ListView(
            padding: const EdgeInsets.only(bottom: 24),
            children: [
              const SizedBox(height: 16),
              Center(
                child: CircleAvatar(
                  radius: 44,
                  backgroundColor: AppColors.ink.withValues(alpha: 0.18),
                  backgroundImage: avatar != null
                      ? CachedNetworkImageProvider(avatar)
                      : null,
                  child: avatar == null
                      ? Text(
                          name.characters.first.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            color: AppColors.ink,
                          ),
                        )
                      : null,
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: Text(
                  name,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Center(
                child: Text(
                  l.level(profile?.level ?? 1),
                  style: const TextStyle(color: AppColors.textMuted),
                ),
              ),
              const SizedBox(height: 20),
              drawings.maybeWhen(
                data: (list) => _StatsRow(drawings: list, l: l),
                orElse: () => const SizedBox.shrink(),
              ),
              const Divider(height: 32),
              drawings.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => StateMessage(
                  icon: Icons.error_outline,
                  title: l.creatorProfile,
                  subtitle: '$e',
                ),
                data: (list) {
                  final public = list.where((c) => c.isPublic).toList();
                  if (public.isEmpty) {
                    return StateMessage(
                      icon: Icons.brush_outlined,
                      title: l.noChallengesYet,
                    );
                  }
                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.7,
                    ),
                    itemCount: public.length,
                    itemBuilder: (_, i) => _DrawingTile(challenge: public[i]),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.drawings, required this.l});
  final List<Challenge> drawings;
  final AppLocalizations l;

  @override
  Widget build(BuildContext context) {
    final public = drawings.where((c) => c.isPublic).toList();
    final rated = public.where((c) => c.hasRating).toList();
    final avg = rated.isEmpty
        ? 0.0
        : rated.map((c) => c.ratingStars).reduce((a, b) => a + b) /
            rated.length;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _Stat(value: '${public.length}', label: l.created),
        _Stat(value: avg.toStringAsFixed(1), label: l.avgRating),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label});
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w900,
            color: AppColors.ink,
          ),
        ),
        Text(label, style: const TextStyle(color: AppColors.textMuted)),
      ],
    );
  }
}

class _DrawingTile extends StatelessWidget {
  const _DrawingTile({required this.challenge});
  final Challenge challenge;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push(Routes.playPath(challenge.id)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Stack(
          fit: StackFit.expand,
          children: [
            CachedNetworkImage(
              imageUrl: challenge.camouflagedImageUrl,
              fit: BoxFit.cover,
              placeholder: (_, __) => const ColoredBox(color: Colors.black12),
              errorWidget: (_, __, ___) =>
                  const Icon(Icons.broken_image_outlined),
            ),
            if (challenge.hasRating)
              Positioned(
                left: 8,
                top: 8,
                child: RatingBadge(stars: challenge.ratingStars),
              ),
          ],
        ),
      ),
    );
  }
}
