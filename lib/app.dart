import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inkognito/l10n/app_localizations.dart';

import 'core/deeplink/deep_link_listener.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/settings/presentation/controllers/locale_controller.dart';

/// Root widget of the Inkognito application.
///
/// Wires up theming, routing via GoRouter, the Riverpod-driven [Locale]
/// preference and localisation.
class InkognitoApp extends ConsumerWidget {
  const InkognitoApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final locale = ref.watch(localeControllerProvider);

    return DeepLinkListener(
      router: router,
      child: MaterialApp.router(
        title: 'Inkognito',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: router,
      ),
    );
  }
}
