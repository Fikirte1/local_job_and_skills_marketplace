import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

import 'CoinTransaction_model.dart';

class CoinService {
  static const int initialCoins = 5;
  static const String balanceCollection = 'jobSeekerCoins';
  static const String transactionsCollection = 'coinTransactions';
  static const String requestsCollection = 'coinRequests';

  // Check if user has enough coins to apply
  static Future<bool> canApplyForJob(String userId) async {
    try {
      final balance = await getCoinBalance(userId);
      return balance > 0;
    } catch (e) {
      print('Error checking coins: $e');
      return false;
    }
  }

  // Initialize user's coins (called on first registration)
  static Future<void> initializeUserCoins(String userId) async {
    try {
      final batch = FirebaseFirestore.instance.batch();

      // Set initial balance
      final balanceRef = FirebaseFirestore.instance
          .collection(balanceCollection)
          .doc(userId);

      batch.set(balanceRef, {
        'balance': initialCoins,
        'lastUpdated': FieldValue.serverTimestamp(),
        'totalEarned': initialCoins,
        'totalSpent': 0,
      });

      // Create initial transaction record
      final transactionRef = FirebaseFirestore.instance
          .collection(transactionsCollection)
          .doc();

      batch.set(transactionRef, {
        'id': transactionRef.id,
        'userId': userId,
        'amount': initialCoins,
        'type': 'initial',
        'timestamp': FieldValue.serverTimestamp(),
        'note': 'Initial signup bonus',
      });

      await batch.commit();
    } catch (e) {
      print('Error initializing coins: $e');
      rethrow;
    }
  }

  // Deduct coins for job application
  static Future<bool> deductCoin({
    required String userId,
    required int amount,
    required String type,
    String? jobId,
  }) async {
    try {
      final transactionRef = FirebaseFirestore.instance
          .collection(transactionsCollection)
          .doc();

      final batch = FirebaseFirestore.instance.batch();

      // Update balance
      final balanceRef = FirebaseFirestore.instance
          .collection(balanceCollection)
          .doc(userId);

      batch.update(balanceRef, {
        'balance': FieldValue.increment(-amount),
        'lastUpdated': FieldValue.serverTimestamp(),
        'totalSpent': FieldValue.increment(amount),
      });

      // Record transaction
      batch.set(transactionRef, {
        'id': transactionRef.id,
        'userId': userId,
        'amount': -amount,
        'type': type,
        'timestamp': FieldValue.serverTimestamp(),
        'jobId': jobId,
      });

      await batch.commit();
      return true;
    } catch (e) {
      print('Error deducting coin: $e');
      return false;
    }
  }

  // Get current coin balance
  static Future<int> getCoinBalance(String userId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection(balanceCollection)
          .doc(userId)
          .get();

      if (!doc.exists) {
        await initializeUserCoins(userId);
        return initialCoins;
      }

      return doc.data()?['balance'] ?? 0;
    } catch (e) {
      print('Error getting coin balance: $e');
      return 0;
    }
  }

  // Admin function to add coins
  static Future<bool> addCoins({
    required String userId,
    required int amount,
    required String adminId,
    String? note,
  }) async {
    try {
      final transactionRef = FirebaseFirestore.instance
          .collection(transactionsCollection)
          .doc();

      final batch = FirebaseFirestore.instance.batch();

      // Update balance
      final balanceRef = FirebaseFirestore.instance
          .collection(balanceCollection)
          .doc(userId);

      batch.update(balanceRef, {
        'balance': FieldValue.increment(amount),
        'lastUpdated': FieldValue.serverTimestamp(),
        'totalEarned': FieldValue.increment(amount),
      });

      // Record transaction
      batch.set(transactionRef, {
        'id': transactionRef.id,
        'userId': userId,
        'amount': amount,
        'type': 'admin_add',
        'timestamp': FieldValue.serverTimestamp(),
        'note': note ?? 'Admin added coins',
        'adminId': adminId,
      });

      await batch.commit();
      return true;
    } catch (e) {
      print('Error adding coins: $e');
      return false;
    }
  }

  // Submit coin purchase request with receipt
  static Future<String> submitPurchaseRequest({
    required String userId,
    required int coins,
    required File receiptImage,
    required double amountPaid,
  }) async {
    try {
      // Upload receipt to storage
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('coin_receipts/$userId/${DateTime.now().millisecondsSinceEpoch}.jpg');

      final uploadTask = storageRef.putFile(receiptImage);
      final snapshot = await uploadTask.whenComplete(() {});
      final receiptUrl = await snapshot.ref.getDownloadURL();

      // Create purchase request
      final docRef = await FirebaseFirestore.instance
          .collection('coinRequests')
          .add({
        'userId': userId,
        'coins': coins,
        'amountPaid': amountPaid,
        'receiptUrl': receiptUrl,
        'status': 'pending',
        'requestDate': FieldValue.serverTimestamp(),
        'processedDate': null,
        'processedBy': null,
        'rejectionReason': null,
      });

      return docRef.id;
    } catch (e) {
      print('Error submitting purchase request: $e');
      rethrow;
    }
  }


  // Get coin transaction history
  static Stream<List<CoinTransaction>> getTransactionHistory(String userId) {
    return FirebaseFirestore.instance
        .collection(transactionsCollection)
        .where('userId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => CoinTransaction.fromMap(doc.data()))
        .toList());
  }
}