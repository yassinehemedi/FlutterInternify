class Enterprise {
  final int? id;
  final int userId; // foreign key to User
  final String companyName;
  final String companyDescription;

  const Enterprise({
    this.id,
    required this.userId,
    required this.companyName,
    required this.companyDescription,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'companyName': companyName,
      'companyDescription': companyDescription,
    };
  }

  factory Enterprise.fromMap(Map<String, dynamic> map) {
    return Enterprise(
      id: map['id'],
      userId: map['userId'],
      companyName: map['companyName'] != null ? map['companyName'] as String : '',
      companyDescription: map['companyDescription'] != null ? map['companyDescription'] as String : '',
    );
  }
}
