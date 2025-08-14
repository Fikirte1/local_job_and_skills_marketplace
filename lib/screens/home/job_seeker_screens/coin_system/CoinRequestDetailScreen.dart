import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';

import 'CoinRequest_model.dart';

class CoinRequestDetailScreen extends StatelessWidget {
  final CoinRequest request;

  const CoinRequestDetailScreen({super.key, required this.request});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM dd, yyyy - hh:mm a');
    final statusColor = _getStatusColor(request.status);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Request Details'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailSection(
              title: 'Transaction Summary',
              children: [
                _buildDetailRow('Status', request.status.toUpperCase(),
                    valueColor: statusColor),
                _buildDetailRow('Coins Purchased', '${request.coins}'),
                _buildDetailRow('Amount Paid',
                    '\$${request.amountPaid.toStringAsFixed(2)}'),
              ],
            ),
            _buildDetailSection(
              title: 'Timeline',
              children: [
                _buildDetailRow('Request Date',
                    dateFormat.format(request.requestDate ?? DateTime.now())),
                if (request.processedDate != null)
                  _buildDetailRow(
                    'Processed Date',
                    dateFormat.format(request.processedDate!),
                  ),
              ],
            ),
            if (request.receiptUrl.isNotEmpty)
              _buildDetailSection(
                title: 'Payment Receipt',
                children: [
                  GestureDetector(
                    onTap: () => _showFullReceipt(context, request.receiptUrl),
                    child: Container(
                      height: 200,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: CachedNetworkImage(
                          imageUrl: request.receiptUrl,
                          placeholder: (context, url) =>
                          const Center(child: CircularProgressIndicator()),
                          errorWidget: (context, url, error) =>
                          const Icon(Icons.receipt, size: 50),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            if (request.status == 'rejected' && request.rejectionReason != null)
              _buildDetailSection(
                title: 'Rejection Details',
                children: [
                  _buildDetailRow(
                    'Reason',
                    request.rejectionReason!,
                    valueColor: Colors.red,
                  ),
                  if (request.processedBy != null)
                    _buildDetailRow('Processed By', request.processedBy!),
                ],
              ),
           /* if (request.status == 'approved' && request.processedBy != null)
              _buildDetailSection(
                title: 'Approval Details',
                children: [
                  _buildDetailRow('Processed By', request.processedBy!),
                ],
              ),*/
          ],
        ),
      ),
    );
  }

  Widget _buildDetailSection({
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: children,
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildDetailRow(
      String label,
      String value, {
        Color? valueColor,
      }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 16),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }

  void _showFullReceipt(BuildContext context, String receiptUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: InteractiveViewer(
          panEnabled: true,
          boundaryMargin: const EdgeInsets.all(20),
          minScale: 0.5,
          maxScale: 3,
          child: CachedNetworkImage(
            imageUrl: receiptUrl,
            placeholder: (context, url) =>
            const Center(child: CircularProgressIndicator()),
            errorWidget: (context, url, error) =>
            const Icon(Icons.error, size: 50),
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'pending':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }
}