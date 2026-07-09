import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:inkognito/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../challenge/domain/entities/challenge.dart';

/// Feed card previewing a challenge with author, stats and a play action.
class ChallengeCard extends StatelessWidget {
  const ChallengeCard({required this.challenge, super.key});
  final Challenge challenge;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: () => context.push(Routes.challengePath(challenge.id)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _AuthorRow(challenge: challenge),
            AspectRatio(
              aspectRatio: challenge.canvasAspectRatio.clamp(0.6, 1.9),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CachedNetworkImage(
                    imageUrl: challenge.camouflagedImageUrl,
                    fit: BoxFit.cover,
                    placeholder: (_, __) =>
                        const ColoredBox(color: Colors.black12),
                    errorWidget: (_, __, ___) =>
                        const Icon(Icons.broken_image_outlined),
                  ),
                  Positioned(
                    right: 10,
                    top: 10,
                    child: _DifficultyBadge(level: challenge.difficulty),
                  ),
                  if (challenge.hasRating)
                    Positioned(
                      left: 10,
                      top: 10,
                      child: RatingBadge(stars: challenge.ratingStars),
                    ),
                  Positioned(
                    right: 12,
                    bottom: 12,
                    child: FloatingActionButton.small(
                      heroTag: 'play-${challenge.id}',
                      backgroundColor: AppColors.splash,
                      onPressed: () =>
                          context.push(Routes.playPath(challenge.id)),
                      child: const Icon(Icons.play_arrow, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      challenge.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  _Stat(icon: Icons.favorite, value: challenge.likeCount),
                  const SizedBox(width: 12),
                  _Stat(
                    icon: Icons.mode_comment_outlined,
                    value: challenge.commentCount,
                  ),
                  const SizedBox(width: 12),
                  _Stat(
                    icon: Icons.play_circle_outline,
                    value: challenge.playCount,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AuthorRow extends StatelessWidget {
  const _AuthorRow({required this.challenge});
  final Challenge challenge;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => context.push(Routes.creatorPath(challenge.authorId)),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: AppColors.ink.withValues(alpha: 0.2),
                  backgroundImage: challenge.authorAvatarUrl != null
                      ? CachedNetworkImageProvider(challenge.authorAvatarUrl!)
                      : null,
                  child: challenge.authorAvatarUrl == null
                      ? Text(
                          challenge.authorName.characters.first.toUpperCase(),
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppColors.ink,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 10),
                Text(
                  challenge.authorName,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
          const Spacer(),
          Text(
            AppLocalizations.of(context).hidden(challenge.inklingCount),
            style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.icon, required this.value});
  final IconData icon;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.textMuted),
        const SizedBox(width: 4),
        Text('$value', style: const TextStyle(color: AppColors.textMuted)),
      ],
    );
  }
}

/// The drawing's note out of 5 — how well it fools seekers.
class RatingBadge extends StatelessWidget {
  const RatingBadge({required this.stars, super.key});
  final double stars;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star_rounded, size: 14, color: AppColors.glow),
          const SizedBox(width: 3),
          Text(
            stars.toStringAsFixed(1),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _DifficultyBadge extends StatelessWidget {
  const _DifficultyBadge({required this.level});
  final int level;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(
          5,
          (i) => Icon(
            Icons.circle,
            size: 7,
            color: i < level ? AppColors.glow : Colors.white24,
          ),
        ),
      ),
    );
  }
}
