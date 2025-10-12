// ==================== RECLAMATION ENTITY ====================
// File: models/reclamation.dart

class Reclamation {
  final int? id;              // Primary key (nullable before saving)
  final String title;         // Short title or subject
  final String description;   // Detailed message or complaint
  final String category;      // e.g., "Technical", "Service", "Payment"
  final String status;        // e.g., "Pending", "Resolved"
  final int userId;        // ID of the user who made it
  final DateTime createdAt;   // Timestamp when created

  Reclamation({
    this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.status,
    required this.userId,
    required this.createdAt,
  });

  // Convert Reclamation → Map (for SQLite or API)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category': category,
      'status': status,
      'userId': userId,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  // Convert Map → Reclamation (for reading from DB)
  factory Reclamation.fromMap(Map<String, dynamic> map) {
    return Reclamation(
      id: map['id'],
      title: map['title'],
      description: map['description'],
      category: map['category'],
      status: map['status'],
      userId: map['userId'],
      createdAt: DateTime.parse(map['createdAt']),
    );
  }
}
