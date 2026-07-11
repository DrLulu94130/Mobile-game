/// A comment left on a community challenge.
class Comment {
  const Comment({
    required this.id,
    required this.challengeId,
    required this.authorId,
    required this.authorName,
    this.authorAvatarUrl,
    required this.text,
    required this.createdAt,
    this.likeCount = 0,
  });

  final String id;
  final String challengeId;
  final String authorId;
  final String authorName;
  final String? authorAvatarUrl;
  final String text;
  final DateTime createdAt;
  final int likeCount;

  Map<String, dynamic> toJson() => {
        'challengeId': challengeId,
        'authorId': authorId,
        'authorName': authorName,
        'authorAvatarUrl': authorAvatarUrl,
        'text': text,
        'createdAt': createdAt.toUtc().toIso8601String(),
        'likeCount': likeCount,
      };

  factory Comment.fromJson(String id, Map<String, dynamic> json) {
    return Comment(
      id: id,
      challengeId: json['challengeId'] as String? ?? '',
      authorId: json['authorId'] as String? ?? '',
      authorName: json['authorName'] as String? ?? 'Player',
      authorAvatarUrl: json['authorAvatarUrl'] as String?,
      text: json['text'] as String? ?? '',
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
      likeCount: (json['likeCount'] as num?)?.toInt() ?? 0,
    );
  }
}
