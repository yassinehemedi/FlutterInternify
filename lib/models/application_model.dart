class ApplicationModel {
  final int? idApplication;
  final String? cvFile; // local path
  final String? motivationalMessage;
  final String status; // Pending, Approved, Denied
  final DateTime createdAt;
  final int userId;
  final int offerId;

  ApplicationModel({
    this.idApplication,
    this.cvFile,
    this.motivationalMessage,
    this.status = 'Pending',
    DateTime? createdAt,
    required this.userId,
    required this.offerId,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id_application': idApplication,
      'cv_file': cvFile,
      'motivational_message': motivationalMessage,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'userId': userId,
      'offerId': offerId,
    };
  }

  factory ApplicationModel.fromMap(Map<String, dynamic> map) {
    return ApplicationModel(
      idApplication: map['id_application'] as int?,
      cvFile: map['cv_file'] as String?,
      motivationalMessage: map['motivational_message'] as String?,
      status: map['status'] as String? ?? 'Pending',
      createdAt: DateTime.parse(map['createdAt'] as String),
      userId: map['userId'] as int,
      offerId: map['offerId'] as int,
    );
  }

  ApplicationModel copyWith({
    int? idApplication,
    String? cvFile,
    String? motivationalMessage,
    String? status,
    DateTime? createdAt,
    int? userId,
    int? offerId,
  }) {
    return ApplicationModel(
      idApplication: idApplication ?? this.idApplication,
      cvFile: cvFile ?? this.cvFile,
      motivationalMessage: motivationalMessage ?? this.motivationalMessage,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      userId: userId ?? this.userId,
      offerId: offerId ?? this.offerId,
    );
  }

  @override
  String toString() {
    return 'Application{id_application: $idApplication, offerId: $offerId, userId: $userId, status: $status}';
  }
}
