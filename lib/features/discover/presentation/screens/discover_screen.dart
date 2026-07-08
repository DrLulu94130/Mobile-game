import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:inkognito/l10n/app_localizations.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/app_widgets.dart';
import '../../../auth/data/auth_repository.dart';
import '../../../challenge/data/challenge_repository.dart';
import '../../../challenge/domain/entities/challenge.dart';
import '../../../economy/data/token_service.dart';
import '../../../play/domain/detection_engine.dart';
import '../../../play/presentation/widgets/found_markers.dart';
import '../../../progression/data/progression_service.dart';

/// Discover: a vertical, TikTok-style feed of everyone's drawings. Each
/// drawing gives the seeker [AppConstants.discoverRoundSeconds] seconds to
/// find every Inkling. Every drawing scrolled earns tokens; wins earn a
/// bonus. Outcomes feed the drawing's note (share of seekers fooled).
class DiscoverScreen extends ConsumerStatefulWidget {
  const DiscoverScreen({super.key});

  @override
  ConsumerState<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends ConsumerState<DiscoverScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  /// Challenges already credited with a scroll token this session, so
  /// swiping back and forth cannot farm tokens.
  final Set<String> _scrollRewarded = {};

  /// Outcomes of resolved rounds (challenge id → found all in time).
  final Map<String, bool> _outcomes = {};

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  String? get _uid => ref.read(authRepositoryProvider).currentUser?.uid;

  /// Every new drawing reached in the scroll pays one token (once per
  /// challenge per session) and counts as a play.
  void _onArrivedAt(Challenge challenge) {
    if (!_scrollRewarded.add(challenge.id)) return;
    final uid = _uid;
    if (uid != null) {
      unawaited(
        ref
            .read(tokenServiceProvider)
            .earn(uid, AppConstants.tokensPerDiscoverScroll),
      );
    }
    unawaited(
      ref.read(challengeRepositoryProvider).incrementPlayCount(challenge.id),
    );
  }

  /// A round ended: persist the outcome on the drawing's note and pay the
  /// seeker when they beat the clock.
  void _onResolved(Challenge challenge, bool foundAll, int foundCount) {
    if (_outcomes.containsKey(challenge.id)) return;
    setState(() => _outcomes[challenge.id] = foundAll);

    unawaited(
      ref
          .read(challengeRepositoryProvider)
          .recordSeekResult(challenge.id, foundAll: foundAll),
    );

    final uid = _uid;
    if (uid == null || !foundAll) return;
    unawaited(
      ref
          .read(tokenServiceProvider)
          .earn(uid, AppConstants.tokensPerDiscoverWin),
    );
    unawaited(
      ref.read(progressionServiceProvider).awardXp(
            uid: uid,
            xpDelta: AppConstants.xpPerChallengeSolved +
                foundCount * AppConstants.xpPerInklingFound,
            challengesSolvedDelta: 1,
            perfectSolvesDelta: 1,
          ),
    );
  }

  void _goNext(int total) {
    if (_currentPage >= total - 1) return;
    _pageController.nextPage(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final uid = ref.watch(currentUserProvider).valueOrNull?.uid;
    final feed = ref.watch(discoverChallengesProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      body: feed.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => StateMessage(
          icon: Icons.wifi_off,
          title: l.feedEmptyTitle,
          subtitle: '$e',
        ),
        data: (all) {
          // Never serve players their own drawings — they know the answer.
          final challenges = all
              .where((c) => c.authorId != uid && c.inklings.isNotEmpty)
              .toList();
          if (challenges.isEmpty) {
            return SafeArea(
              child: Stack(
                children: [
                  StateMessage(
                    icon: Icons.explore_off_outlined,
                    title: l.discoverEmpty,
                    subtitle: l.feedEmptyBody,
                    action: FilledButton.icon(
                      onPressed: () => context.push(Routes.create),
                      icon: const Icon(Icons.add),
                      label: Text(l.createOne),
                    ),
                  ),
                  _CloseButton(onTap: () => context.pop()),
                ],
              ),
            );
          }
          // The first drawing shown also counts as a scroll.
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && _currentPage < challenges.length) {
              _onArrivedAt(challenges[_currentPage]);
            }
          });
          return SafeArea(
            child: Stack(
              children: [
                PageView.builder(
                  controller: _pageController,
                  scrollDirection: Axis.vertical,
                  itemCount: challenges.length,
                  onPageChanged: (i) {
                    setState(() => _currentPage = i);
                    _onArrivedAt(challenges[i]);
                  },
                  itemBuilder: (_, i) {
                    final challenge = challenges[i];
                    return _DiscoverRound(
                      key: ValueKey(challenge.id),
                      challenge: challenge,
                      active: i == _currentPage,
                      previousOutcome: _outcomes[challenge.id],
                      onResolved: (foundAll, foundCount) =>
                          _onResolved(challenge, foundAll, foundCount),
                      onNext: () => _goNext(challenges.length),
                    );
                  },
                ),
                _CloseButton(onTap: () => context.pop()),
                Positioned(
                  top: 8,
                  right: 12,
                  child: _TokenChip(),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _CloseButton extends StatelessWidget {
  const _CloseButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 8,
      left: 12,
      child: IconButton.filledTonal(
        onPressed: onTap,
        icon: const Icon(Icons.close),
      ),
    );
  }
}

/// Live token balance, streamed from the profile document.
class _TokenChip extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = ref.watch(currentUserProvider).valueOrNull?.tokens ?? 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.toll_rounded, color: AppColors.glow, size: 18),
          const SizedBox(width: 6),
          Text(
            '$tokens',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

/// One drawing in the Discover feed: a timed find-them-all round.
class _DiscoverRound extends StatefulWidget {
  const _DiscoverRound({
    required this.challenge,
    required this.active,
    required this.previousOutcome,
    required this.onResolved,
    required this.onNext,
    super.key,
  });

  final Challenge challenge;

  /// Whether this page is the one currently on screen — the clock only runs
  /// on the visible round.
  final bool active;

  /// Non-null when this round was already resolved earlier in the session
  /// (the page was rebuilt after scrolling away and back).
  final bool? previousOutcome;

  final void Function(bool foundAll, int foundCount) onResolved;
  final VoidCallback onNext;

  @override
  State<_DiscoverRound> createState() => _DiscoverRoundState();
}

class _DiscoverRoundState extends State<_DiscoverRound> {
  late final PlaySession _session =
      PlaySession(inklings: widget.challenge.inklings);
  Timer? _ticker;
  double _remaining = AppConstants.discoverRoundSeconds.toDouble();
  Offset? _lastMiss;
  bool? _outcome;

  bool get _resolved => _outcome != null;

  @override
  void initState() {
    super.initState();
    _outcome = widget.previousOutcome;
    if (widget.previousOutcome != null) _remaining = 0;
    if (widget.active) _startClock();
  }

  @override
  void didUpdateWidget(covariant _DiscoverRound oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !oldWidget.active) _startClock();
    if (!widget.active && oldWidget.active && !_resolved) {
      // Scrolled away mid-round: the round pauses; the clock restarts from
      // where it stopped if the player comes back.
      _ticker?.cancel();
      _ticker = null;
    }
  }

  void _startClock() {
    if (_resolved || _ticker != null) return;
    _session.start();
    _ticker = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (!mounted) return;
      setState(() => _remaining = (_remaining - 0.1).clamp(0.0, 60.0));
      if (_remaining <= 0) _resolve(false);
    });
  }

  void _resolve(bool foundAll) {
    if (_resolved) return;
    _ticker?.cancel();
    _ticker = null;
    setState(() {
      _outcome = foundAll;
      if (!foundAll) _remaining = 0;
    });
    widget.onResolved(foundAll, _session.foundCount);
  }

  void _onTap(Offset normalised) {
    if (_resolved || !widget.active) return;
    _startClock();
    final result = _session.tap(normalised);
    setState(() => _lastMiss = result.hit ? null : normalised);
    if (_session.isComplete) _resolve(true);
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final challenge = widget.challenge;
    final progress =
        (_remaining / AppConstants.discoverRoundSeconds).clamp(0.0, 1.0);
    final urgent = !_resolved && _remaining <= 3;

    return Stack(
      children: [
        Center(
          child: AspectRatio(
            aspectRatio: challenge.canvasAspectRatio,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final size = Size(constraints.maxWidth, constraints.maxHeight);
                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTapUp: (d) => _onTap(
                    Offset(
                      d.localPosition.dx / size.width,
                      d.localPosition.dy / size.height,
                    ),
                  ),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CachedNetworkImage(
                        imageUrl: challenge.camouflagedImageUrl,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => const ColoredBox(
                          color: Colors.black26,
                          child: Center(child: CircularProgressIndicator()),
                        ),
                      ),
                      CustomPaint(
                        painter: FoundMarkersPainter(
                          inklings: challenge.inklings,
                          foundIds: _session.found,
                          lastMiss: _lastMiss,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),

        // Round HUD: countdown + progress, under the top chips.
        Positioned(
          top: 64,
          left: 16,
          right: 16,
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _HudPill(
                    icon: Icons.search,
                    text: '${_session.foundCount}/${challenge.inklingCount}',
                  ),
                  _HudPill(
                    icon: Icons.timer_outlined,
                    text: _remaining.ceil().toString(),
                    color: urgent ? AppColors.coral : AppColors.splash,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 6,
                  backgroundColor: Colors.white24,
                  valueColor: AlwaysStoppedAnimation(
                    urgent ? AppColors.coral : AppColors.splash,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Author + title, pinned at the bottom like a social feed.
        Positioned(
          bottom: 24,
          left: 16,
          right: 16,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                challenge.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                challenge.authorName,
                style: const TextStyle(color: Colors.white70),
              ),
            ],
          ),
        ),

        if (_resolved)
          _RoundResult(
            won: _outcome!,
            challenge: challenge,
            l: l,
            onNext: widget.onNext,
          ),
      ],
    );
  }
}

/// End-of-round overlay: celebrates a win (with the token bonus) or shows
/// the reveal when the drawing fooled the seeker, then invites the swipe.
class _RoundResult extends StatelessWidget {
  const _RoundResult({
    required this.won,
    required this.challenge,
    required this.l,
    required this.onNext,
  });

  final bool won;
  final Challenge challenge;
  final AppLocalizations l;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    // The drawing's fresh note including this round.
    final stars = Challenge.computeRatingScore(
          challenge.seekWinCount + (won ? 1 : 0),
          challenge.seekFailCount + (won ? 0 : 1),
        ) /
        20.0;

    return Container(
      color: Colors.black.withValues(alpha: 0.82),
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                won ? l.discoverFoundAll : l.discoverTimeUp,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                ),
              ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack),
              const SizedBox(height: 8),
              if (won)
                Text(
                  l.tokensEarned(AppConstants.tokensPerDiscoverWin),
                  style: const TextStyle(
                    color: AppColors.glow,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                )
              else
                Text(
                  l.discoverDrawingWins,
                  style: const TextStyle(color: Colors.white70),
                ),
              const SizedBox(height: 12),
              Text(
                l.drawingRating(stars.toStringAsFixed(1)),
                style: const TextStyle(color: Colors.white70),
              ),
              if (!won) ...[
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: CachedNetworkImage(
                    imageUrl: challenge.revealedImageUrl,
                    height: 220,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => const SizedBox(
                      height: 220,
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: onNext,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.splash,
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(Icons.arrow_upward_rounded),
                label: Text(l.nextDrawing),
              ),
              const SizedBox(height: 8),
              Text(
                l.discoverSwipeNext,
                style: const TextStyle(color: Colors.white54, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HudPill extends StatelessWidget {
  const _HudPill({
    required this.icon,
    required this.text,
    this.color = AppColors.splash,
  });

  final IconData icon;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
