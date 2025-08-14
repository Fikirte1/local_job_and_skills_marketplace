/*
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:video_player/video_player.dart';

import '../../../models/applications_model.dart';
import '../../../models/job _seeker_models/job_seeker_model.dart';
import 'application_screens/hiring_decision_screen.dart';
import 'application_screens/schedule_interview_screen.dart';
import 'application_screens/video_review_screen.dart';

class ApplicationsScreen extends StatefulWidget {
  final String jobId;

  const ApplicationsScreen({Key? key, required this.jobId}) : super(key: key);

  @override
  State<ApplicationsScreen> createState() => _ApplicationsScreenState();
}

class _ApplicationsScreenState extends State<ApplicationsScreen> {
  String _selectedStatus = "All";
  final User? _currentUser = FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Applications"),
        actions: [_buildStatusDropdown()],
      ),
      body: _buildApplicationsList(),
    );
  }

  Widget _buildStatusDropdown() {
    return DropdownButton<String>(
      value: _selectedStatus,
      items: ["All", "Applied", "Interview", "Completed", "Hired", "Rejected", "Winner"]
          .map((status) => DropdownMenuItem(
        value: status,
        child: Text(status),
      ))
          .toList(),
      onChanged: (value) => setState(() => _selectedStatus = value!),
    );
  }

  Widget _buildApplicationsList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('applications')
          .where('jobId', isEqualTo: widget.jobId)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

        final applications = snapshot.data!.docs.map((doc) =>
            ApplicationModel.fromMap(doc.data() as Map<String, dynamic>, doc.id)).toList();

        final filteredApplications = _filterApplications(applications);

        if (filteredApplications.isEmpty) {
          return const Center(child: Text("No applications found"));
        }

        return ListView.builder(
          itemCount: filteredApplications.length,
          itemBuilder: (context, index) {
            return FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection('jobSeekers')
                  .doc(filteredApplications[index].jobSeekerId)
                  .get(),
              builder: (context, userSnapshot) {
                if (!userSnapshot.hasData) return const SizedBox();
                final applicant = JobSeeker.fromMap(
                    userSnapshot.data!.data() as Map<String, dynamic>);
                return _buildApplicationCard(
                    context, filteredApplications[index], applicant);
              },
            );
          },
        );
      },
    );
  }

  List<ApplicationModel> _filterApplications(List<ApplicationModel> applications) {
    if (_selectedStatus == "All") return applications;

    return applications.where((app) {
      switch (_selectedStatus) {
        case "Applied":
          return app.status == ApplicationStatus.applied;
        case "Interview":
          return app.status == ApplicationStatus.interviewScheduled;
        case "Completed":
          return app.status == ApplicationStatus.interviewCompleted;
        case "Hired":
          return app.status == ApplicationStatus.hired;
        case "Rejected":
          return app.status == ApplicationStatus.rejected;
        case "Winner":
          return app.status == ApplicationStatus.winnerAnnounced;
        default:
          return false;
      }
    }).toList();
  }

  Widget _buildApplicationCard(
      BuildContext context, ApplicationModel application, JobSeeker applicant) {
    return Card(
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundImage: applicant.profilePictureUrl != null
                      ? NetworkImage(applicant.profilePictureUrl!)
                      : const AssetImage('assets/default_avatar.png') as ImageProvider,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(applicant.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text(applicant.email),
                      _buildStatusIndicator(application.status),
                    ],
                  ),
                ),
                if (application.videoResponseUrl != null)
                  IconButton(
                    icon: const Icon(Icons.videocam),
                    onPressed: () => _viewVideoResponse(application, applicant.name),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            if (application.interviewDate != null)
              Text(
                "Interview: ${DateFormat('MMM dd, yyyy - hh:mm a').format(application.interviewDate!)}",
                style: const TextStyle(fontSize: 12),
              ),
            _buildActionButtons(application),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusIndicator(ApplicationStatus status) {
    Color color;
    String text;

    switch (status) {
      case ApplicationStatus.applied:
        color = Colors.blue;
        text = "Applied";
        break;
      case ApplicationStatus.acceptedForInterview:
        color = Colors.orange;
        text = "Interview Accepted";
        break;
      case ApplicationStatus.interviewScheduled:
        color = Colors.purple;
        text = "Interview Scheduled";
        break;
      case ApplicationStatus.interviewCompleted:
        color = Colors.indigo;
        text = "Response Submitted";
        break;
      case ApplicationStatus.hired:
        color = Colors.green;
        text = "Hired";
        break;
      case ApplicationStatus.rejected:
        color = Colors.red;
        text = "Rejected";
        break;
      case ApplicationStatus.winnerAnnounced:
        color = Colors.green.shade800;
        text = "Winner Announced";
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(text, style: TextStyle(color: color)),
    );
  }

  Widget _buildActionButtons(ApplicationModel application) {
    switch (application.status) {
      case ApplicationStatus.applied:
        return Row(
          children: [
            ElevatedButton(
              onPressed: () => _updateStatus(application, ApplicationStatus.acceptedForInterview),
              child: const Text("Accept for Interview"),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: () => _updateStatus(application, ApplicationStatus.rejected),
              child: const Text("Reject"),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            ),
          ],
        );
      case ApplicationStatus.acceptedForInterview:
        return ElevatedButton(
          onPressed: () => _scheduleInterview(application),
          child: const Text("Schedule Interview"),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
        );
      case ApplicationStatus.interviewCompleted:
        return ElevatedButton(
          onPressed: () => _makeHiringDecision(application),
          child: const Text("Review & Hire"),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
        );
      case ApplicationStatus.hired:
        return ElevatedButton(
          onPressed: () => _announceWinner(application),
          child: const Text("Announce Winner"),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade800),
        );
      case ApplicationStatus.winnerAnnounced:
        return const Text("Winner announced!",
            style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold));
      case ApplicationStatus.rejected:
        return const Text("Candidate rejected", style: TextStyle(color: Colors.red));
      default:
        return const SizedBox();
    }
  }

  void _viewVideoResponse(ApplicationModel application, String name) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VideoReviewScreen(
          videoUrl: application.videoResponseUrl!,
          questions: application.interviewQuestions ?? [],
          applicationId: application.applicationId,
          jobSeekerName: name,
        ),
      ),
    );
  }

  void _scheduleInterview(ApplicationModel application) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ScheduleInterviewScreen(
          applicationId: application.applicationId,
          jobSeekerId: application.jobSeekerId,
        ),
      ),
    );
  }

  void _makeHiringDecision(ApplicationModel application) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => HiringDecisionScreen(
          application: application,
          videoUrl: application.videoResponseUrl!,
        ),
      ),
    );
  }

  void _announceWinner(ApplicationModel application) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => HiringDecisionScreen(
          application: application,
          videoUrl: application.videoResponseUrl!,
        ),
      ),
    );
  }

  Future<void> _updateStatus(
      ApplicationModel application, ApplicationStatus newStatus) async {
    await FirebaseFirestore.instance
        .collection('applications')
        .doc(application.applicationId)
        .update({
      'status': newStatus.toString().split('.').last,
    });

    // Send notification to job seeker
    await _sendNotification(
      userId: application.jobSeekerId,
      title: "Application Update",
      body: "Your application status has been updated to: ${newStatus.toString().split('.').last}",
    );
  }

  Future<void> _sendNotification({
    required String userId,
    required String title,
    required String body,
  }) async {
    await FirebaseFirestore.instance.collection('notifications').add({
      'userId': userId,
      'title': title,
      'body': body,
      'timestamp': FieldValue.serverTimestamp(),
      'read': false,
    });
  }
}


*/
