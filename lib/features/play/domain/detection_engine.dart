import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';
import '../../editor/domain/entities/placed_inkling.dart';

/// Result of testing a tap against the hidden Inklings.
class DetectionResult {
  const DetectionResult({
    required this.hit,
    this.inklingId,
    this.distance = double.infinity,
  });

  final bool hit;
  final String? inklingId;
  final double distance;
}

/// Live scoring state for a play session.
class PlaySession {
  PlaySession({required this.inklings});

  final List<PlacedInkling> inklings;
  final Set<String> found = {};
  final List<Offset> taps = [];
  DateTime? _startedAt;

  int get total => inklings.length;
  int get foundCount => found.length;
  bool get isComplete => found.length == inklings.length;

  Duration get elapsed => _startedAt == null
      ? Duration.zero
      : DateTime.now().difference(_startedAt!);

  void start() => _startedAt ??= DateTime.now();

  /// Tests a tap in **normalised** canvas coordinates and records the result.
  DetectionResult tap(Offset normalised) {
    start();
    taps.add(normalised);
    final result = DetectionEngine.hitTest(
      tap: normalised,
      inklings: inklings,
      alreadyFound: found,
    );
    if (result.hit && result.inklingId != null) {
      found.add(result.inklingId!);
    }
    return result;
  }

  /// Final score: rewards accuracy, speed and completeness.
  int computeScore() {
    if (total == 0) return 0;
    final completion = foundCount / total; // 0..1
    final accuracy = taps.isEmpty ? 0.0 : foundCount / taps.length; // 0..1
    final seconds = elapsed.inMilliseconds / 1000.0;
    // Speed bonus decays over ~2 minutes.
    final speed = math.max(0.0, 1 - (seconds / 120));

    final base = completion * 1000;
    final accuracyBonus = accuracy * 400;
    final speedBonus = speed * 300 * completion;
    final perfectBonus = isComplete ? 300 : 0;
    return (base + accuracyBonus + speedBonus + perfectBonus).round();
  }
}

/// Pure hit-testing logic, isolated for unit testing.
abstract class DetectionEngine {
  /// Returns the closest not-yet-found Inkling within tolerance, if any.
  static DetectionResult hitTest({
    required Offset tap,
    required List<PlacedInkling> inklings,
    required Set<String> alreadyFound,
    double toleranceFactor = AppConstants.detectionToleranceFactor,
  }) {
    DetectionResult best = const DetectionResult(hit: false);
    for (final inkling in inklings) {
      if (alreadyFound.contains(inkling.id)) continue;
      final d = (tap - inkling.center).distance;
      // The Inkling's normalised radius plus a fixed tolerance band.
      final radius = inkling.size / 2 + toleranceFactor;
      if (d <= radius && d < best.distance) {
        best = DetectionResult(hit: true, inklingId: inkling.id, distance: d);
      }
    }
    return best;
  }
}
