/// Strongly-typed route names and path helpers for GoRouter.
abstract class Routes {
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String signIn = '/sign-in';

  /// The game main menu.
  static const String home = '/home';

  // Secondary screens
  static const String feed = '/feed';
  static const String discover = '/discover';
  static const String daily = '/daily';
  static const String leaderboard = '/leaderboard';
  static const String profile = '/profile';

  // Creation flow
  static const String create = '/create';
  static const String editor = '/editor';

  // Detail / play
  static const String challenge = '/challenge/:id';
  static String challengePath(String id) => '/challenge/$id';
  static const String play = '/play/:id';
  static String playPath(String id) => '/play/$id';

  static const String packs = '/packs';
  static const String premium = '/premium';
  static const String settings = '/settings';
  static const String badges = '/badges';
}
