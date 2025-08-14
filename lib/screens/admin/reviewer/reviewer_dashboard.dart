import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:local_job_and_skills_marketplace/services/auth_service.dart';
import '../../../models/employer_model/employer_model.dart';
import '../../../models/job_model.dart';
import '../../../models/reviewer_model.dart';
import '../../auth/signIn_screen.dart';
import 'jobs_submitted_for_review_detailScreen.dart';

class ReviewerDashboard extends StatefulWidget {
  const ReviewerDashboard({super.key});

  @override
  State<ReviewerDashboard> createState() => _ReviewerDashboardState();
}

class _ReviewerDashboardState extends State<ReviewerDashboard> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final AuthService _authService = AuthService();
  final ValueNotifier<bool> _isRejecting = ValueNotifier<bool>(false);

  ReviewerModel? _currentReviewer;
  bool _isLoading = false;
  String _selectedFilter = 'Pending Review';
  final List<String> _filterOptions = ['Pending Review', 'Approved', 'Rejected'];

  @override
  void initState() {
    super.initState();
    _initializeReviewer();
  }

  @override
  void dispose() {
    _isRejecting.dispose();
    super.dispose();
  }
  Future<void> _logout() async {
    try {
      await _authService.logout();
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) =>  SignInScreen()),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error during logout: ${e.toString()}')),
      );
    }
  }

  Future<void> _initializeReviewer() async {
    setState(() => _isLoading = true);
    try {
      await _fetchReviewerData();
      if (_currentReviewer == null) {
        _showSnackBar("Reviewer data not found. Please contact support.", isError: true);
      }
    } catch (e) {
      _showSnackBar("Error loading reviewer data", isError: true);
      debugPrint("Error initializing reviewer: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchReviewerData() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      _showSnackBar("No user logged in", isError: true);
      return;
    }

    try {
      final doc = await _firestore.collection('reviewers').doc(userId).get();
      if (doc.exists) {
        setState(() {
          _currentReviewer = ReviewerModel.fromMap(doc.data()!);
        });
      }
    } catch (e) {
      debugPrint("Error fetching reviewer data: $e");
      rethrow;
    }
  }

  Future<List<JobModel>> _fetchJobsByStatus(String status) async {
    setState(() => _isLoading = true);
    try {
      Query query = _firestore.collection('jobs');

      if (status == 'Pending Review') {
        query = query
            .where('reviewStatus', isEqualTo: 'Under Review')
            .orderBy('datePosted', descending: true);
      } else {
        query = query
            .where('approvalStatus', isEqualTo: status)
            .where('reviewedBy', isEqualTo: _currentReviewer?.userId ?? '')
            .orderBy('reviewedAt', descending: true);
      }

      final querySnapshot = await query.limit(50).get();
      return querySnapshot.docs
          .map((doc) => JobModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    } catch (e) {
      debugPrint("Error fetching $status jobs: $e");
      _showSnackBar("Error loading $status jobs", isError: true);
      return [];
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<Employer> _fetchEmployerDetails(String employerId) async {
    try {
      final doc = await _firestore.collection('employers').doc(employerId).get();
      if (!doc.exists) {
        throw Exception('Employer not found');
      }
      return Employer.fromMap(doc.data()!);
    } catch (e) {
      debugPrint("Error fetching employer details: $e");
      rethrow;
    }
  }

  Future<void> _updateJobReviewStatus({
    required String jobId,
    required String reviewStatus,
    required String reviewMessage,
  }) async {
    if (_currentReviewer == null) {
      _showSnackBar("Reviewer privileges required", isError: true);
      return;
    }

    setState(() => _isLoading = true);
    try {
      await _firestore.collection('jobs').doc(jobId).update({
        'reviewStatus': reviewStatus == 'Approved' ? 'Approved' : 'Rejected',
        'reviewMessage': reviewMessage,
        'reviewedBy': _currentReviewer!.userId,
        'reviewedByName': _currentReviewer!.name,
        'approvalStatus': reviewStatus,
        'reviewedAt': FieldValue.serverTimestamp(),
      });

      // Notify employer
      final jobDoc = await _firestore.collection('jobs').doc(jobId).get();
      if (jobDoc.exists) {
        final job = JobModel.fromMap(jobDoc.data()!, jobId);
        await _firestore.collection('notifications').add({
          'userId': job.employerId,
          'title': 'Job ${reviewStatus.toLowerCase()}',
          'message': 'Your job "${job.title}" has been $reviewStatus by reviewer',
          'type': 'job_review',
          'jobId': jobId,
          'isRead': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
      _showSnackBar(
        "Job $reviewStatus!",
        isError: false,
        isApproved: reviewStatus == 'Approved',
      );
      setState(() {});
    } catch (e) {
      _showSnackBar("Failed to update: ${e.toString()}", isError: true);
      debugPrint("Update error: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message, {bool isError = false, bool isApproved = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError
              ? Colors.red
              : isApproved
              ? Colors.green
              : Colors.orange,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ));
    }

  void _showReviewDialog(JobModel job) {
    String? _selectedRejectionReason;
    final List<String> rejectionReasons = [
      'Incomplete job description',
      'Salary range not competitive',
      'Job requirements unclear',
      'Company information insufficient',
      'Other compliance issues'
    ];

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text("Review Job: ${job.title}"),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ValueListenableBuilder<bool>(
                      valueListenable: _isRejecting,
                      builder: (context, isRejecting, child) {
                        return isRejecting
                            ? Column(
                          children: [
                            const Text(
                              "Select rejection reason:",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            DropdownButtonFormField<String>(
                              value: _selectedRejectionReason,
                              items: rejectionReasons.map((reason) {
                                return DropdownMenuItem(
                                  value: reason,
                                  child: Text(reason),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  _selectedRejectionReason = value;
                                });
                              },
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                              ),
                              validator: (value) {
                                if (isRejecting && (value == null || value.isEmpty)) {
                                  return 'Please select a reason';
                                }
                                return null;
                              },
                            ),
                          ],
                        )
                            : const SizedBox();
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  onPressed: () {
                    _isRejecting.value = false;
                    Navigator.pop(context);
                    _updateJobReviewStatus(
                      jobId: job.jobId,
                      reviewStatus: 'Approved',
                      reviewMessage:
                      "Congratulations! Your job posting has been approved, now you can post it",
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                  child: const Text("Approve"),
                ),
                ElevatedButton(
                  onPressed: () {
                    _isRejecting.value = true;
                    if (_selectedRejectionReason == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text("Please select a rejection reason")),
                      );
                      return;
                    }
                    Navigator.pop(context);
                    _updateJobReviewStatus(
                      jobId: job.jobId,
                      reviewStatus: 'Rejected',
                      reviewMessage: _selectedRejectionReason!,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                  child: const Text("Reject"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildJobCard(JobModel job) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => JobsSubmittedForReviewDetailScreen(job: job),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.indigo.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    alignment: Alignment.center,
                    child: const Icon(Icons.work, color: Colors.indigo),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          job.title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "${job.jobType} • ${DateFormat('MMM d, y').format(job.datePosted)}",
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Chip(
                    label: Text(job.approvalStatus),
                    backgroundColor: _getStatusColor(job.approvalStatus),
                    labelStyle: const TextStyle(color: Colors.white),
                  ),
                  const Spacer(),
                    ElevatedButton(
                      onPressed: () => _showReviewDialog(job),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        "Review Now",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Approved':
        return Colors.green;
      case 'Rejected':
        return Colors.red;
      case 'Under Review':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  Widget _buildJobList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return FutureBuilder<List<JobModel>>(
      future: _fetchJobsByStatus(_selectedFilter),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting && !_isLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text("Error: ${snapshot.error}"));
        }

        final jobs = snapshot.data ?? [];
        if (jobs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _selectedFilter == 'Pending Review'
                      ? Icons.pending_actions
                      : _selectedFilter == 'Approved'
                      ? Icons.verified
                      : Icons.block,
                  size: 64,
                  color: Colors.grey,
                ),
                const SizedBox(height: 16),
                Text(
                  _selectedFilter == 'Pending Review'
                      ? "No jobs pending review"
                      : _selectedFilter == 'Approved'
                      ? "No approved jobs"
                      : "No rejected jobs",
                  style: const TextStyle(fontSize: 18, color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            setState(() {});
          },
          child: ListView.builder(
            padding: const EdgeInsets.only(top: 16),
            itemCount: jobs.length,
            itemBuilder: (context, index) => _buildJobCard(jobs[index]),
          ),
        );
      },
    );
  }

  Widget _buildFilterChip(String status, IconData icon) {
    return ChoiceChip(
      label: Row(
        children: [
          Icon(icon, size: 18, color: _selectedFilter == status ? Colors.white : Colors.indigo),
          const SizedBox(width: 4),
          Text(status),
        ],
      ),
      selected: _selectedFilter == status,
      selectedColor: Colors.indigo,
      labelStyle: TextStyle(
        color: _selectedFilter == status ? Colors.white : Colors.black,
      ),
      onSelected: (selected) {
        setState(() {
          _selectedFilter = status;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_currentReviewer == null && _isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_currentReviewer == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 20),
              const Text(
                "Reviewer Account Not Found",
                style: TextStyle(fontSize: 20),
              ),
              const SizedBox(height: 10),
              const Text("Please contact support"),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _initializeReviewer,
                child: const Text("Retry"),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Job Review Dashboard",
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.indigo.shade400, Colors.indigo.shade700],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout ,
            tooltip: "logout",
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildFilterChip('Pending Review', Icons.pending_actions),
                  const SizedBox(width: 8),
                  _buildFilterChip('Approved', Icons.verified),
                  const SizedBox(width: 8),
                  _buildFilterChip('Rejected', Icons.block),
                ],
              ),
            ),
          ),
        ),
      ),
      body: _buildJobList(),
    );
  }
}