import '../../../editor/domain/entities/placed_inkling.dart';

/// A published (or draft) hide-and-seek challenge.
class Challenge {
  const Challenge({
    required this.id,
    required this.authorId,
    required this.authorName,
    this.authorAvatarUrl,
    required this.title,
    required this.camouflagedImageUrl,
    required this.revealedImageUrl,
    required this.inklings,
    required this.canvasAspectRatio,
    required this.createdAt,
    this.likeCount = 0,
    this.commentCount = 0,
    this.playCount = 0,
    this.bestTimeMs,
    this.isPublic = true,
    this.difficulty = 1,
  });

  final String id;
  final String authorId;
  final String authorName;
  final String? authorAvatarUrl;
  final String title;

  /// Publicly shareable image where the Inklings are camouflaged.
  final String camouflagedImageUrl;

  /// Solution image with Inkling positions revealed.
  final String revealedImageUrl;

  /// Inkling placements — the ground truth used for detection scoring.
  final List<PlacedInkling> inklings;

  /// width / height of the source photo, used to lay out the canvas.
  final double canvasAspectRatio;

  final DateTime createdAt;
  final int likeCount;
  final int commentCount;
  final int playCount;
  final int? bestTimeMs;
  final bool isPublic;

  /// 1..5 difficulty derived from Inkling count and camouflage density.
  final int difficulty;

  int get inklingCount => inklings.length;

  Challenge copyWith({
    int? likeCount,
    int? commentCount,
    int? playCount,
    int? bestTimeMs,
    bool? isPublic,
  }) {
    return Challenge(
      id: id,
      authorId: authorId,
      authorName: authorName,
      authorAvatarUrl: authorAvatarUrl,
      title: title,
      camouflagedImageUrl: camouflagedImageUrl,
      revealedImageUrl: revealedImageUrl,
      inklings: inklings,
      canvasAspectRatio: canvasAspectRatio,
      createdAt: createdAt,
      likeCount: likeCount ?? this.likeCount,
      commentCount: commentCount ?? this.commentCount,
      playCount: playCount ?? this.playCount,
      bestTimeMs: bestTimeMs ?? this.bestTimeMs,
      isPublic: isPublic ?? this.isPublic,
      difficulty: difficulty,
    );
  }

  /// Firestore serialisation. `createdAt` is written as an ISO string here;
  /// the repository swaps in a server timestamp on create.
  Map<String, dynamic> toJson() => {
    'authorId': authorId,
    'authorName': authorName,
    'authorAvatarUrl': authorAvatarUrl,
    'title': title,
    'camouflagedImageUrl': camouflagedImageUrl,
    'revealedImageUrl': revealedImageUrl,
    'inklings': inklings.map((e) => e.toJson()).toList(),
    'canvasAspectRatio': canvasAspectRatio,
    'createdAt': createdAt.toUtc().toIso8601String(),
    'likeCount': likeCount,
    'commentCount': commentCount,
    'playCount': playCount,
    'bestTimeMs': bestTimeMs,
    'isPublic': isPublic,
    'difficulty': difficulty,
  };

  factory Challenge.fromJson(String id, Map<String, dynamic> json) {
    return Challenge(
      id: id,
      authorId: json['authorId'] as String? ?? '',
      authorName: json['authorName'] as String? ?? 'Unknown',
      authorAvatarUrl: json['authorAvatarUrl'] as String?,
      title: json['title'] as String? ?? 'Untitled',
      camouflagedImageUrl: json['camouflagedImageUrl'] as String? ?? '',
      revealedImageUrl: json['revealedImageUrl'] as String? ?? '',
      inklings: (json['inklings'] as List? ?? [])
          .map((e) => PlacedInkling.fromJson(e as Map<String, dynamic>))
          .toList(),
      canvasAspectRatio: (json['canvasAspectRatio'] as num?)?.toDouble() ?? 1.0,
      createdAt: _parseDate(json['createdAt']),
      likeCount: (json['likeCount'] as num?)?.toInt() ?? 0,
      commentCount: (json['commentCount'] as num?)?.toInt() ?? 0,
      playCount: (json['playCount'] as num?)?.toInt() ?? 0,
      bestTimeMs: (json['bestTimeMs'] as num?)?.toInt(),
      isPublic: json['isPublic'] as bool? ?? true,
      difficulty: (json['difficulty'] as num?)?.toInt() ?? 1,
    );
  }

  static DateTime _parseDate(dynamic value) {
    if (value is String) {
      return DateTime.tryParse(value)?.toLocal() ?? DateTime.now();
    }
    // Firestore Timestamp exposes toDate() via dynamic dispatch.
    try {
      return (value as dynamic).toDate() as DateTime;
    } catch (_) {
      return DateTime.now();
    }
  }
}
