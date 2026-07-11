import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/data/auth_repository.dart';
import '../../features/challenge/presentation/screens/challenge_detail_screen.dart';
import '../../features/community/presentation/screens/feed_screen.dart';
import '../../features/daily/presentation/screens/daily_screen.dart';
import '../../features/editor/presentation/screens/create_screen.dart';
import '../../features/editor/presentation/screens/editor_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/leaderboard/presentation/screens/leaderboard_screen.dart';
import '../../features/onboarding/presentation/screens/onboarding_screen.dart';
import '../../features/onboarding/presentation/screens/splash_screen.dart';
import '../../features/packs/presentation/screens/packs_screen.dart';
import '../../features/play/presentation/screens/play_screen.dart';
import '../../features/premium/presentation/screens/premium_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/progression/presentation/screens/badges_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
import '../../shared/widgets/home_shell.dart';
import 'routes.dart';

final _rootKey = GlobalKey<NavigatorState>();

/// Provides the app's [GoRouter], rebuilt when auth state changes so that
/// redirect guards stay in sync with the signed-in user.
final appRouterProvider = Provider<GoRouter>((ref) {
  final refresh = GoRouterRefreshStream(ref);

  return GoRouter(
    navigatorKey: _rootKey,
    initialLocation: Routes.splash,
    refreshListenable: refresh,
    redirect: (context, state) {
      final authAsync = ref.read(currentUserProvider);
      final loggedIn = authAsync.valueOrNull != null;
      final loc = state.matchedLocation;

      final entryRoutes = {Routes.splash, Routes.onboarding, Routes.signIn};

      // Signed in: any entry route funnels straight into the game.
      if (loggedIn) {
        return entryRoutes.contains(loc) ? Routes.home : null;
      }

      // Signed out: hold on the splash — it signs the player in anonymously
      // in the background (no login screens in the game flow).
      return loc == Routes.splash ? null : Routes.splash;
    },
    routes: [
      GoRoute(path: Routes.splash, builder: (_, __) => const SplashScreen()),
      GoRoute(
        path: Routes.onboarding,
        builder: (_, __) => const OnboardingScreen(),
      ),
      GoRoute(
        path: Routes.signIn,
        builder: (_, __) => const OnboardingScreen(startOnSignIn: true),
      ),

      // The game shell: a persistent bottom navigation bar hosts the four main
      // destinations (Play, Feed, Ranks, Profile) plus a central "create"
      // action. Each destination keeps its own navigation state.
      StatefulShellRoute.indexedStack(
        builder: (_, __, navigationShell) => HomeShell(shell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.home,
                builder: (_, __) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.feed,
                builder: (_, __) => const FeedScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.leaderboard,
                builder: (_, __) => const LeaderboardScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.profile,
                builder: (_, __) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),

      // Full-screen flows pushed above the shell.
      GoRoute(
        path: Routes.daily,
        parentNavigatorKey: _rootKey,
        builder: (_, __) => const DailyScreen(),
      ),
      GoRoute(
        path: Routes.create,
        parentNavigatorKey: _rootKey,
        builder: (_, __) => const CreateScreen(),
      ),
      GoRoute(
        path: Routes.editor,
        parentNavigatorKey: _rootKey,
        builder: (context, state) =>
            EditorScreen(args: state.extra as EditorArgs),
      ),
      GoRoute(
        path: Routes.challenge,
        parentNavigatorKey: _rootKey,
        builder: (_, state) =>
            ChallengeDetailScreen(challengeId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: Routes.play,
        parentNavigatorKey: _rootKey,
        builder: (_, state) =>
            PlayScreen(challengeId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: Routes.packs,
        parentNavigatorKey: _rootKey,
        builder: (_, __) => const PacksScreen(),
      ),
      GoRoute(
        path: Routes.premium,
        parentNavigatorKey: _rootKey,
        builder: (_, __) => const PremiumScreen(),
      ),
      GoRoute(
        path: Routes.settings,
        parentNavigatorKey: _rootKey,
        builder: (_, __) => const SettingsScreen(),
      ),
      GoRoute(
        path: Routes.badges,
        parentNavigatorKey: _rootKey,
        builder: (_, __) => const BadgesScreen(),
      ),
    ],
    errorBuilder: (_, state) =>
        Scaffold(body: Center(child: Text('Route not found: ${state.uri}'))),
  );
});

/// Bridges Riverpod's auth state to GoRouter's [Listenable] refresh contract.
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Ref ref) {
    ref.listen(currentUserProvider, (_, __) => notifyListeners());
  }
}
