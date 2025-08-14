import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../models/employer_model/employer_model.dart';
import '../../../models/job_model.dart';
import 'add_job_screen.dart';
import 'employer_profile_edit_screens/employer_profile_screen.dart';
import 'new_application_interview/employer_applications_screen.dart';

class JobListScreen extends StatefulWidget {
  const JobListScreen({Key? key}) : super(key: key);

  @override
  State<JobListScreen> createState() => _JobListScreenState();
}

class _JobListScreenState extends State<JobListScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  Employer? _currentEmployer;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    await _fetchCurrentEmployer();
  }

  Future<void> _fetchCurrentEmployer() async {
    setState(() => _isLoading = true);
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return;

      final doc = await _firestore.collection('employers').doc(userId).get();
      if (doc.exists) {
        setState(() => _currentEmployer = Employer.fromMap(doc.data()!));
      }
    } catch (e) {
      _showSnackBar('Failed to load employer data: ${e.toString()}',
          isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<List<JobModel>> _fetchJobs() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) throw Exception("User not authenticated");

      final querySnapshot = await _firestore
          .collection('jobs')
          .where('employerId', isEqualTo: userId)
          .orderBy('datePosted', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => JobModel.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      throw Exception("Failed to fetch jobs: ${e.toString()}");
    }
  }

  Future<void> _updateJobStatus({
    required String jobId,
    String? reviewStatus,
    String? postStatus,
    String? jobStatus,
  }) async {
    try {
      final updateData = <String, dynamic>{};
      if (reviewStatus != null) updateData['reviewStatus'] = reviewStatus;
      if (postStatus != null) updateData['postStatus'] = postStatus;
      if (jobStatus != null) updateData['status'] = jobStatus;

      await _firestore.collection('jobs').doc(jobId).update(updateData);
      _showSnackBar("Job updated successfully!");
      setState(() {});
    } catch (e) {
      _showSnackBar("Failed to update job: ${e.toString()}", isError: true);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _navigateToAddJob({String? jobId}) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddJobScreen(jobId: jobId),
      ),
    );
    setState(() {});
  }

  void _navigateToApplications(String jobId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EmployerApplicationsScreen(jobId: jobId),
      ),
    );
  }

  void _navigateToVerification() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => EmployerProfileScreen()),
    );
  }

  void _handleSendForReview(JobModel job) {
    if (_currentEmployer?.isVerified != true) {
      _showVerificationDialog();
    } else {
      _updateJobStatus(jobId: job.jobId, reviewStatus: 'Under Review');
    }
  }

  void _showVerificationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Verification Required"),
        content: const Text(
            "You need to verify your identity before submitting jobs for review."),
        actions: [
          TextButton(
            onPressed: Navigator.of(context).pop,
            child: const Text("Later"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _navigateToVerification();
            },
            child: const Text("Verify Now"),
          ),
        ],
      ),
    );
  }

  void _showRejectionDetails(String? reviewMessage) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Rejection Details"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Reason for Rejection:",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(reviewMessage ?? "No reason provided"),
          ],
        ),
        actions: [
          TextButton(
            onPressed: Navigator.of(context).pop,
            child: const Text("Close"),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.work_outline, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            "No Jobs Created Yet",
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.grey.shade600,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            "Tap the + button to create your first job",
            style: TextStyle(color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String label, String value) {
    final statusColor = _getStatusColor(value);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text("$label: ", style: const TextStyle(fontWeight: FontWeight.bold)),
        Chip(
          label: Text(value),
          backgroundColor: statusColor.withOpacity(0.1),
          labelStyle: TextStyle(color: statusColor),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(color: statusColor.withOpacity(0.3)),
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(String value) {
    switch (value.toLowerCase()) {
      case 'approved':
      case 'open':
      case 'posted':
        return Colors.green;
      case 'rejected':
      case 'closed':
        return Colors.red;
      case 'pending':
      case 'under review':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  Widget _buildJobItem(JobModel job) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => _navigateToApplications(job.jobId),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// Top row: Title & Menu
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      job.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  _buildJobMenu(job),
                ],
              ),
              const SizedBox(height: 8),

              /// Job description
              Text(
                job.description,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 16),

              /// Chips & status messages
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildStatusChip('Status', job.status),
                  _buildStatusChip('Approval', job.approvalStatus),
                  _buildStatusChip('Review', job.reviewStatus),
                  _buildStatusChip('Post', job.postStatus),
                ],
              ),

              const SizedBox(height: 12),

              /// Review messages
              if (job.reviewStatus == 'Rejected') ...[
                Text(
                  "Your job has been rejected. Please review the reason and update your listing.",
                  style: TextStyle(color: Colors.red.shade700),
                ),
                const SizedBox(height: 4),
                GestureDetector(
                  onTap: () => _showRejectionDetails(job.reviewMessage),
                  child: Text(
                    "View Rejection Reason",
                    style: TextStyle(
                      color: Colors.red.shade600,
                      decoration: TextDecoration.underline,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ] else if (job.reviewStatus == 'Under Review') ...[
                _buildInfoText("Your job is under review. Please wait for verification.", Colors.orange),
              ] else if (job.reviewStatus == 'Closed') ...[
                _buildInfoText("You’ve closed this job. It no longer accepts applications.", Colors.grey),
              ] else if (job.reviewStatus == 'Approved') ...[
                _buildInfoText("Your job has been approved. You can now post it and start hiring.", Colors.green),
              ] else if (job.reviewStatus == 'Hired') ...[
                _buildInfoText("You’ve hired for this job. It no longer accepts applications.", Colors.green),
              ] else if (job.reviewStatus == 'Not submitted') ...[
                _buildInfoText("Send this job for review before posting.", Colors.purple),
              ],
            ],
          ),
        ),
      ),
    );
  }
  Widget _buildInfoText(String text, Color color) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }


  Widget _buildJobMenu(JobModel job) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert),
      onSelected: (value) => _handleMenuSelection(value, job),
      itemBuilder: (context) => _buildMenuItems(job),
    );
  }

  List<PopupMenuEntry<String>> _buildMenuItems(JobModel job) {
    final items = <PopupMenuEntry<String>>[];

    if (job.approvalStatus != 'Approved') {
      items.add(const PopupMenuItem(
        value: 'edit',
        child: Text('Edit Job'),
      ));
    }

    if (job.reviewStatus == 'Not submitted' || job.reviewStatus == 'Rejected') {
      items.add(const PopupMenuItem(
        value: 'review',
        child: Text('Send for Review'),
      ));
    }

    if (job.reviewStatus == 'Approved' && job.approvalStatus == 'Approved') {
      if (job.postStatus == 'Draft') {
        items.add(const PopupMenuItem(
          value: 'post',
          child: Text('Post Job'),
        ));
      } else if (job.postStatus == 'Posted') {
        if (job.status == 'Open') {
          items.add(const PopupMenuItem(
            value: 'hired',
            child: Text('Mark as Hired'),
          ));
          items.add(const PopupMenuItem(
            value: 'closed',
            child: Text('Mark as Closed'),
          ));
        } else if (job.status == 'Hired') {
          items.add(const PopupMenuItem(
            value: 'closed',
            child: Text('Mark as Closed'),
          ));
          items.add(const PopupMenuItem(
            value: 'open',
            child: Text('Reopen Job'),
          ));
        } else if (job.status == 'Closed') {
          items.add(const PopupMenuItem(
            value: 'open',
            child: Text('Reopen Job'),
          ));
          items.add(const PopupMenuItem(
            value: 'hired',
            child: Text('Mark as Hired'),
          ));
        }
      }
    }

    return items;
  }

  void _handleMenuSelection(String value, JobModel job) {
    switch (value) {
      case 'edit':
        _navigateToAddJob(jobId: job.jobId);
        break;
      case 'review':
        _handleSendForReview(job);
        break;
      case 'post':
        if (job.reviewStatus == 'Approved' &&
            job.approvalStatus == 'Approved') {
          _updateJobStatus(
            jobId: job.jobId,
            postStatus: 'Posted',
            jobStatus: 'Open',
          );
        } else {
          _showSnackBar("Job must be approved before posting", isError: true);
        }
        break;
      case 'hired':
        _updateJobStatus(jobId: job.jobId, jobStatus: 'Hired');
        break;
      case 'closed':
        _updateJobStatus(jobId: job.jobId, jobStatus: 'Closed');
        break;
      case 'open':
        _updateJobStatus(jobId: job.jobId, jobStatus: 'Open');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("My Jobs", style: TextStyle(fontWeight: FontWeight.w600)),
        centerTitle: false,
        backgroundColor: Theme.of(context).colorScheme.background,
        foregroundColor: Theme.of(context).colorScheme.onBackground,
        elevation: 1,
        surfaceTintColor: Colors.transparent,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : FutureBuilder<List<JobModel>>(
        future: _fetchJobs(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text(
                "Error: ${snapshot.error}",
                style: TextStyle(color: Colors.red.shade700),
              ),
            );
          }

          final jobs = snapshot.data ?? [];
          return jobs.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
            onRefresh: () async => setState(() {}),
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              itemCount: jobs.length,
              itemBuilder: (_, i) => _buildJobItem(jobs[i]),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToAddJob(),
        label: const Text("Add Job"),
        icon: const Icon(Icons.add),
        backgroundColor: Theme.of(context).colorScheme.primary,
        elevation: 4,
      ),
    );
  }

}
