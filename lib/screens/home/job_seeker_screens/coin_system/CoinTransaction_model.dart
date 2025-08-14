import 'package:cloud_firestore/cloud_firestore.dart';

class CoinTransaction {
  final String id;
  final String userId;
  final int amount;
  final String type; // 'purchase', 'application', 'admin_add'
  final DateTime timestamp;
  final String? note;
  final String? receiptUrl;
  final String? jobId; // For application deductions

  CoinTransaction({
    required this.id,
    required this.userId,
    required this.amount,
    required this.type,
    required this.timestamp,
    this.note,
    this.receiptUrl,
    this.jobId,
  });

  factory CoinTransaction.fromMap(Map<String, dynamic> map) {
    return CoinTransaction(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      amount: map['amount'] ?? 0,
      type: map['type'] ?? '',
      timestamp: (map['timestamp'] as Timestamp).toDate(),
      note: map['note'],
      receiptUrl: map['receiptUrl'],
      jobId: map['jobId'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'amount': amount,
      'type': type,
      'timestamp': Timestamp.fromDate(timestamp),
      'note': note,
      'receiptUrl': receiptUrl,
      'jobId': jobId,
    };
  }
}