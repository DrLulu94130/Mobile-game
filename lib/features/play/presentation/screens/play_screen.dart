import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:inkognito/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/data/auth_repository.dart';
import '../../../challenge/data/challenge_repository.dart';
import '../../../challenge/domain/entities/challenge.dart';
import '../../../progression/data/progression_service.dart';
import '../../../../shared/widgets/app_widgets.dart';
import '../../data/attempt_repository.dart';
import '../../domain/detection_engine.dart';
import '../../domain/entities/attempt.dart';
import '../widgets/found_markers.dart';
import '../widgets/result_overlay.dart';

/// Loads a challenge and hosts the interactive "find the Inklings" session.
class PlayScreen extends ConsumerWidget {
  const PlayScreen({required this.challengeId, super.key});
  final String challengeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(challengeByIdProvider(challengeId));
    return Scaffold(
      backgroundColor: Colors.black,
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => StateMessage(
          icon: Icons.error_outline,
          title: AppLocalizations.of(context).challengeNotFound,
          action: FilledButton(
            onPressed: () => context.pop(),
            child: Text(AppLocalizations.of(context).goBack),
          ),
        ),
        data: (challenge) => _PlayView(challenge: challenge),
      ),
    );
  }
}

class _PlayView extends ConsumerStatefulWidget {
  const _PlayView({required this.challenge});
  final Challenge challenge;

  @override
  ConsumerState<_PlayView> createState() => _PlayViewState();
}

class _PlayViewState extends ConsumerState<_PlayView> {
  late PlaySession _session;
  Timer? _ticker;
  Offset? _lastMiss;
  bool _finished = false;

  /// Rewards are granted once per screen visit: replaying after seeing the
  /// solution must not farm XP, attempts or best times.
  bool _rewarded = false;

  @override
  void initState() {
    super.initState();
    _session = PlaySession(inklings: widget.challenge.inklings);
    ref
        .read(challengeRepositoryProvider)
        .incrementPlayCount(widget.challenge.id);
    _startTicker();
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && !_finished) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  void _onTap(Offset normalised) {
    if (_finished) return;
    final result = _session.tap(normalised);
    setState(() {
      _lastMiss = result.hit ? null : normalised;
    });
    if (result.hit) {
      HapticFeedbackSafe.light();
    }
    if (_session.isComplete) {
      _finish();
    }
  }

  Future<void> _finish() async {
    if (_finished) return;
    _finished = true;
    _ticker?.cancel();

    final score = _session.computeScore();
    final user = ref.read(authRepositoryProvider).currentUser;

    if (user != null && !_rewarded) {
      _rewarded = true;
      final attempt = Attempt(
        id: '',
        challengeId: widget.challenge.id,
        playerId: user.uid,
        foundCount: _session.foundCount,
        totalInklings: _session.total,
        durationMs: _session.elapsed.inMilliseconds,
        score: score,
        taps: _session.taps,
        createdAt: DateTime.now(),
      );
      await ref.read(attemptRepositoryProvider).save(attempt);
      // A best time only makes sense for a completed round — giving up
      // must not claim the record.
      if (_session.isComplete) {
        await ref.read(challengeRepositoryProvider).recordBestTime(
              widget.challenge.id,
              _session.elapsed.inMilliseconds,
            );
      }
      // Award XP for solving; giving up without finding all of them only
      // pays for the Inklings actually found.
      final xp = (_session.isComplete ? AppConstants.xpPerChallengeSolved : 0) +
          _session.foundCount * AppConstants.xpPerInklingFound;
      if (xp > 0) {
        await ref.read(progressionServiceProvider).awardXp(
              uid: user.uid,
              xpDelta: xp,
              challengesSolvedDelta: _session.isComplete ? 1 : 0,
              perfectSolvesDelta: _session.isComplete ? 1 : 0,
            );
      }
    }

    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final elapsed = _session.elapsed;
    return SafeArea(
      child: Stack(
        children: [
          // The camouflaged image with tap detection.
          Center(
            child: AspectRatio(
              aspectRatio: widget.challenge.canvasAspectRatio,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final size =
                      Size(constraints.maxWidth, constraints.maxHeight);
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
                          imageUrl: widget.challenge.camouflagedImageUrl,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => const ColoredBox(
                            color: Colors.black26,
                            child: Center(child: CircularProgressIndicator()),
                          ),
                        ),
                        CustomPaint(
                          painter: FoundMarkersPainter(
                            inklings: widget.challenge.inklings,
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

          // HUD.
          Positioned(
            top: 12,
            left: 12,
            right: 12,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton.filledTonal(
                  onPressed: () => context.pop(),
                  icon: const Icon(Icons.close),
                ),
                _HudPill(
                  icon: Icons.search,
                  text: '${_session.foundCount}/${_session.total}',
                ),
                _HudPill(
                  icon: Icons.timer_outlined,
                  text: _format(elapsed),
                ),
              ],
            ),
          ),

          // Result overlay.
          if (_finished)
            ResultOverlay(
              found: _session.foundCount,
              total: _session.total,
              durationMs: _session.elapsed.inMilliseconds,
              score: _session.computeScore(),
              revealUrl: widget.challenge.revealedImageUrl,
              onReplay: () {
                setState(() {
                  _finished = false;
                  // Fresh session: the previous one keeps accumulating time.
                  _session = PlaySession(inklings: widget.challenge.inklings);
                  _lastMiss = null;
                });
                _startTicker();
              },
              onDone: () => context.pop(),
            ),

          // Give up / reveal button.
          if (!_finished)
            Positioned(
              bottom: 20,
              left: 0,
              right: 0,
              child: Center(
                child: TextButton.icon(
                  onPressed: _finish,
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.black54,
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.flag_outlined),
                  label: Text(AppLocalizations.of(context).giveUpReveal),
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _format(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}

class _HudPill extends StatelessWidget {
  const _HudPill({required this.icon, required this.text});
  final IconData icon;
  final String text;

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
          Icon(icon, color: AppColors.splash, size: 18),
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

/// Wraps HapticFeedback so tests on non-mobile platforms don't crash.
abstract class HapticFeedbackSafe {
  static void light() {
    try {
      // ignore: discarded_futures
      HapticFeedback.lightImpact();
    } catch (_) {}
  }
}
