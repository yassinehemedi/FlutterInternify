// filepath: lib/models/internship_demand.dart
// InternshipDemand model - mirrors the Reclamation model style
import 'dart:convert';

class InternshipDemand {
  final int? id;
  final String title;
  final String description;
  final String duration; // e.g. "1 month", "3 months"
  final String? companyPreference;
  final int? companyId; // company that receives this demand (nullable)
  final String? domain; // domaine de stage
  final String status; // e.g. "En cours", "Terminé"
  final int userId;
  final DateTime createdAt;
  final DateTime? updatedAt;

  // Attachments stored as file paths (JSON encoded in DB)
  final List<String>? attachments;
  // Feedback/comments from company when accepting/rejecting
  final String? feedback;

  InternshipDemand({
    this.id,
    required this.title,
    required this.description,
    required this.duration,
    this.companyPreference,
    this.companyId,
    this.domain,
    required this.status,
    required this.userId,
    required this.createdAt,
    this.updatedAt,
    this.attachments,
    this.feedback,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'duration': duration,
      'companyPreference': companyPreference,
      'companyId': companyId,
      'domain': domain,
      'status': status,
      'userId': userId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'attachments': attachments == null ? null : jsonEncode(attachments),
      'feedback': feedback,
    };
  }

  factory InternshipDemand.fromMap(Map<String, dynamic> map) {
    return InternshipDemand(
      id: map['id'] as int?,
      title: map['title'] as String,
      description: map['description'] as String,
      duration: map['duration'] as String,
      companyPreference: map['companyPreference'] as String?,
      companyId: map['companyId'] is int ? map['companyId'] as int : (map['companyId'] != null ? int.tryParse(map['companyId'].toString()) : null),
      domain: map['domain'] as String?,
      status: map['status'] as String,
      userId: map['userId'] as int,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: map['updatedAt'] == null ? null : DateTime.tryParse(map['updatedAt'] as String),
      attachments: map['attachments'] == null ? null : List<String>.from(jsonDecode(map['attachments'] as String)),
      feedback: map['feedback'] as String?,
    );
  }
}
