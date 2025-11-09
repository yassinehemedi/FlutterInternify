class CommentModel {
  final int? idComment;
  final String commentContent;
  final DateTime createdAt;
  final int userId;
  final int offerId;

  CommentModel({
    this.idComment,
    required this.commentContent,
    DateTime? createdAt,
    required this.userId,
    required this.offerId,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id_comment': idComment,
      'comment_content': commentContent,
      'createdAt': createdAt.toIso8601String(),
      'userId': userId,
      'offerId': offerId,
    };
  }

  factory CommentModel.fromMap(Map<String, dynamic> map) {
    return CommentModel(
      idComment: map['id_comment'] as int?,
      commentContent: map['comment_content'] as String,
      createdAt: DateTime.parse(map['createdAt'] as String),
      userId: map['userId'] as int,
      offerId: map['offerId'] as int,
    );
  }

  CommentModel copyWith({
    int? idComment,
    String? commentContent,
    DateTime? createdAt,
    int? userId,
    int? offerId,
  }) {
    return CommentModel(
      idComment: idComment ?? this.idComment,
      commentContent: commentContent ?? this.commentContent,
      createdAt: createdAt ?? this.createdAt,
      userId: userId ?? this.userId,
      offerId: offerId ?? this.offerId,
    );
  }

  @override
  String toString() {
    return 'Comment{id_comment: $idComment, offerId: $offerId, userId: $userId}';
  }
}
