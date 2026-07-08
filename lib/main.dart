import 'dart:async';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/ads/ad_service.dart';
import 'core/config/env.dart';
import 'firebase_options.dart';

/// Application entry point.
///
/// Bootstraps Firebase, Crashlytics error handling and RevenueCat before
/// mounting the widget tree inside a Riverpod [ProviderScope].
Future<void> main() async {
  await runZonedGuarded<Future<void>>(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      // Route uncaught Flutter framework errors to Crashlytics.
      FlutterError.onError = (details) {
        FlutterError.presentError(details);
        if (!kDebugMode) {
          FirebaseCrashlytics.instance.recordFlutterFatalError(details);
        }
      };

      // Route uncaught platform/async errors to Crashlytics.
      PlatformDispatcher.instance.onError = (error, stack) {
        FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
        return true;
      };

      await FirebaseCrashlytics.instance
          .setCrashlyticsCollectionEnabled(!kDebugMode);
      await FirebaseAnalytics.instance
          .setAnalyticsCollectionEnabled(!kDebugMode);

      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
      ]);

      // Best-effort billing bootstrap; failure must not block app start.
      await Env.configureBilling();

      final container = ProviderContainer();
      // Warm up the ads SDK for the Free tier (no-op on failure).
      unawaited(container.read(adServiceProvider).initialize());

      runApp(
        UncontrolledProviderScope(
          container: container,
          child: const InkognitoApp(),
        ),
      );
    },
    (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    },
  );
}
