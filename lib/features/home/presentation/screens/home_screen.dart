import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:inkognito/l10n/app_localizations.dart';

import '../../../../core/router/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/app_logo_title.dart';
import '../../../../shared/widgets/juicy_button.dart';
import '../../../../shared/widgets/mascot_3d.dart';

/// The game's "Play" tab: the live 3D character front and centre, a glowing
/// "hide" CTA, a "seek" CTA and a quick link to the daily challenges. The
/// persistent bottom navigation lives in the surrounding [HomeShell].
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(gradient: AppColors.brandGradient),
        child: SafeArea(
          child: Column(
            children: [
              // Slim utility row — everything else is game.
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
                child: Row(
                  children: [
                    _RoundIcon(
                      icon: Icons.settings_rounded,
                      onTap: () => context.push(Routes.settings),
                    ),
                    const Spacer(),
                    _RoundIcon(
                      icon: Icons.workspace_premium_rounded,
                      onTap: () => context.push(Routes.premium),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              const AppLogoTitle(fontSize: 46, letterSpacing: 3),
              const SizedBox(height: 4),
              Text(
                l.homeTagline,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.85),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              // The star of the menu: the paintable white character, live.
              Expanded(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                          width: 280,
                          height: 280,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                Colors.white.withValues(alpha: 0.28),
                                Colors.white.withValues(alpha: 0.06),
                                Colors.white.withValues(alpha: 0),
                              ],
                              stops: const [0.0, 0.6, 1.0],
                            ),
                          ),
                        )
                        .animate(onPlay: (c) => c.repeat(reverse: true))
                        .scaleXY(begin: 0.96, end: 1.05, duration: 1600.ms),
                    const Positioned.fill(child: Mascot3D()),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                child: Column(
                  children: [
                    JuicyButton.primary(
                      title: l.homeHideCta,
                      subtitle: l.homeHideSub,
                      icon: Icons.brush_rounded,
                      onPressed: () => context.push(Routes.create),
                    ),
                    const SizedBox(height: 14),
                    JuicyButton.ghost(
                      title: l.homeSeekCta,
                      subtitle: l.homeSeekSub,
                      icon: Icons.search_rounded,
                      // Switch to the Feed tab inside the shell.
                      onPressed: () => context.go(Routes.feed),
                    ),
                    const SizedBox(height: 6),
                    TextButton.icon(
                      onPressed: () => context.push(Routes.daily),
                      icon: const Icon(
                        Icons.today_rounded,
                        size: 18,
                        color: Colors.white,
                      ),
                      label: Text(
                        l.daily,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoundIcon extends StatelessWidget {
  const _RoundIcon({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.14),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(icon, color: Colors.white, size: 22),
        ),
      ),
    );
  }
}
