import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

import '../../../../models/applications_model.dart';
import '../../../../models/job_model.dart';
import 'application_detail_screen.dart';

class JobSeekerApplicationsListScreen extends StatelessWidget {
  const JobSeekerApplicationsListScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Applications'),
        centerTitle: true,
        elevation: 2,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('applications')
            .where('jobSeekerId', isEqualTo: userId)
            .orderBy('appliedDate', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                'No applications found',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          final applications = snapshot.data!.docs.map((doc) {
            return ApplicationModel.fromMap(
              doc.data() as Map<String, dynamic>,
              doc.id,
            );
          }).toList();

          return ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            itemCount: applications.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final application = applications[index];
              return _ApplicationCard(application: application);
            },
          );
        },
      ),
    );
  }
}

class _ApplicationCard extends StatelessWidget {
  final ApplicationModel application;

  const _ApplicationCard({required this.application});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('jobs')
          .doc(application.jobId)
          .get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return _loadingCard();
        }

        final job = JobModel.fromMap(
          snapshot.data!.data() as Map<String, dynamic>,
          snapshot.data!.id,
        );

        return Material(
          elevation: 3,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => JobSeekerApplicationDetailScreen(
                    application: application,
                    job: job,
                  ),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.work_outline, size: 36, color: Colors.blueGrey),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          job.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Applied: ${DateFormat.yMMMd().format(application.appliedDate)}',
                          style: const TextStyle(color: Colors.grey),
                        ),
                        const SizedBox(height: 8),
                        _buildStatusChip(application.status),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _loadingCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(16),
      ),
      child: const ListTile(
        title: Text('Loading...'),
      ),
    );
  }

  Widget _buildStatusChip(ApplicationStatus status) {
    final statusInfo = _getStatusInfo(status);
    return Chip(
      label: Text(
        statusInfo.label,
        style: const TextStyle(color: Colors.white, fontSize: 12),
      ),
      backgroundColor: statusInfo.color,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8),
    );
  }

  _StatusInfo _getStatusInfo(ApplicationStatus status) {
    switch (status) {
      case ApplicationStatus.applied:
        return _StatusInfo('Applied', Colors.blue);
      case ApplicationStatus.acceptedForInterview:
        return _StatusInfo('Interview Accepted', Colors.green);
      case ApplicationStatus.rejected:
        return _StatusInfo('Rejected', Colors.red);
      case ApplicationStatus.interviewScheduled:
        return _StatusInfo('Interview Scheduled', Colors.orange);
      case ApplicationStatus.interviewStarted:
        return _StatusInfo('Interview Started', Colors.deepOrange);
      case ApplicationStatus.responseSubmitted:
        return _StatusInfo('Response Submitted', Colors.amber);
      case ApplicationStatus.interviewCompleted:
        return _StatusInfo('Interview Completed', Colors.purple);
      case ApplicationStatus.hired:
        return _StatusInfo('Hired', Colors.green.shade800);
      case ApplicationStatus.winnerAnnounced:
        return _StatusInfo('Not Selected', Colors.grey);
      case ApplicationStatus.needsResubmission:
        return _StatusInfo('Resubmit Needed', Colors.orange);
      default:
        return _StatusInfo('Unknown', Colors.grey);
    }
  }
}

class _StatusInfo {
  final String label;
  final Color color;

  _StatusInfo(this.label, this.color);
}
