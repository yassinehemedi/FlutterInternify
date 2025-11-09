class CommentReport {
  final int? idReport;
  final int commentId;
  final int reporterId;
  final DateTime createdAt;

  CommentReport({
    this.idReport,
    required this.commentId,
    required this.reporterId,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, Object?> toMap() {
    return {
      'commentId': commentId,
      'reporterId': reporterId,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  static CommentReport fromMap(Map<String, Object?> m) {
    return CommentReport(
      idReport: m['id_report'] as int?,
      commentId: m['commentId'] as int,
      reporterId: m['reporterId'] as int,
      createdAt: DateTime.parse(m['createdAt'] as String),
    );
  }

  CommentReport copyWith(
      {int? idReport, int? commentId, int? reporterId, DateTime? createdAt}) {
    return CommentReport(
      idReport: idReport ?? this.idReport,
      commentId: commentId ?? this.commentId,
      reporterId: reporterId ?? this.reporterId,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
