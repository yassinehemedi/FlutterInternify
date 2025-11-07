class Event {
  final int? id;
  final String title;
  final String description;
  final String type;
  final String creationDate;
  final String creationTime;
  final String deadlineDate;
  final String deadlineTime;
  final String status;
  final int userId;

  Event({
    this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.creationDate,
    required this.creationTime,
    required this.deadlineDate,
    required this.deadlineTime,
    required this.status,
    required this.userId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'type': type,
      'creation_date': creationDate,
      'creation_time': creationTime,
      'deadline_date': deadlineDate,
      'deadline_time': deadlineTime,
      'status': status,
      'userId': userId,
    };
  }

  factory Event.fromMap(Map<String, dynamic> map) {
    return Event(
      id: map['id'],
      title: map['title'],
      description: map['description'],
      type: map['type'],
      creationDate: map['creation_date'],
      creationTime: map['creation_time'],
      deadlineDate: map['deadline_date'],
      deadlineTime: map['deadline_time'],
      status: map['status'],
      userId: map['userId'],
    );
  }
}
