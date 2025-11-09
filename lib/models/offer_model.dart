class Offer {
  final int? idOffer;
  final String title;
  final String? description;
  final String? image; // URL or local path
  final String? category;
  final DateTime? expiresAt;
  final DateTime createdAt;
  final int userId;

  Offer({
    this.idOffer,
    required this.title,
    this.description,
    this.image,
    this.category,
    this.expiresAt,
    DateTime? createdAt,
    required this.userId,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id_offer': idOffer,
      'title': title,
      'description': description,
      'image': image,
      'category': category,
      'expiresAt': expiresAt?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'userId': userId,
    };
  }

  factory Offer.fromMap(Map<String, dynamic> map) {
    return Offer(
      idOffer: map['id_offer'] as int?,
      title: map['title'] as String,
      description: map['description'] as String?,
      image: map['image'] as String?,
      category: map['category'] as String?,
      expiresAt: map['expiresAt'] != null
          ? DateTime.parse(map['expiresAt'] as String)
          : null,
      createdAt: DateTime.parse(map['createdAt'] as String),
      userId: map['userId'] as int,
    );
  }

  Offer copyWith({
    int? idOffer,
    String? title,
    String? description,
    String? image,
    String? category,
    DateTime? createdAt,
    DateTime? expiresAt,
    int? userId,
  }) {
    return Offer(
      idOffer: idOffer ?? this.idOffer,
      title: title ?? this.title,
      description: description ?? this.description,
      image: image ?? this.image,
      category: category ?? this.category,
      expiresAt: expiresAt ?? this.expiresAt,
      createdAt: createdAt ?? this.createdAt,
      userId: userId ?? this.userId,
    );
  }

  @override
  String toString() {
    return 'Offer{id_offer: $idOffer, title: $title, category: $category, userId: $userId}';
  }
}
