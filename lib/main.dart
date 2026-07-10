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
/// Initialises Firebase and error handling, mounts the widget tree inside a
/// Riverpod [ProviderScope] as early as possible, then warms up the remaining
/// non-critical services (analytics, billing, ads) off the first-frame path.
Future<void> main() async {
  await runZonedGuarded<Future<void>>(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      // Only Firebase must be ready before the first frame — everything else
      // is deferred so the UI paints as early as possible.
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

      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
      ]);

      final container = ProviderContainer();

      runApp(
        UncontrolledProviderScope(
          container: container,
          child: const InkognitoApp(),
        ),
      );

      // Fire-and-forget the non-critical bootstrap once the UI is on screen:
      // analytics/crash reporting toggles, billing and the ads SDK. None of
      // these should ever delay the first frame.
      unawaited(_warmUpServices(container));
    },
    (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    },
  );
}

/// Best-effort initialisation that runs after the first frame so it never
/// blocks startup. Every step is independently guarded upstream.
Future<void> _warmUpServices(ProviderContainer container) async {
  await FirebaseCrashlytics.instance
      .setCrashlyticsCollectionEnabled(!kDebugMode);
  await FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(!kDebugMode);

  // Best-effort billing bootstrap; failure must not affect the app.
  await Env.configureBilling();

  // Warm up the ads SDK for the Free tier (no-op on failure).
  unawaited(container.read(adServiceProvider).initialize());
}
