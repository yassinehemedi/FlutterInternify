class Contract {
  final int? id;
  final String? title;
  final int jobSeekerId;
  final int enterpriseId;
  final String startDate;
  final String endDate;
  final String status;
  final String? description;
  final String? contractType;
  final String pdfPath;
  final String? signaturePath;

  Contract({
    this.id,
    this.title,
    required this.jobSeekerId,
    required this.enterpriseId,
    required this.startDate,
    required this.endDate,
    this.status = 'Pending',
    this.description,
    this.contractType,
    required this.pdfPath,
    this.signaturePath,
  });

  // Convert Contract object to Map for database insertion
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'jobSeekerId': jobSeekerId,
      'enterpriseId': enterpriseId,
      'startDate': startDate,
      'endDate': endDate,
      'status': status,
      'description': description,
      'contractType': contractType,
      'pdfPath': pdfPath,
      'signaturePath': signaturePath,
    };
  }

  // Create Contract object from Map (database query result)
  factory Contract.fromMap(Map<String, dynamic> map) {
    return Contract(
      id: map['id'] as int?,
      title: map['title'] as String?,
      jobSeekerId: map['jobSeekerId'] as int,
      enterpriseId: map['enterpriseId'] as int,
      startDate: map['startDate'] as String,
      endDate: map['endDate'] as String,
      status: map['status'] as String? ?? 'Pending',
      description: map['description'] as String?,
      contractType: map['contractType'] as String?,
      pdfPath: map['pdfPath'] as String,
      signaturePath: map['signaturePath'] as String?,
    );
  }

  // Create a copy of Contract with modified fields
  Contract copyWith({
    int? id,
    String? title,
    int? jobSeekerId,
    int? enterpriseId,
    String? startDate,
    String? endDate,
    String? status,
    String? description,
    String? contractType,
    String? pdfPath,
    String? signaturePath,
  }) {
    return Contract(
      id: id ?? this.id,
      title: title ?? this.title,
      jobSeekerId: jobSeekerId ?? this.jobSeekerId,
      enterpriseId: enterpriseId ?? this.enterpriseId,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      status: status ?? this.status,
      description: description ?? this.description,
      contractType: contractType ?? this.contractType,
      pdfPath: pdfPath ?? this.pdfPath,
      signaturePath: signaturePath ?? this.signaturePath,
    );
  }
}