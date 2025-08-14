import 'package:cloud_firestore/cloud_firestore.dart';

class JobSeekerCoinBalance {
  final int balance;
  final int totalEarned;
  final int totalSpent;
  final DateTime? lastUpdated;

  JobSeekerCoinBalance({
    required this.balance,
    required this.totalEarned,
    required this.totalSpent,
    this.lastUpdated,
  });

  factory JobSeekerCoinBalance.fromMap(Map<String, dynamic> data) {
    return JobSeekerCoinBalance(
      balance: data['balance'] ?? 0,
      totalEarned: data['totalEarned'] ?? 0,
      totalSpent: data['totalSpent'] ?? 0,
      lastUpdated: (data['lastUpdated'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'balance': balance,
      'totalEarned': totalEarned,
      'totalSpent': totalSpent,
      'lastUpdated': lastUpdated,
    };
  }
}
