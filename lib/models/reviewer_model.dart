import 'package:cloud_firestore/cloud_firestore.dart';

class ReviewerModel {
  final String userId;
  final String name;
  final String email;
  final String? contactNumber;
  final DateTime? createdAt;

  ReviewerModel({
    required this.userId,
    required this.name,
    required this.email,
    required this.contactNumber,

    this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'name': name,
      'email': email,

      'createdAt': createdAt ?? FieldValue.serverTimestamp(),
    };
  }

  factory ReviewerModel.fromMap(Map<String, dynamic> map) {
    return ReviewerModel(
      userId: map['userId'],
      name: map['name'],
      email: map['email'],
      contactNumber: map['contactNumber'],

      createdAt: map['createdAt']?.toDate(),
    );
  }
}
