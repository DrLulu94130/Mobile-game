import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Holds the user's preferred [Locale]. `null` means "follow the system",
/// which is the default. The app ships with English and French.
class LocaleController extends StateNotifier<Locale?> {
  LocaleController() : super(null);

  static const supported = [Locale('en'), Locale('fr')];

  void set(Locale? locale) => state = locale;
}

final localeControllerProvider =
    StateNotifierProvider<LocaleController, Locale?>(
      (ref) => LocaleController(),
    );
