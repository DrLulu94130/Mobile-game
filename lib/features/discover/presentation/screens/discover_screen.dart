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
import '../../../community/data/community_repository.dart';
import '../../../economy/data/token_service.dart';
import '../../../play/domain/detection_engine.dart';
import '../../../play/presentation/widgets/found_markers.dart';
import '../../../progression/data/progression_service.dart';
import '../../domain/discover_feed.dart';

/// Discover: a vertical, TikTok-style feed of everyone's drawings.
///
/// Each drawing gives the seeker a few seconds (scaled by Inkling count, plus a
/// Premium bonus) to find every creature. Scrolling earns capped daily tokens;
/// winning earns an uncapped, combo-scaled bonus. Outcomes feed each drawing's
/// note. The featured daily drawing leads the feed and pays double.
class DiscoverScreen extends ConsumerStatefulWidget {
  const DiscoverScreen({super.key});

  @override
  ConsumerState<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends ConsumerState<DiscoverScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  /// A stable seed so the weighted shuffle stays consistent while the feed
  /// stream re-emits during a session.
  final int _seed = DateTime.now().millisecondsSinceEpoch & 0x7fffffff;

  /// Challenges already credited with a scroll token this session, so
  /// swiping back and forth cannot farm tokens.
  final Set<String> _scrollRewarded = {};

  /// Outcomes of resolved rounds (challenge id → found all in time).
  final Map<String, bool> _outcomes = {};

  /// Consecutive wins — drives the token combo multiplier.
  int _winStreak = 0;

  /// Ephemeral "+N 🪙" celebrations floating above the round.
  int _floatKey = 0;
  int? _floatAmount;

  bool _tutorialDismissed = false;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  String? get _uid => ref.read(authRepositoryProvider).currentUser?.uid;

  void _showFloat(int amount) {
    setState(() {
      _floatAmount = amount;
      _floatKey++;
    });
  }

  /// Every new drawing reached in the scroll pays one capped token and counts
  /// as a play. Also preloads the next image so the swipe feels instant.
  void _onArrivedAt(List<Challenge> feed, int index) {
    final challenge = feed[index];
    if (index + 1 < feed.length) {
      precacheImage(
        CachedNetworkImageProvider(feed[index + 1].camouflagedImageUrl),
        context,
      );
    }
    if (!_scrollRewarded.add(challenge.id)) return;
    final uid = _uid;
    if (uid != null) {
      unawaited(_creditScroll(uid));
    }
    unawaited(
      ref.read(challengeRepositoryProvider).incrementPlayCount(challenge.id),
    );
  }

  Future<void> _creditScroll(String uid) async {
    final credited = await ref.read(tokenServiceProvider).earnScrollToken(uid);
    if (credited > 0 && mounted) _showFloat(credited);
  }

  /// A round ended: persist the outcome and, on a win, pay the combo-scaled
  /// (and daily-doubled) bonus plus XP.
  void _onResolved(
    Challenge challenge,
    bool foundAll,
    int foundCount, {
    required bool isDaily,
  }) {
    if (_outcomes.containsKey(challenge.id)) return;
    setState(() {
      _outcomes[challenge.id] = foundAll;
      _winStreak = foundAll ? _winStreak + 1 : 0;
    });

    unawaited(
      ref
          .read(challengeRepositoryProvider)
          .recordSeekResult(challenge.id, foundAll: foundAll),
    );

    final uid = _uid;
    if (uid == null || !foundAll) return;

    var bonus = AppConstants.discoverWinBonus(_winStreak);
    if (isDaily) bonus *= AppConstants.dailyChallengeBonusMultiplier;

    unawaited(ref.read(tokenServiceProvider).earn(uid, bonus));
    _showFloat(bonus);
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

  Future<void> _dismissTutorial(String? uid) async {
    setState(() => _tutorialDismissed = true);
    if (uid != null) {
      await ref.read(authRepositoryProvider).markDiscoverTutorialSeen(uid);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final profile = ref.watch(currentUserProvider).valueOrNull;
    final uid = profile?.uid;
    final premium = profile?.isPremium ?? false;
    final feedAsync = ref.watch(discoverChallengesProvider);
    final dailyId =
        ref.watch(dailyChallengesProvider).valueOrNull?.firstOrNull?.id;

    return Scaffold(
      backgroundColor: Colors.black,
      body: feedAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => StateMessage(
          icon: Icons.wifi_off,
          title: l.feedEmptyTitle,
          subtitle: '$e',
        ),
        data: (all) {
          final challenges = DiscoverFeed.order(
            all,
            viewerId: uid,
            dailyId: dailyId,
            seed: _seed,
          );
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

          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && _currentPage < challenges.length) {
              _onArrivedAt(challenges, _currentPage);
            }
          });

          final showTutorial = profile != null &&
              !profile.discoverTutorialSeen &&
              !_tutorialDismissed;

          return SafeArea(
            child: Stack(
              children: [
                PageView.builder(
                  controller: _pageController,
                  scrollDirection: Axis.vertical,
                  itemCount: challenges.length,
                  onPageChanged: (i) {
                    setState(() => _currentPage = i);
                    _onArrivedAt(challenges, i);
                  },
                  itemBuilder: (_, i) {
                    final challenge = challenges[i];
                    final isDaily = challenge.id == dailyId;
                    return _DiscoverRound(
                      key: ValueKey(challenge.id),
                      challenge: challenge,
                      active: i == _currentPage,
                      isDaily: isDaily,
                      premium: premium,
                      seconds: AppConstants.discoverSecondsFor(
                        challenge.inklingCount,
                        premium: premium,
                      ),
                      previousOutcome: _outcomes[challenge.id],
                      onResolved: (foundAll, foundCount) => _onResolved(
                        challenge,
                        foundAll,
                        foundCount,
                        isDaily: isDaily,
                      ),
                      onNext: () => _goNext(challenges.length),
                    );
                  },
                ),
                _CloseButton(onTap: () => context.pop()),
                Positioned(
                  top: 8,
                  right: 12,
                  child: Row(
                    children: [
                      if (_winStreak >= 2) ...[
                        _ComboChip(streak: _winStreak),
                        const SizedBox(width: 8),
                      ],
                      const _TokenChip(),
                    ],
                  ),
                ),
                if (_floatAmount != null)
                  _TokenFloat(
                    key: ValueKey(_floatKey),
                    amount: _floatAmount!,
                  ),
                if (showTutorial)
                  _TutorialOverlay(onDismiss: () => _dismissTutorial(uid)),
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
  const _TokenChip();

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

/// Current win-streak indicator.
class _ComboChip extends StatelessWidget {
  const _ComboChip({required this.streak});
  final int streak;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.coral,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        AppLocalizations.of(context).discoverComboLabel(streak),
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
        ),
      ),
    ).animate(key: ValueKey(streak)).scale(
          begin: const Offset(1.3, 1.3),
          end: const Offset(1, 1),
          duration: 250.ms,
          curve: Curves.easeOutBack,
        );
  }
}

/// A "+N 🪙" burst that floats up and fades.
class _TokenFloat extends StatelessWidget {
  const _TokenFloat({required this.amount, super.key});
  final int amount;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Align(
        alignment: const Alignment(0, -0.35),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.toll_rounded, color: AppColors.glow, size: 22),
              const SizedBox(width: 6),
              Text(
                '+$amount',
                style: const TextStyle(
                  color: AppColors.glow,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        )
            .animate()
            .fadeIn(duration: 150.ms)
            .then()
            .moveY(begin: 0, end: -60, duration: 900.ms, curve: Curves.easeOut)
            .fadeOut(delay: 500.ms, duration: 400.ms),
      ),
    );
  }
}

/// One-time how-to overlay shown on the first Discover visit.
class _TutorialOverlay extends StatelessWidget {
  const _TutorialOverlay({required this.onDismiss});
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Positioned.fill(
      child: ColoredBox(
        color: Colors.black.withValues(alpha: 0.82),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.touch_app_rounded,
                color: AppColors.splash,
                size: 56,
              ),
              const SizedBox(height: 20),
              Text(
                l.discoverTutorialTitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                l.discoverTutorialBody,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, height: 1.4),
              ),
              const SizedBox(height: 28),
              FilledButton(
                onPressed: onDismiss,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.splash,
                  foregroundColor: Colors.white,
                ),
                child: Text(l.discoverTutorialCta),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// One drawing in the Discover feed: a timed find-them-all round. The clock
/// only starts once the image has actually rendered, so slow loads never eat
/// into the seeker's time.
class _DiscoverRound extends StatefulWidget {
  const _DiscoverRound({
    required this.challenge,
    required this.active,
    required this.isDaily,
    required this.premium,
    required this.seconds,
    required this.previousOutcome,
    required this.onResolved,
    required this.onNext,
    super.key,
  });

  final Challenge challenge;
  final bool active;
  final bool isDaily;
  final bool premium;
  final int seconds;
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
  late double _remaining = widget.seconds.toDouble();
  Offset? _lastMiss;
  bool? _outcome;
  bool _imageReady = false;

  bool get _resolved => _outcome != null;

  @override
  void initState() {
    super.initState();
    _outcome = widget.previousOutcome;
    if (widget.previousOutcome != null) _remaining = 0;
  }

  @override
  void didUpdateWidget(covariant _DiscoverRound oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !oldWidget.active) _maybeStartClock();
    if (!widget.active && oldWidget.active && !_resolved) {
      _ticker?.cancel();
      _ticker = null;
    }
  }

  /// Starts the clock only when the round is on-screen *and* the image has
  /// painted at least one frame.
  void _maybeStartClock() {
    if (_resolved || _ticker != null || !_imageReady || !widget.active) return;
    _session.start();
    _ticker = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (!mounted) return;
      setState(() => _remaining = (_remaining - 0.1).clamp(0.0, 90.0));
      if (_remaining <= 0) _resolve(false);
    });
  }

  void _onImageReady() {
    if (_imageReady) return;
    _imageReady = true;
    _maybeStartClock();
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
    final progress = (_remaining / widget.seconds).clamp(0.0, 1.0);
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
                        imageBuilder: (context, provider) {
                          WidgetsBinding.instance.addPostFrameCallback(
                            (_) => _onImageReady(),
                          );
                          return Image(image: provider, fit: BoxFit.cover);
                        },
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
              if (widget.isDaily)
                Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.glow,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    l.discoverDailyBadge,
                    style: const TextStyle(
                      color: Colors.black87,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                ),
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
              GestureDetector(
                onTap: () =>
                    context.push(Routes.creatorPath(challenge.authorId)),
                child: Text(
                  challenge.authorName,
                  style: const TextStyle(
                    color: Colors.white70,
                    decoration: TextDecoration.underline,
                    decorationColor: Colors.white38,
                  ),
                ),
              ),
            ],
          ),
        ),

        if (_resolved)
          _RoundResult(
            won: _outcome!,
            challenge: challenge,
            onNext: widget.onNext,
          ),
      ],
    );
  }
}

/// End-of-round overlay: celebrates a win or shows the reveal on a loss, plus
/// like / report actions and the invitation to swipe on.
class _RoundResult extends ConsumerWidget {
  const _RoundResult({
    required this.won,
    required this.challenge,
    required this.onNext,
  });

  final bool won;
  final Challenge challenge;
  final VoidCallback onNext;

  Future<void> _like(WidgetRef ref) async {
    final uid = ref.read(authRepositoryProvider).currentUser?.uid;
    if (uid == null) return;
    await ref.read(communityRepositoryProvider).toggleLike(challenge.id, uid);
  }

  Future<void> _report(BuildContext context, WidgetRef ref) async {
    final l = AppLocalizations.of(context);
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l.reportTitle,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
            ),
            const SizedBox(height: 6),
            Text(l.reportBody),
            const SizedBox(height: 12),
            for (final reason in [
              l.reportReasonInappropriate,
              l.reportReasonImpossible,
              l.reportReasonSpam,
            ])
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.flag_outlined),
                title: Text(reason),
                onTap: () => Navigator.pop(sheetContext, true),
              ),
          ],
        ),
      ),
    );
    if (confirmed != true) return;
    await ref.read(challengeRepositoryProvider).report(challenge.id);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.reportSubmitted)),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
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
              if (!won)
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
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _RoundAction(
                    icon: Icons.favorite_border,
                    label: l.likeDrawing,
                    onTap: () => _like(ref),
                  ),
                  const SizedBox(width: 24),
                  _RoundAction(
                    icon: Icons.flag_outlined,
                    label: l.reportDrawing,
                    onTap: () => _report(context, ref),
                  ),
                ],
              ),
              const SizedBox(height: 20),
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

class _RoundAction extends StatelessWidget {
  const _RoundAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: onTap,
      style: TextButton.styleFrom(foregroundColor: Colors.white),
      icon: Icon(icon, size: 20),
      label: Text(label),
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
