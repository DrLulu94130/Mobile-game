import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

/// Remembers whether the playable tutorial has been completed, via a marker
/// file in the app documents directory (no plugin beyond path_provider).
///
/// Reads fail open (returns true) so a storage hiccup can never trap a
/// player in the tutorial.
class FirstRunService {
  static const String _markerName = '.tutorial_done';

  Future<File> _marker() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/$_markerName');
  }

  Future<bool> isTutorialDone() async {
    try {
      return await (await _marker()).exists();
    } catch (_) {
      return true;
    }
  }

  Future<void> markTutorialDone() async {
    try {
      await (await _marker()).create();
    } catch (_) {
      // Worst case the tutorial shows again next launch; it is skippable.
    }
  }
}

final firstRunServiceProvider = Provider<FirstRunService>(
  (ref) => FirstRunService(),
);

/// Whether the tutorial was already completed. `null` while loading — the
/// router holds the splash until this resolves.
final tutorialDoneProvider = FutureProvider<bool>(
  (ref) => ref.watch(firstRunServiceProvider).isTutorialDone(),
);
