import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:inkognito/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/router/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/app_widgets.dart';
import '../../../auth/data/auth_repository.dart';
import '../../../community/data/community_repository.dart';
import '../../../community/domain/entities/comment.dart';
import '../../data/challenge_repository.dart';
import '../../domain/entities/challenge.dart';

/// Challenge detail: preview, play CTA, likes and a comment thread.
class ChallengeDetailScreen extends ConsumerWidget {
  const ChallengeDetailScreen({required this.challengeId, super.key});
  final String challengeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(challengeByIdProvider(challengeId));
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context).newChallenge)),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => StateMessage(
          icon: Icons.error_outline,
          title: AppLocalizations.of(context).challengeNotFound,
        ),
        data: (challenge) => _DetailView(challenge: challenge),
      ),
    );
  }
}

class _DetailView extends ConsumerWidget {
  const _DetailView({required this.challenge});
  final Challenge challenge;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final uid = ref.watch(authRepositoryProvider).currentUser?.uid;
    final comments = ref.watch(commentsProvider(challenge.id));

    return Column(
      children: [
        Expanded(
          child: ListView(
            children: [
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(20),
                    ),
                    child: CachedNetworkImage(
                      imageUrl: challenge.camouflagedImageUrl,
                      fit: BoxFit.cover,
                      height: 300,
                      width: double.infinity,
                    ),
                  ),
                  Positioned(
                    bottom: 12,
                    right: 12,
                    child: FloatingActionButton.extended(
                      heroTag: 'play-detail',
                      backgroundColor: AppColors.splash,
                      onPressed: () =>
                          context.push(Routes.playPath(challenge.id)),
                      icon: const Icon(Icons.play_arrow, color: Colors.white),
                      label: Text(
                        l.play,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      challenge.title,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${challenge.authorName} · '
                      '${l.hidden(challenge.inklingCount)} · '
                      '${_best(challenge.bestTimeMs)}',
                      style: const TextStyle(color: AppColors.textMuted),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        if (uid != null)
                          _LikeButton(challengeId: challenge.id, uid: uid),
                        const SizedBox(width: 16),
                        const Icon(
                          Icons.mode_comment_outlined,
                          size: 20,
                          color: AppColors.textMuted,
                        ),
                        const SizedBox(width: 4),
                        Text('${challenge.commentCount}'),
                        const Spacer(),
                        Text(
                          l.plays(challenge.playCount),
                          style: const TextStyle(color: AppColors.textMuted),
                        ),
                      ],
                    ),
                    const Divider(height: 32),
                    Text(
                      l.comments,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    comments.when(
                      loading: () => const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: CircularProgressIndicator(),
                        ),
                      ),
                      error: (e, _) => Text('$e'),
                      data: (list) => list.isEmpty
                          ? Padding(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              child: Text(l.beFirstComment),
                            )
                          : Column(
                              children: [
                                for (final c in list) _CommentTile(comment: c),
                              ],
                            ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (uid != null) _CommentComposer(challenge: challenge, uid: uid),
      ],
    );
  }

  String _best(int? ms) =>
      ms == null ? '—' : '${(ms / 1000).toStringAsFixed(1)}s';
}

class _LikeButton extends ConsumerWidget {
  const _LikeButton({required this.challengeId, required this.uid});
  final String challengeId;
  final String uid;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final liked = ref
            .watch(likedProvider((challengeId: challengeId, uid: uid)))
            .valueOrNull ??
        false;
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () =>
          ref.read(communityRepositoryProvider).toggleLike(challengeId, uid),
      child: Row(
        children: [
          Icon(
            liked ? Icons.favorite : Icons.favorite_border,
            color: liked ? AppColors.coral : AppColors.textMuted,
          ),
          const SizedBox(width: 4),
          Text(AppLocalizations.of(context).like),
        ],
      ),
    );
  }
}

class _CommentTile extends StatelessWidget {
  const _CommentTile({required this.comment});
  final Comment comment;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: AppColors.ink.withValues(alpha: 0.2),
        child: Text(
          comment.authorName.characters.first.toUpperCase(),
          style: const TextStyle(color: AppColors.ink),
        ),
      ),
      title: Text(
        comment.authorName,
        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
      ),
      subtitle: Text(comment.text),
      trailing: Text(
        DateFormat.Md().add_jm().format(comment.createdAt),
        style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
      ),
    );
  }
}

class _CommentComposer extends ConsumerStatefulWidget {
  const _CommentComposer({required this.challenge, required this.uid});
  final Challenge challenge;
  final String uid;

  @override
  ConsumerState<_CommentComposer> createState() => _CommentComposerState();
}

class _CommentComposerState extends ConsumerState<_CommentComposer> {
  final _controller = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    final profile = await ref.read(currentUserProvider.future);
    final comment = Comment(
      id: '',
      challengeId: widget.challenge.id,
      authorId: widget.uid,
      authorName: profile?.displayName ?? 'Player',
      authorAvatarUrl: profile?.avatarUrl,
      text: text,
      createdAt: DateTime.now(),
    );
    await ref.read(communityRepositoryProvider).addComment(comment);
    _controller.clear();
    if (mounted) setState(() => _sending = false);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(
          left: 12,
          right: 12,
          bottom: MediaQuery.of(context).viewInsets.bottom + 8,
          top: 8,
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _send(),
                decoration: InputDecoration(
                  hintText: AppLocalizations.of(context).addComment,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                ),
              ),
            ),
            IconButton(
              onPressed: _sending ? null : _send,
              icon: const Icon(Icons.send, color: AppColors.ink),
            ),
          ],
        ),
      ),
    );
  }
}
