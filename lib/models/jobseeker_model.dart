class JobSeeker {
  final int? id;
  final int userId; // foreign key to User
  final String resumeUrl;
  final String cvDescription;

  const JobSeeker({
    this.id,
    required this.userId,
    required this.resumeUrl,
    required this.cvDescription,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'resumeUrl': resumeUrl,
      'cvDescription': cvDescription,
    };
  }

  factory JobSeeker.fromMap(Map<String, dynamic> map) {
    return JobSeeker(
      id: map['id'],
      userId: map['userId'],
      resumeUrl: map['resumeUrl'] != null ? map['resumeUrl'] as String : '',
      cvDescription: map['cvDescription'] != null
          ? map['cvDescription'] as String
          : '',
    );
  }
}
