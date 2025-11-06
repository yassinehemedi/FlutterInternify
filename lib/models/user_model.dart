import 'package:internify/models/reclamation.dart';

class User {
  final int? id;
  final String name;
  final String email;
  final String password;
  final bool isVerified;
  final String? phone;
  final String? role;
  final List<Reclamation>? reclamations; // holds related reclamations

  User({
    this.id,
    required this.name,
    required this.email,
    required this.password,
    this.isVerified = false,
    this.phone,
    this.role,
    this.reclamations,
  });

  // Convert User to Map (for database)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'password': password,
      'isVerified': isVerified ? 1 : 0,
      'phone': phone,
      'role': role,
      // Do NOT include reclamations here; handled separately
    };
  }

  // Create User from Map (from database)
  factory User.fromMap(Map<String, dynamic> map, {List<Reclamation>? reclamations}) {
    return User(
      id: map['id'] as int?,
      name: map['name'],
      email: map['email'],
      password: map['password'],
      isVerified: map['isVerified'] == 1,
      phone: map['phone'],
      role: map['role'],
      reclamations: reclamations,
    );
  }

  // Copy User with updated fields
  User copyWith({
    int? id,
    String? name,
    String? email,
    String? password,
    bool? isVerified,
    String? phone,
    String? role,
    List<Reclamation>? reclamations,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      password: password ?? this.password,
      isVerified: isVerified ?? this.isVerified,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      reclamations: reclamations ?? this.reclamations,
    );
  }

  @override
  String toString() {
    return 'User{id: $id, name: $name, email: $email, isVerified: $isVerified, phone: $phone, reclamations: ${reclamations?.length ?? 0}}';
  }
}
