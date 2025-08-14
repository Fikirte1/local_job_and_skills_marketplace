import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';

import '../../models/job _seeker_models/job_seeker_model.dart';
import '../home/job_seeker_screens/coin_system/CoinRequest_model.dart';
import '../home/job_seeker_screens/coin_system/coin_service.dart';

class AdminCoinApprovalScreen extends StatefulWidget {
  const AdminCoinApprovalScreen({super.key});

  @override
  State<AdminCoinApprovalScreen> createState() => _AdminCoinApprovalScreenState();
}

class _AdminCoinApprovalScreenState extends State<AdminCoinApprovalScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String _filterStatus = 'pending';
  bool _isLoading = false;
  String? _errorMessage;
  final Map<String, JobSeeker> _jobSeekerCache = {};

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Coin Purchase Requests'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshData,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilterControls(),
          if (_errorMessage != null) _buildErrorBanner(),
          if (_isLoading) const LinearProgressIndicator(),
          Expanded(
            child: _buildRequestList(),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorBanner() {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
              style: TextStyle(color: Colors.red[800]),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 18),
            onPressed: () => setState(() => _errorMessage = null),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterControls() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              labelText: 'Search by Email',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  _searchController.clear();
                  setState(() => _searchQuery = '');
                },
              )
                  : null,
              border: const OutlineInputBorder(),
            ),
            onChanged: (value) => setState(() => _searchQuery = value.toLowerCase()),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Text('Filter by status:'),
              const SizedBox(width: 12),
              DropdownButton<String>(
                value: _filterStatus,
                items: const [
                  DropdownMenuItem(
                    value: 'pending',
                    child: Text('Pending'),
                  ),
                  DropdownMenuItem(
                    value: 'approved',
                    child: Text('Approved'),
                  ),
                  DropdownMenuItem(
                    value: 'rejected',
                    child: Text('Rejected'),
                  ),
                  DropdownMenuItem(
                    value: 'all',
                    child: Text('All'),
                  ),
                ],
                onChanged: (value) => setState(() => _filterStatus = value!),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRequestList() {
    Query query = FirebaseFirestore.instance
        .collection('coinRequests')
        .orderBy('requestDate', descending: true);

    if (_filterStatus != 'all') {
      query = query.where('status', isEqualTo: _filterStatus);
    }

    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting && !_isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No requests found'));
        }

        // Filter by search query if provided
        final filteredDocs = snapshot.data!.docs.where((doc) {
          if (_searchQuery.isEmpty) return true;

          final data = doc.data() as Map<String, dynamic>;
          final userId = data['userId'] ?? '';
          final jobSeeker = _jobSeekerCache[userId];
          final email = jobSeeker?.email?.toLowerCase() ?? '';

          return email.contains(_searchQuery);
        }).toList();

        if (filteredDocs.isEmpty) {
          return const Center(child: Text('No matching requests found'));
        }

        return ListView.builder(
          padding: const EdgeInsets.only(bottom: 16),
          itemCount: filteredDocs.length,
          itemBuilder: (context, index) {
            final requestDoc = filteredDocs[index];
            final request = CoinRequest.fromMap(
                requestDoc.data() as Map<String, dynamic>,
                requestDoc.id
            );

            return FutureBuilder<JobSeeker?>(
              future: _getJobSeeker(request.userId),
              builder: (context, seekerSnapshot) {
                if (seekerSnapshot.connectionState == ConnectionState.waiting) {
                  return _buildRequestCard(context, request, null);
                }

                return _buildRequestCard(context, request, seekerSnapshot.data);
              },
            );
          },
        );
      },
    );
  }

  Future<JobSeeker?> _getJobSeeker(String userId) async {
    if (_jobSeekerCache.containsKey(userId)) {
      return _jobSeekerCache[userId];
    }

    try {
      final doc = await FirebaseFirestore.instance
          .collection('jobSeekers') // Adjust collection name as needed
          .doc(userId)
          .get();

      if (doc.exists) {
        final jobSeeker = JobSeeker.fromMap(doc.data()!);
        _jobSeekerCache[userId] = jobSeeker;
        return jobSeeker;
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching job seeker: $e');
      return null;
    }
  }

  Widget _buildRequestCard(BuildContext context, CoinRequest request, JobSeeker? jobSeeker) {
    final dateFormat = DateFormat('MMM dd, yyyy - hh:mm a');

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (jobSeeker != null)
                      Text(
                        jobSeeker.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    Text(
                      jobSeeker?.email ?? 'User ID: ${request.userId}',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(request.status),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    request.status.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('Requested on: ${dateFormat.format(request.requestDate ?? DateTime.now())}'),
            if (request.processedDate != null)
              Text(
                'Processed on: ${dateFormat.format(request.processedDate!)}',
                style: const TextStyle(fontSize: 12),
              ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildDetailChip('Coins', '${request.coins}'),
                const SizedBox(width: 8),
                _buildDetailChip('Amount', '\$${request.amountPaid.toStringAsFixed(2)}'),
              ],
            ),
            const SizedBox(height: 12),
            if (request.receiptUrl.isNotEmpty)
              GestureDetector(
                onTap: () => _showReceiptDialog(context, request.receiptUrl),
                child: Container(
                  height: 120,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: CachedNetworkImage(
                      imageUrl: request.receiptUrl,
                      placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                      errorWidget: (context, url, error) => const Center(child: Icon(Icons.receipt)),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 12),
            if (request.status == 'pending')
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                    ),
                    onPressed: () => _showRejectDialog(context, request),
                    child: const Text('Reject'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                    ),
                    onPressed: () => _approveRequest(context, request),
                    child: const Text('Approve'),
                  ),
                ],
              ),
            if (request.status == 'rejected' && request.rejectionReason != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  Text(
                    'Rejection Reason: ${request.rejectionReason}',
                    style: TextStyle(color: Colors.red[700]),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailChip(String label, String value) {
    return Chip(
      backgroundColor: Colors.grey[200],
      labelPadding: const EdgeInsets.symmetric(horizontal: 8),
      label: Text(
        '$label: $value',
        style: const TextStyle(fontSize: 14),
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

  Future<void> _refreshData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Clear cache to force fresh data
      _jobSeekerCache.clear();
      setState(() => _isLoading = false);
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to refresh: ${e.toString()}';
      });
    }
  }

  Future<void> _approveRequest(BuildContext context, CoinRequest request) async {
    final adminId = FirebaseAuth.instance.currentUser?.uid ?? 'admin';
    bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Approval'),
        content: Text(
          'Are you sure you want to approve this request for ${request.coins} coins?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Approve'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);

    try {
      // Add coins to user's balance
      final success = await CoinService.addCoins(
        userId: request.userId,
        amount: request.coins,
        adminId: adminId,
        note: 'Approved purchase request #${request.id}',
      );

      if (!success) throw Exception('Failed to add coins');

      // Update request status
      await FirebaseFirestore.instance
          .collection('coinRequests')
          .doc(request.id)
          .update({
        'status': 'approved',
        'processedBy': adminId,
        'processedDate': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Successfully approved ${request.coins} coins'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = 'Error approving request: ${e.toString()}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _showRejectDialog(BuildContext context, CoinRequest request) async {
    final reasonController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Request'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Please provide a reason for rejection:'),
              const SizedBox(height: 12),
              TextFormField(
                controller: reasonController,
                decoration: const InputDecoration(
                  labelText: 'Reason',
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                value?.isEmpty ?? true ? 'Please enter a reason' : null,
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              if (formKey.currentState?.validate() ?? false) {
                Navigator.pop(context);
                await _rejectRequest(context, request, reasonController.text);
              }
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }

  Future<void> _rejectRequest(
      BuildContext context, CoinRequest request, String reason) async {
    setState(() => _isLoading = true);

    try {
      await FirebaseFirestore.instance
          .collection('coinRequests')
          .doc(request.id)
          .update({
        'status': 'rejected',
        'processedBy': FirebaseAuth.instance.currentUser?.uid ?? 'admin',
        'processedDate': FieldValue.serverTimestamp(),
        'rejectionReason': reason,
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Request rejected'),
          backgroundColor: Colors.orange,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = 'Error rejecting request: ${e.toString()}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showReceiptDialog(BuildContext context, String receiptUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.all(20),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Payment Receipt',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Expanded(
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
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}