import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import '../../../../models/applications_model.dart';
import '../../../../models/job_model.dart';
import '../../employer_screens/new_application_interview/interview_details_model.dart';
import '../../employer_screens/new_application_interview/interview_schedule_model.dart';
import 'questionnaire_interview_screen.dart';
import 'video_call_interview_screen.dart';

class JobSeekerApplicationDetailScreen extends StatelessWidget {
  final ApplicationModel application;
  final JobModel job;

  const JobSeekerApplicationDetailScreen({
    Key? key,
    required this.application,
    required this.job,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Application Details'),
        elevation: 3,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildJobInfoCard(),
            const SizedBox(height: 16),
            _buildApplicationStatusCard(),
            const SizedBox(height: 16),
            if (application.interviewScheduleId != null)
              _buildInterviewSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildJobInfoCard() {
    return _ModernCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            job.title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(job.description, style: TextStyle(color: Colors.grey[700])),
          const SizedBox(height: 12),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              _iconText(Icons.location_on, '${job.city ?? ''}, ${job.region ?? ''}'),
              _iconText(Icons.work, job.jobType),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildApplicationStatusCard() {
    return _ModernCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Application Status', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildStatusChip(application.status),
              const Spacer(),
              Text('Applied: ${DateFormat.yMd().format(application.appliedDate)}', style: const TextStyle(fontSize: 12)),
            ],
          ),
          if (application.statusNote != null) ...[
            const Divider(height: 24),
            Text(application.statusNote!, style: const TextStyle(fontStyle: FontStyle.italic)),
          ],
          if (application.rejectionReason != null) ...[
            const Divider(height: 24),
            Text('Rejection Reason: ${application.rejectionReason}', style: TextStyle(color: Colors.red.shade700)),
          ],
          if (application.resubmissionFeedback != null) ...[
            const Divider(height: 24),
            Text('Resubmission Feedback: ${application.resubmissionFeedback}', style: TextStyle(color: Colors.orange.shade700)),
          ],
        ],
      ),
    );
  }

  Widget _buildInterviewSection() {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('interviewSchedules')
          .doc(application.interviewScheduleId)
          .snapshots(),
      builder: (context, scheduleSnapshot) {
        if (!scheduleSnapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final schedule = InterviewSchedule.fromMap(
          scheduleSnapshot.data!.data() as Map<String, dynamic>,
          scheduleSnapshot.data!.id,
        );

        return Column(
          children: [
            _ModernCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Interview Schedule', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  _iconText(Icons.calendar_today, DateFormat.yMMMd().add_jm().format(schedule.scheduledDate)),
                  const SizedBox(height: 4),
                  _iconText(Icons.video_call, schedule.interviewType == InterviewType.videoCall ? 'Video Call Interview' : 'Questionnaire Interview'),
                  if (schedule.instructions != null) ...[
                    const Divider(height: 24),
                    const Text('Instructions:', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text(schedule.instructions!),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (schedule.interviewDetailsId != null)
              _buildInterviewDetailsSection(schedule),
          ],
        );
      },
    );
  }

  Widget _buildInterviewDetailsSection(InterviewSchedule schedule) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('interviewDetails')
          .doc(schedule.interviewDetailsId)
          .snapshots(),
      builder: (context, detailsSnapshot) {
        if (!detailsSnapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final details = InterviewDetails.fromMap(
          detailsSnapshot.data!.data() as Map<String, dynamic>,
          detailsSnapshot.data!.id,
        );

        if (details.status == 'draft') {
          return const _ModernCard(
            child: Text('Interview details are being prepared by the employer'),
          );
        }

        return Column(
          children: [
            if (schedule.interviewType == InterviewType.questionnaire)
              _buildQuestionnaireDetails(context, details, schedule),
            if (schedule.interviewType == InterviewType.videoCall)
              _buildVideoCallDetails(context, details, schedule),
          ],
        );
      },
    );
  }

  Widget _buildQuestionnaireDetails(BuildContext context, InterviewDetails details, InterviewSchedule schedule) {
    return _ModernCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Questionnaire Details', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          if (details.responseDeadline != null)
            Text('Deadline: ${DateFormat.yMMMd().add_jm().format(details.responseDeadline!)}'),
          const SizedBox(height: 12),
          if (details.questions != null && details.questions!.isNotEmpty)
            ...details.questions!.map((q) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text('• $q'),
            )),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            icon: const Icon(Icons.edit_document),
            label: const Text('Submit Response'),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => QuestionnaireResponseScreen(
                    application: application,
                    schedule: schedule,
                    details: details,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildVideoCallDetails(BuildContext context, InterviewDetails details, InterviewSchedule schedule) {
    return _ModernCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Video Call Details', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          if (details.meetingPlatform != null)
            Text('Platform: ${details.meetingPlatform}'),
          if (details.meetingLink != null) ...[
            const SizedBox(height: 8),
            ElevatedButton.icon(
              icon: const Icon(Icons.video_call),
              label: const Text('View Meeting Details'),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => VideoCallDetailsScreen(
                      meetingLink: details.meetingLink!,
                      meetingPlatform: details.meetingPlatform ?? 'Video Call',
                      schedule: schedule,
                    ),
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusChip(ApplicationStatus status) {
    final statusInfo = _getStatusInfo(status);
    return Chip(
      label: Text(statusInfo.label, style: const TextStyle(color: Colors.white, fontSize: 12)),
      backgroundColor: statusInfo.color,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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

  Widget _iconText(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: Colors.teal),
        const SizedBox(width: 6),
        Flexible(child: Text(text, style: const TextStyle(fontSize: 14))),
      ],
    );
  }
}

class _ModernCard extends StatelessWidget {
  final Widget child;

  const _ModernCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      shadowColor: Colors.black26,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: child,
      ),
    );
  }
}

class _StatusInfo {
  final String label;
  final Color color;
  _StatusInfo(this.label, this.color);
}
