import 'package:cloud_firestore/cloud_firestore.dart';

class CoinRequest {
  final String id;
  final String userId;
  final int coins;
  final double amountPaid;
  final String receiptUrl;
  final String status; // e.g. 'pending', 'approved', 'rejected'
  final DateTime? requestDate;
  final DateTime? processedDate;
  final String? processedBy;
  final String? rejectionReason;

  CoinRequest({
    required this.id,
    required this.userId,
    required this.coins,
    required this.amountPaid,
    required this.receiptUrl,
    required this.status,
    this.requestDate,
    this.processedDate,
    this.processedBy,
    this.rejectionReason,
  });

  factory CoinRequest.fromMap(Map<String, dynamic> data, String docId) {
    return CoinRequest(
      id: docId,
      userId: data['userId'] ?? '',
      coins: data['coins'] ?? 0,
      amountPaid: (data['amountPaid'] ?? 0).toDouble(),
      receiptUrl: data['receiptUrl'] ?? '',
      status: data['status'] ?? 'pending',
      requestDate: (data['requestDate'] as Timestamp?)?.toDate(),
      processedDate: (data['processedDate'] as Timestamp?)?.toDate(),
      processedBy: data['processedBy'],
      rejectionReason: data['rejectionReason'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'coins': coins,
      'amountPaid': amountPaid,
      'receiptUrl': receiptUrl,
      'status': status,
      'requestDate': requestDate,
      'processedDate': processedDate,
      'processedBy': processedBy,
      'rejectionReason': rejectionReason,
    };
  }
}
