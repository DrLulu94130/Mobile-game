import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:inkognito/l10n/app_localizations.dart';

import '../../../../core/router/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/juicy_button.dart';
import '../../../editor/domain/entities/inkling_species.dart';
import '../../../editor/domain/entities/placed_inkling.dart';
import '../../../editor/presentation/painters/inkling_painter.dart';
import '../../../play/domain/detection_engine.dart';
import '../../../play/presentation/widgets/found_markers.dart';
import '../../data/first_run_service.dart';

/// First-run playable tutorial: spot two half-hidden Inklings in a painted
/// scene, then get sent off to create or explore.
///
/// Teaching by doing — the player wins a real round of seek in under thirty
/// seconds and understands the whole game loop viscerally, with zero text
/// walls. Uses the real [PlaySession] detection, so what they learn here is
/// exactly what the game does.
class TutorialScreen extends ConsumerStatefulWidget {
  const TutorialScreen({super.key});

  @override
  ConsumerState<TutorialScreen> createState() => _TutorialScreenState();
}

class _TutorialScreenState extends ConsumerState<TutorialScreen> {
  static const List<PlacedInkling> _inklings = [
    PlacedInkling(
      id: 'tutorial-classic',
      species: InklingSpecies.classic,
      variantId: 'default',
      center: Offset(0.28, 0.66),
      size: 0.26,
      rotation: 0,
    ),
    PlacedInkling(
      id: 'tutorial-ghost',
      species: InklingSpecies.ghost,
      variantId: 'default',
      center: Offset(0.74, 0.34),
      size: 0.22,
      rotation: 0,
    ),
  ];

  late final PlaySession _session = PlaySession(inklings: _inklings);
  Offset? _lastMiss;
  bool _done = false;

  Future<void> _markDone() async {
    await ref.read(firstRunServiceProvider).markTutorialDone();
    ref.invalidate(tutorialDoneProvider);
  }

  Future<void> _leaveTo(String route) async {
    await _markDone();
    if (!mounted) return;
    context.go(route);
  }

  Future<void> _leaveToCreate() async {
    await _markDone();
    if (!mounted) return;
    context.go(Routes.home);
    context.push(Routes.create);
  }

  void _onTap(Offset normalised) {
    if (_done) return;
    final result = _session.tap(normalised);
    setState(() => _lastMiss = result.hit ? null : normalised);
    if (result.hit) {
      try {
        HapticFeedback.lightImpact();
      } catch (_) {}
    }
    if (_session.isComplete) {
      setState(() => _done = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final coach =
        _session.foundCount == 1 ? l.tutorialOneLeft : l.tutorialFindBody;

    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(gradient: AppColors.brandGradient),
        child: SafeArea(
          child: Stack(
            children: [
              Column(
                children: [
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => _leaveTo(Routes.home),
                      child: Text(
                        l.tutorialSkip,
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      l.tutorialTitle,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    coach,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Center(
                        child: AspectRatio(
                          aspectRatio: 3 / 4,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(24),
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                final size = Size(
                                  constraints.maxWidth,
                                  constraints.maxHeight,
                                );
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
                                      const CustomPaint(
                                        painter: _MeadowPainter(),
                                      ),
                                      for (final inkling in _inklings)
                                        Positioned.fromRect(
                                          rect: inkling.rectFor(size),
                                          child: Opacity(
                                            opacity: 0.55,
                                            child: CustomPaint(
                                              painter: InklingPainter(
                                                inkling: inkling,
                                              ),
                                            ),
                                          ),
                                        ),
                                      CustomPaint(
                                        painter: FoundMarkersPainter(
                                          inklings: _inklings,
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
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${_session.foundCount}/${_session.total}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              if (_done)
                _CompletionOverlay(
                  onCreate: _leaveToCreate,
                  onExplore: () => _leaveTo(Routes.feed),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Full-screen celebration once both Inklings are found.
class _CompletionOverlay extends StatelessWidget {
  const _CompletionOverlay({required this.onCreate, required this.onExplore});

  final VoidCallback onCreate;
  final VoidCallback onExplore;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Container(
      color: Colors.black.withValues(alpha: 0.75),
      alignment: Alignment.center,
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l.tutorialDoneTitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 30,
              fontWeight: FontWeight.w900,
            ),
          ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack),
          const SizedBox(height: 12),
          Text(
            l.tutorialDoneBody,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 32),
          JuicyButton.primary(
            title: l.tutorialCreateCta,
            icon: Icons.brush_rounded,
            onPressed: onCreate,
          ),
          const SizedBox(height: 14),
          JuicyButton.ghost(
            title: l.tutorialExploreCta,
            icon: Icons.search_rounded,
            onPressed: onExplore,
          ),
        ],
      ),
    );
  }
}

/// Procedural painted meadow the tutorial Inklings hide in — brand-coloured
/// layered hills, a glow sun and ink-drop accents. Purely deterministic, no
/// image assets, so the tutorial works offline on first launch.
class _MeadowPainter extends CustomPainter {
  const _MeadowPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final rect = Offset.zero & size;

    // Sky wash.
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFA29BFE), Color(0xFF6C5CE7)],
        ).createShader(rect),
    );

    // Sun glow.
    canvas.drawCircle(
      Offset(w * 0.80, h * 0.14),
      size.shortestSide * 0.12,
      Paint()..color = AppColors.glow,
    );

    // Layered hills, back to front.
    _hill(canvas, size,
        baseline: 0.46, bump: 0.14, color: const Color(0xFF00CEC9));
    _hill(canvas, size,
        baseline: 0.62, bump: 0.16, color: const Color(0xFF00A8A3));
    _hill(canvas, size,
        baseline: 0.80, bump: 0.14, color: const Color(0xFF4834D4));

    // Ink-drop accents on the foreground hill.
    final drop = Paint()..color = Colors.white.withValues(alpha: 0.25);
    canvas.drawCircle(Offset(w * 0.16, h * 0.90), w * 0.02, drop);
    canvas.drawCircle(Offset(w * 0.52, h * 0.94), w * 0.015, drop);
    canvas.drawCircle(Offset(w * 0.88, h * 0.88), w * 0.018, drop);
  }

  /// One rounded hill spanning the full width from [baseline] (0..1 of the
  /// height) down to the bottom edge, with a [bump]-high crest.
  void _hill(
    Canvas canvas,
    Size size, {
    required double baseline,
    required double bump,
    required Color color,
  }) {
    final w = size.width;
    final h = size.height;
    final path = Path()
      ..moveTo(0, h * baseline)
      ..quadraticBezierTo(
        w * 0.30,
        h * (baseline - bump),
        w * 0.55,
        h * baseline,
      )
      ..quadraticBezierTo(
        w * 0.80,
        h * (baseline + bump * 0.6),
        w,
        h * (baseline - bump * 0.3),
      )
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _MeadowPainter oldDelegate) => false;
}
