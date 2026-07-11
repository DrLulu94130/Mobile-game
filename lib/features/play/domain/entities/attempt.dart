import 'package:flutter/material.dart';

/// The result of a player attempting to solve a challenge.
class Attempt {
  const Attempt({
    required this.id,
    required this.challengeId,
    required this.playerId,
    required this.foundCount,
    required this.totalInklings,
    required this.durationMs,
    required this.score,
    required this.taps,
    required this.createdAt,
  });

  final String id;
  final String challengeId;
  final String playerId;
  final int foundCount;
  final int totalInklings;
  final int durationMs;
  final int score;

  /// Every tap the player made, in normalised canvas coordinates, for replay
  /// and heat-map analytics.
  final List<Offset> taps;

  final DateTime createdAt;

  bool get isPerfect => foundCount == totalInklings;
  double get accuracy => taps.isEmpty ? 0 : foundCount / taps.length;

  Map<String, dynamic> toJson() => {
        'challengeId': challengeId,
        'playerId': playerId,
        'foundCount': foundCount,
        'totalInklings': totalInklings,
        'durationMs': durationMs,
        'score': score,
        'taps': taps.expand((o) => [o.dx, o.dy]).toList(),
        'createdAt': createdAt.toUtc().toIso8601String(),
      };

  factory Attempt.fromJson(String id, Map<String, dynamic> json) {
    final flat = (json['taps'] as List? ?? []).cast<num>();
    return Attempt(
      id: id,
      challengeId: json['challengeId'] as String? ?? '',
      playerId: json['playerId'] as String? ?? '',
      foundCount: (json['foundCount'] as num?)?.toInt() ?? 0,
      totalInklings: (json['totalInklings'] as num?)?.toInt() ?? 0,
      durationMs: (json['durationMs'] as num?)?.toInt() ?? 0,
      score: (json['score'] as num?)?.toInt() ?? 0,
      taps: [
        for (var i = 0; i + 1 < flat.length; i += 2)
          Offset(flat[i].toDouble(), flat[i + 1].toDouble()),
      ],
      createdAt: _parseDate(json['createdAt']),
    );
  }

  /// Attempts are written server-side with a Firestore Timestamp, but older
  /// documents stored an ISO string — accept both.
  static DateTime _parseDate(dynamic value) {
    if (value is String) {
      return DateTime.tryParse(value)?.toLocal() ?? DateTime.now();
    }
    try {
      return (value as dynamic).toDate() as DateTime;
    } catch (_) {
      return DateTime.now();
    }
  }
}
