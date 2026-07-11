import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Holds the user's preferred [ThemeMode]. Defaults to following the system,
/// giving full Dark Mode support out of the box.
class ThemeController extends StateNotifier<ThemeMode> {
  ThemeController() : super(ThemeMode.system);

  void set(ThemeMode mode) => state = mode;

  void toggle() {
    state = switch (state) {
      ThemeMode.light => ThemeMode.dark,
      ThemeMode.dark => ThemeMode.light,
      ThemeMode.system => ThemeMode.dark,
    };
  }
}

final themeControllerProvider =
    StateNotifierProvider<ThemeController, ThemeMode>(
      (ref) => ThemeController(),
    );
