import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../auth/data/auth_repository.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../editor/domain/entities/inkling_species.dart';
import '../../../../shared/widgets/app_logo_title.dart';
import '../../../../shared/widgets/inkling_avatar.dart';

/// Branded splash shown while the auth state resolves.
///
/// There is no login UI in the game flow: if the player turns out to be
/// signed out, this screen silently creates an anonymous account and the
/// router then advances to the main menu.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  bool _signInStarted = false;

  void _ensureSignedIn(AsyncValue<Object?> auth) {
    if (_signInStarted) return;
    if (auth is AsyncData && auth.value == null) {
      _signInStarted = true;
      ref.read(authControllerProvider.notifier).signInAnonymously();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Reacts both to the initial value and to later emissions.
    _ensureSignedIn(ref.watch(currentUserProvider));
    ref.listen(currentUserProvider, (_, next) => _ensureSignedIn(next));
    return DecoratedBox(
      decoration: const BoxDecoration(gradient: AppColors.brandGradient),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const InklingAvatar(species: InklingSpecies.classic, size: 120)
                  .animate(onPlay: (c) => c.repeat(reverse: true))
                  .moveY(begin: 0, end: -14, duration: 900.ms)
                  .then()
                  .scaleXY(begin: 1, end: 1.03, duration: 900.ms),
              const SizedBox(height: 24),
              const AppLogoTitle(fontSize: 40, letterSpacing: 2),
              const SizedBox(height: 8),
              Text(
                'Hide. Camouflage. Challenge.',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.85),
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 40),
              const SizedBox(
                width: 26,
                height: 26,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
