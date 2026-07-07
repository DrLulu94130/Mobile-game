import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

/// Centralised, build-time configuration.
///
/// Secrets are injected via `--dart-define` so they never live in source
/// control. Sensible empty defaults keep the app compiling and runnable in a
/// local/dev context without any keys.
class Env {
  const Env._();

  static const String revenueCatAndroidKey =
      String.fromEnvironment('RC_ANDROID_KEY');
  static const String revenueCatIosKey =
      String.fromEnvironment('RC_IOS_KEY');

  /// Public deep-link / universal-link host used to open shared challenges.
  static const String dynamicLinkHost =
      String.fromEnvironment('DL_HOST', defaultValue: 'inkognito.page.link');

  static const String appStoreId =
      String.fromEnvironment('APPSTORE_ID', defaultValue: '0000000000');
  static const String androidPackage = String.fromEnvironment(
    'ANDROID_PACKAGE',
    defaultValue: 'app.inkognito.game',
  );

  /// RevenueCat entitlement identifier that unlocks Premium features.
  static const String premiumEntitlement = 'premium';

  /// Best-effort RevenueCat configuration. Silently no-ops when keys are
  /// absent (e.g. CI, unit tests) so the app still runs in Free mode.
  static Future<void> configureBilling() async {
    final key = Platform.isIOS ? revenueCatIosKey : revenueCatAndroidKey;
    if (key.isEmpty) return;
    try {
      await Purchases.setLogLevel(
        kDebugMode ? LogLevel.debug : LogLevel.warn,
      );
      await Purchases.configure(PurchasesConfiguration(key));
    } catch (_) {
      // Billing is optional; never block startup.
    }
  }
}
