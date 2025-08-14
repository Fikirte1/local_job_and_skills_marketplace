import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

import 'coin_balance_widget.dart';
import 'coin_service.dart';

class PaymentStatusScreen extends StatefulWidget {
  final String requestId;

  const PaymentStatusScreen({super.key, required this.requestId});

  @override
  State<PaymentStatusScreen> createState() => _PaymentStatusScreenState();
}

class _PaymentStatusScreenState extends State<PaymentStatusScreen> {
  late Stream<DocumentSnapshot> _requestStream;
  final _dateFormat = DateFormat('MMM dd, yyyy - hh:mm a');

  @override
  void initState() {
    super.initState();
    _requestStream = FirebaseFirestore.instance
        .collection('coinRequests')
        .doc(widget.requestId)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment Status'),
        actions: const [
          CoinBalanceWidget(),
          SizedBox(width: 8),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: _requestStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Request not found'));
          }

          final request = snapshot.data!.data() as Map<String, dynamic>;
          final status = request['status'] ?? 'pending';
          final coins = request['coins'] ?? 0;
          final amountPaid = request['amountPaid'] ?? 0.0;
          final receiptUrl = request['receiptUrl'] ?? '';
          final requestDate = (request['requestDate'] as Timestamp?)?.toDate();
          final processedDate = (request['processedDate'] as Timestamp?)?.toDate();
          final rejectionReason = request['rejectionReason'] ?? '';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildStatusCard(status, rejectionReason),
                const SizedBox(height: 24),
                _buildRequestDetails(
                  coins: coins,
                  amount: amountPaid,
                  receiptUrl: receiptUrl,
                  requestDate: requestDate,
                  processedDate: processedDate,
                ),
                const SizedBox(height: 24),
                _buildActionButtons(status),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatusCard(String status, String rejectionReason) {
    Color backgroundColor;
    IconData icon;
    String statusText;
    String message;

    switch (status) {
      case 'approved':
        backgroundColor = Colors.green.shade50;
        icon = Icons.check_circle;
        statusText = 'Approved';
        message = 'Your coins have been added to your account';
        break;
      case 'rejected':
        backgroundColor = Colors.red.shade50;
        icon = Icons.error;
        statusText = 'Rejected';
        message = rejectionReason.isNotEmpty
            ? rejectionReason
            : 'Your payment request was rejected';
        break;
      default:
        backgroundColor = Colors.blue.shade50;
        icon = Icons.access_time;
        statusText = 'Pending';
        message = 'Your request is being reviewed by our team';
    }

    return Card(
      color: backgroundColor,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, size: 48, color: _getStatusColor(status)),
            const SizedBox(height: 16),
            Text(
              statusText,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: _getStatusColor(status),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: _getStatusColor(status)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRequestDetails({
    required int coins,
    required double amount,
    required String receiptUrl,
    required DateTime? requestDate,
    required DateTime? processedDate,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Request Details',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildDetailRow('Request ID', widget.requestId),
            _buildDetailRow('Coins Requested', '$coins'),
            _buildDetailRow('Amount Paid', '\$${amount.toStringAsFixed(2)}'),
            if (requestDate != null)
              _buildDetailRow('Request Date', _dateFormat.format(requestDate)),
            if (processedDate != null)
              _buildDetailRow('Processed Date', _dateFormat.format(processedDate)),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => _viewReceipt(receiptUrl),
              child: const Text('View Receipt'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 16)),
          Text(
            value,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(String status) {
    switch (status) {
      case 'approved':
        return Column(
          children: [
            const Text(
              'Thank you for your purchase! Your coins are now available for use.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Back to Home'),
            ),
          ],
        );
      case 'rejected':
        return Column(
          children: [
            const Text(
              'If you believe this was a mistake, please contact support with your receipt.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _contactSupport,
              child: const Text('Contact Support'),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Back to Home'),
            ),
          ],
        );
      default: // pending
        return Column(
          children: [
            const Text(
              'Your request is being reviewed by our team. '
                  'This usually takes 1-2 business days.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Back to Home'),
            ),
          ],
        );
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.blue;
    }
  }

  Future<void> _viewReceipt(String url) async {
    // Implement receipt viewing logic
    // Could be a dialog with the image or opening in a browser
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Payment Receipt'),
        content: Image.network(url),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _contactSupport() async {
    // Implement support contact logic
    final user = FirebaseAuth.instance.currentUser;
    final email = user?.email ?? 'No email';

    final uri = Uri(
      scheme: 'mailto',
      path: 'support@localjobs.com',
      queryParameters: {
        'subject': 'Coin Purchase Issue - Request ID: ${widget.requestId}',
        'body': 'Hello Support Team,\n\n'
            'I have an issue with my coin purchase (Request ID: ${widget.requestId}).\n\n'
            'User Email: $email\n'
            'Please assist with resolving this matter.\n\n'
            'Best regards,',
      },
    );

    try {
      // await launchUrl(uri); // Uncomment if you have url_launcher package
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please email support@localjobs.com')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not launch email client')),
      );
    }
  }
}