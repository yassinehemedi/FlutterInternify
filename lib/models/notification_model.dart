class NotificationModel {
  final int? idNotification;
  final String title;
  final String body;
  final DateTime createdAt;
  final int recipientId;
  final bool isRead;
  final int? offerId;

  NotificationModel({
    this.idNotification,
    required this.title,
    required this.body,
    required this.createdAt,
    required this.recipientId,
    this.isRead = false,
    this.offerId,
  });

  NotificationModel copyWith({
    int? idNotification,
    String? title,
    String? body,
    DateTime? createdAt,
    int? recipientId,
    bool? isRead,
    int? offerId,
  }) {
    return NotificationModel(
      idNotification: idNotification ?? this.idNotification,
      title: title ?? this.title,
      body: body ?? this.body,
      createdAt: createdAt ?? this.createdAt,
      recipientId: recipientId ?? this.recipientId,
      isRead: isRead ?? this.isRead,
      offerId: offerId ?? this.offerId,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'title': title,
      'body': body,
      'createdAt': createdAt.toIso8601String(),
      'recipientId': recipientId,
      'isRead': isRead ? 1 : 0,
      'offerId': offerId,
    };
  }

  static NotificationModel fromMap(Map<String, Object?> m) {
    return NotificationModel(
      idNotification: m['id_notification'] as int?,
      title: m['title'] as String,
      body: m['body'] as String,
      createdAt: DateTime.parse(m['createdAt'] as String),
      recipientId: m['recipientId'] as int,
      isRead: (m['isRead'] as int) == 1,
      offerId: m['offerId'] as int?,
    );
  }
}
