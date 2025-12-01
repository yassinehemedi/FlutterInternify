import 'dart:convert';

class ParsedCv {
  final int? id;
  final int demandId;
  final Map<String, dynamic> parsedJson;
  final String? contactEmail;
  final String? contactPhone;
  final List<String>? technicalSkills;
  final List<String>? nonTechnicalSkills;
  final String? summary;
  final DateTime parsedAt;
  final int? parsedBy;
  final bool verified;

  ParsedCv({this.id, required this.demandId, required this.parsedJson, this.contactEmail, this.contactPhone, this.technicalSkills, this.nonTechnicalSkills, this.summary, DateTime? parsedAt, this.parsedBy, this.verified = false}) : parsedAt = parsedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'demandId': demandId,
      'parsedJson': jsonEncode(parsedJson),
      'contactEmail': contactEmail,
      'contactPhone': contactPhone,
      'technicalSkills': technicalSkills == null ? null : jsonEncode(technicalSkills),
      'nonTechnicalSkills': nonTechnicalSkills == null ? null : jsonEncode(nonTechnicalSkills),
      'summary': summary,
      'parsedAt': parsedAt.toIso8601String(),
      'parsedBy': parsedBy,
      'verified': verified ? 1 : 0,
    };
  }

  factory ParsedCv.fromMap(Map<String, dynamic> map) {
    return ParsedCv(
      id: map['id'] as int?,
      demandId: map['demandId'] as int,
      parsedJson: map['parsedJson'] != null ? jsonDecode(map['parsedJson']) as Map<String, dynamic> : <String, dynamic>{},
      contactEmail: map['contactEmail'] as String?,
      contactPhone: map['contactPhone'] as String?,
      technicalSkills: map['technicalSkills'] != null ? List<String>.from(jsonDecode(map['technicalSkills']) as List) : null,
      nonTechnicalSkills: map['nonTechnicalSkills'] != null ? List<String>.from(jsonDecode(map['nonTechnicalSkills']) as List) : null,
      summary: map['summary'] as String?,
      parsedAt: map['parsedAt'] != null ? DateTime.parse(map['parsedAt'] as String) : DateTime.now(),
      parsedBy: map['parsedBy'] as int?,
      verified: (map['verified'] as int?) == 1,
    );
  }
}

