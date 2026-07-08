import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:inkognito/l10n/app_localizations.dart';

import '../../../../core/ads/banner_ad_widget.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/juicy_button.dart';
import '../../../../shared/widgets/mascot_3d.dart';
import '../../../auth/data/auth_repository.dart';

/// The game's main menu: the live 3D character front and centre, one glowing
/// "hide" CTA and one "seek" CTA. No tabs, no app chrome — arcade first.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final tokens = ref.watch(currentUserProvider).valueOrNull?.tokens ?? 0;
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
                    const SizedBox(width: 8),
                    _TokenBalance(tokens: tokens),
                    const Spacer(),
                    _RoundIcon(
                      icon: Icons.workspace_premium_rounded,
                      onTap: () => context.push(Routes.premium),
                    ),
                    const SizedBox(width: 8),
                    _RoundIcon(
                      icon: Icons.person_rounded,
                      onTap: () => context.push(Routes.profile),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'INKOGNITO',
                style: GoogleFonts.luckiestGuy(
                  color: Colors.white,
                  fontSize: 46,
                  letterSpacing: 3,
                  shadows: [
                    const Shadow(
                      color: Color(0xFF2B1B7E),
                      offset: Offset(0, 5),
                      blurRadius: 0,
                    ),
                    Shadow(
                      color: AppColors.splash.withValues(alpha: 0.55),
                      offset: const Offset(0, 10),
                      blurRadius: 24,
                    ),
                  ],
                ),
              ),
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
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
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
                      onPressed: () => context.push(Routes.discover),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _QuickLink(
                          icon: Icons.grid_view_rounded,
                          label: l.navFeed,
                          onTap: () => context.push(Routes.feed),
                        ),
                        const SizedBox(width: 10),
                        _QuickLink(
                          icon: Icons.today_rounded,
                          label: l.navDaily,
                          onTap: () => context.push(Routes.daily),
                        ),
                        const SizedBox(width: 10),
                        _QuickLink(
                          icon: Icons.leaderboard_rounded,
                          label: l.navRanks,
                          onTap: () => context.push(Routes.leaderboard),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Free-tier banner (renders nothing for Premium users).
              const BannerAdWidget(),
            ],
          ),
        ),
      ),
    );
  }
}

/// The player's token balance ("jetons"), spent to publish drawings.
class _TokenBalance extends StatelessWidget {
  const _TokenBalance({required this.tokens});
  final int tokens;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
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

/// Small pill linking to a secondary screen (gallery, daily, rankings).
class _QuickLink extends StatelessWidget {
  const _QuickLink({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.14),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white, size: 16),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
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
