import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import '../../../../models/applications_model.dart';
import '../../../../models/job _seeker_models/job_seeker_model.dart';
import 'notification_service.dart';

class HiringScreen extends StatefulWidget {
  final String jobId;

  const HiringScreen({Key? key, required this.jobId}) : super(key: key);

  @override
  _HiringScreenState createState() => _HiringScreenState();
}

class _HiringScreenState extends State<HiringScreen> {
  final List<String> _selectedApplicants = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hire Applicants'),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('applications')
                  .where('jobId', isEqualTo: widget.jobId)
                  .where('status', isEqualTo: ApplicationStatus.interviewCompleted.toString().split('.').last)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No completed interviews yet'));
                }

                final applications = snapshot.data!.docs.map((doc) {
                  return ApplicationModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
                }).toList();

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: applications.length,
                  itemBuilder: (context, index) {
                    final application = applications[index];
                    return _buildApplicantCard(application);
                  },
                );
              },
            ),
          ),
          _buildHireButton(),
        ],
      ),
    );
  }

  Widget _buildApplicantCard(ApplicationModel application) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection('jobSeekers')
            .doc(application.jobSeekerId)
            .get(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const ListTile(
              leading: CircleAvatar(child: Icon(Icons.person)),
              title: Text('Loading...'),
            );
          }

          final jobSeeker = JobSeeker.fromMap(
            snapshot.data!.data() as Map<String, dynamic>,
          );

          return CheckboxListTile(
            title: Text(jobSeeker.name),
            subtitle: Text(jobSeeker.userTitle ?? ''),
            secondary: CircleAvatar(
              backgroundImage: jobSeeker.profilePictureUrl != null
                  ? NetworkImage(jobSeeker.profilePictureUrl!)
                  : null,
              child: jobSeeker.profilePictureUrl == null
                  ? const Icon(Icons.person)
                  : null,
            ),
            value: _selectedApplicants.contains(application.applicationId),
            onChanged: (bool? value) {
              setState(() {
                if (value == true) {
                  _selectedApplicants.add(application.applicationId);
                } else {
                  _selectedApplicants.remove(application.applicationId);
                }
              });
            },
          );
        },
      ),
    );
  }

  Widget _buildHireButton() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            backgroundColor: Colors.green,
          ),
          onPressed: _selectedApplicants.isEmpty ? null : _hireApplicants,
          child: const Text('Hire Selected Applicants'),
        ),
      ),
    );
  }

  Future<void> _hireApplicants() async {
    if (_selectedApplicants.isEmpty) return;

    try {
      // First, update the hired applicants
      final batch = FirebaseFirestore.instance.batch();

      for (final appId in _selectedApplicants) {
        final appRef = FirebaseFirestore.instance.collection('applications').doc(appId);
        batch.update(appRef, {
          'status': ApplicationStatus.hired.toString().split('.').last,
          'isWinner': true,
          'statusUpdatedDate': FieldValue.serverTimestamp(),
          'statusNote': 'Applicant hired after interview',
        });
      }

      // Then notify all other applicants that they weren't selected
      final applications = await FirebaseFirestore.instance
          .collection('applications')
          .where('jobId', isEqualTo: widget.jobId)
          .where('status', isEqualTo: ApplicationStatus.interviewCompleted.toString().split('.').last)
          .get();

      for (final doc in applications.docs) {
        if (!_selectedApplicants.contains(doc.id)) {
          batch.update(doc.reference, {
            'status': ApplicationStatus.winnerAnnounced.toString().split('.').last,
            'statusUpdatedDate': FieldValue.serverTimestamp(),
            'statusNote': 'Another applicant was selected for this position',
          });
        }
      }

      await batch.commit();

      // Send notifications
      await NotificationService.sendHireNotifications(
        jobId: widget.jobId,
        hiredApplicationIds: _selectedApplicants,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Applicants hired successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to hire applicants: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}