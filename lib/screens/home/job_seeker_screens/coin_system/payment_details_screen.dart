import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:local_job_and_skills_marketplace/screens/home/job_seeker_screens/coin_system/payment_status_screen.dart';

import 'coin_balance_widget.dart';
import 'coin_service.dart';

class PaymentDetailsScreen extends StatefulWidget {
  final int coins;
  final int bonus;
  final double price;

  const PaymentDetailsScreen({
    super.key,
    required this.coins,
    required this.bonus,
    required this.price,
  });

  @override
  State<PaymentDetailsScreen> createState() => _PaymentDetailsScreenState();
}

class _PaymentDetailsScreenState extends State<PaymentDetailsScreen> {
  final ImagePicker _picker = ImagePicker();
  File? _receiptImage;
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment Details'),
        actions: const [
          CoinBalanceWidget(),
          SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_errorMessage != null) _buildErrorBanner(),
            _buildPackageInfo(),
            const SizedBox(height: 24),
            _buildPaymentInstructions(),
            const SizedBox(height: 24),
            _buildReceiptUpload(),
            const SizedBox(height: 24),
            _buildSubmitButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorBanner() {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red[200]!),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.red),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
                _errorMessage!,
                style: TextStyle(color: Colors.red[800])),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 18),
            onPressed: () => setState(() => _errorMessage = null),
          ),
        ],
      ),
    );
  }

  Widget _buildPackageInfo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Package Details',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildDetailRow('Base Coins', '${widget.coins}'),
            if (widget.bonus > 0) _buildDetailRow('Bonus Coins', '+${widget.bonus}'),
            _buildDetailRow('Total Coins', '${widget.coins + widget.bonus}'),
            _buildDetailRow('Amount to Pay', '\$${widget.price.toStringAsFixed(2)}'),
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
          Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildPaymentInstructions() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Payment Instructions',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text('Please transfer the exact amount to:'),
            const SizedBox(height: 8),
            const Text(
              'Bank: XYZ Bank\n'
                  'Account: 123456789\n'
                  'Name: Local Jobs Marketplace\n'
                  'Reference: Your User ID',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text('After payment, upload the receipt screenshot below.'),
          ],
        ),
      ),
    );
  }

  Widget _buildReceiptUpload() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Upload Receipt',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            if (_receiptImage == null)
              ElevatedButton(
                onPressed: _pickReceiptImage,
                child: const Text('Select Receipt Image'),
              )
            else
              Column(
                children: [
                  Image.file(_receiptImage!, height: 200),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      ElevatedButton(
                        onPressed: _pickReceiptImage,
                        child: const Text('Change Image'),
                      ),
                      const SizedBox(width: 12),
                      TextButton(
                        onPressed: () => setState(() => _receiptImage = null),
                        child: const Text('Remove'),
                      ),
                    ],
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _receiptImage == null || _isSubmitting ? null : _submitRequest,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        child: _isSubmitting
            ? const CircularProgressIndicator(color: Colors.white)
            : const Text('Submit Payment Request', style: TextStyle(fontSize: 16)),
      ),
    );
  }

  Future<void> _pickReceiptImage() async {
    try {
      final pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1000,
        maxHeight: 1000,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _receiptImage = File(pickedFile.path);
          _errorMessage = null;
        });
      }
    } catch (e) {
      setState(() => _errorMessage = 'Failed to select image: ${e.toString()}');
    }
  }

  Future<void> _submitRequest() async {
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final requestId = await CoinService.submitPurchaseRequest(
        userId: userId,
        coins: widget.coins + widget.bonus,
        receiptImage: _receiptImage!,
        amountPaid: widget.price,
      );

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => PaymentStatusScreen(requestId: requestId),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _errorMessage = 'Failed to submit request: ${e.toString()}';
        });
      }
    }
  }
}