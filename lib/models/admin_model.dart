// models/admin_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminModel {
  final String userId;
  final String name;
  final String email;
  final String? contactNumber;
  final DateTime? createdAt;
  final bool isSuperAdmin;

  AdminModel({
    required this.userId,
    required this.name,
    required this.email,
    this.contactNumber,
    this.createdAt,
    this.isSuperAdmin = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'name': name,
      'email': email,
      'contactNumber': contactNumber,
      'isSuperAdmin': isSuperAdmin,
      'createdAt': createdAt ?? FieldValue.serverTimestamp(),
    };
  }

  factory AdminModel.fromMap(Map<String, dynamic> map) {
    return AdminModel(
      userId: map['userId'],
      name: map['name'],
      email: map['email'],
      contactNumber: map['contactNumber'],
      isSuperAdmin: map['isSuperAdmin'] ?? false,
      createdAt: map['createdAt']?.toDate(),
    );
  }
}