import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:video_player/video_player.dart';

import '../../../../models/applications_model.dart';
import '../../../../models/job _seeker_models/job_seeker_model.dart';
import 'interview_details_model.dart';
import 'interview_response_model.dart';
import 'interview_schedule_model.dart';
import 'hiring_screen.dart';
import 'notification_service.dart';

class InterviewResponsesScreen extends StatelessWidget {
  final InterviewSchedule schedule;

  const InterviewResponsesScreen({Key? key, required this.schedule}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Interview Responses'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_alt),
            onPressed: () => _showFilterDialog(context),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(child: _buildResponseList()),
            _buildHiringButton(context),
        ],
      ),
    );
  }

  Widget _buildHiringButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => HiringScreen(jobId: schedule.jobId),
              ),
            );
          },
          child: const Text('Proceed to Hiring'),
        ),
      ),
    );
  }

  Widget _buildResponseList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('applications')
          .where('interviewScheduleId', isEqualTo: schedule.scheduleId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No applicants found'));
        }

        final applications = snapshot.data!.docs.map((doc) {
          return ApplicationModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
        }).toList();

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: applications.length,
          itemBuilder: (context, index) {
            return _ApplicantResponseCard(
              application: applications[index],
              interviewType: schedule.interviewType,
              schedule: schedule,
            );
          },
        );
      },
    );
  }

  void _showFilterDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Filter Responses'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('All Responses'),
                onTap: () => Navigator.pop(context),
              ),
              ListTile(
                title: const Text('Pending Review'),
                onTap: () => Navigator.pop(context),
              ),
              ListTile(
                title: const Text('Completed'),
                onTap: () => Navigator.pop(context),
              ),
              ListTile(
                title: const Text('Hired'),
                onTap: () => Navigator.pop(context),
              ),
              ListTile(
                title: const Text('Rejected'),
                onTap: () => Navigator.pop(context),
              ),
              ListTile(
                title: const Text('Needs Resubmission'),
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ApplicantResponseCard extends StatefulWidget {
  final ApplicationModel application;
  final InterviewType interviewType;
  final InterviewSchedule schedule;

  const _ApplicantResponseCard({
    required this.application,
    required this.interviewType,
    required this.schedule,
  });

  @override
  State<_ApplicantResponseCard> createState() => __ApplicantResponseCardState();
}

class __ApplicantResponseCardState extends State<_ApplicantResponseCard> {
  late VideoPlayerController? _videoPlayerController;
  Future<void>? _initializeVideoPlayerFuture;
  bool _isVideoPlaying = false;

  @override
  void initState() {
    super.initState();
    _videoPlayerController = null;
  }

  @override
  void dispose() {
    _videoPlayerController?.dispose();
    super.dispose();
  }

  void _initVideoPlayer(String videoUrl) {
    _videoPlayerController = VideoPlayerController.network(videoUrl);
    _initializeVideoPlayerFuture = _videoPlayerController!.initialize().then((_) {
      setState(() {});
    });
  }

  void _toggleVideoPlayback() {
    setState(() {
      if (_videoPlayerController!.value.isPlaying) {
        _videoPlayerController!.pause();
        _isVideoPlaying = false;
      } else {
        _videoPlayerController!.play();
        _isVideoPlaying = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildApplicantHeader(),
            const SizedBox(height: 16),
            _buildResponseStatusInfo(),
            const SizedBox(height: 16),
            // Dynamic content based on interview type
            if (widget.interviewType == InterviewType.questionnaire)
              _buildQuestionnaireResponse(),
            if (widget.interviewType == InterviewType.videoCall)
              _buildVideoCallAttendance(),
            const SizedBox(height: 16),
            _buildResponseActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildApplicantHeader() {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('jobSeekers')
          .doc(widget.application.jobSeekerId)
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

        return ListTile(
          contentPadding: EdgeInsets.zero,
          leading: CircleAvatar(
            radius: 24,
            backgroundImage: jobSeeker.profilePictureUrl != null
                ? NetworkImage(jobSeeker.profilePictureUrl!)
                : null,
            child: jobSeeker.profilePictureUrl == null
                ? const Icon(Icons.person)
                : null,
          ),
          title: Text(
            jobSeeker.name,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          subtitle: Text(jobSeeker.userTitle ?? ''),
          trailing: _buildStatusChip(widget.application.status),
        );
      },
    );
  }

  Widget _buildResponseStatusInfo() {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('interviewDetails')
          .doc(widget.application.interviewDetailsId)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const SizedBox();
        }

        final details = InterviewDetails.fromMap(
          snapshot.data!.data() as Map<String, dynamic>,
          snapshot.data!.id,
        );

        if (details.status == 'draft') {
          return _buildStatusMessage(
            'Interview details are still in draft',
            icon: Icons.edit,
            color: Colors.orange,
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.application.rejectionReason != null) ...[
              _buildStatusMessage(
                'Rejection Reason: ${widget.application.rejectionReason}',
                icon: Icons.cancel,
                color: Colors.red,
              ),
              const SizedBox(height: 8),
            ],
            if (widget.application.resubmissionFeedback != null) ...[
              _buildStatusMessage(
                'Resubmission Feedback: ${widget.application.resubmissionFeedback}',
                icon: Icons.feedback,
                color: Colors.orange,
              ),
              const SizedBox(height: 8),
            ],
            if (widget.interviewType == InterviewType.questionnaire)
              _buildQuestionnaireStatusInfo(details),
          ],
        );
      },
    );
  }

  Widget _buildQuestionnaireStatusInfo(InterviewDetails details) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('interviewResponses')
          .doc(widget.application.applicationId)
          .snapshots(),
      builder: (context, responseSnapshot) {
        if (!responseSnapshot.hasData || !responseSnapshot.data!.exists) {
          return _buildStatusMessage(
            'Interview not yet sent to applicant',
            icon: Icons.send,
            color: Colors.blue,
          );
        }

        final response = InterviewResponse.fromFirestore(responseSnapshot.data!);

        if (response.status == 'needsResubmission') {
          return _buildStatusMessage(
            'Applicant needs to resubmit video response',
            icon: Icons.videocam_off,
            color: Colors.orange,
          );
        }

        if (response.videoResponseUrl == null) {
          return _buildStatusMessage(
            'Applicant has not submitted video response',
            icon: Icons.videocam_off,
            color: Colors.orange,
          );
        }

        return const SizedBox();
      },
    );
  }

  Widget _buildStatusMessage(String message, {required IconData icon, required Color color}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ), // <-- this was missing
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: color),
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildStatusChip(ApplicationStatus status) {
    final statusInfo = _getStatusInfo(status);
    return Chip(
      label: Text(
        statusInfo.label,
        style: const TextStyle(color: Colors.white),
      ),
      backgroundColor: statusInfo.color,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }

  _StatusInfo _getStatusInfo(ApplicationStatus status) {
    switch (status) {
      case ApplicationStatus.interviewScheduled:
        return _StatusInfo('Pending', Colors.orange);
      case ApplicationStatus.interviewCompleted:
        return _StatusInfo('Completed', Colors.green);
      case ApplicationStatus.hired:
        return _StatusInfo('Hired', Colors.blue);
      case ApplicationStatus.rejected:
        return _StatusInfo('Rejected', Colors.red);
      case ApplicationStatus.needsResubmission:
        return _StatusInfo('Resubmit', Colors.orange);
      case ApplicationStatus.winnerAnnounced:
        return _StatusInfo('Not Selected', Colors.grey);
      default:
        return _StatusInfo('Unknown', Colors.grey);
    }
  }

  Widget _buildQuestionnaireResponse() {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('interviewResponses')
          .doc(widget.application.applicationId)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return _buildEmptyState('No response submitted yet');
        }

        final response = InterviewResponse.fromFirestore(snapshot.data!);
        final submittedAt = response.createdAt?.toDate();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (submittedAt != null)
              Text(
                'Submitted: ${DateFormat.yMMMd().add_jm().format(submittedAt)}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            const SizedBox(height: 16),
            if (response.questions.isNotEmpty) ...[
              Text(
                'Questions & Response',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              ...response.questions.map((question) => _buildQuestionCard(question)),
              const SizedBox(height: 16),
            ],
            if (response.videoResponseUrl != null)
              _buildVideoResponseSection(response.videoResponseUrl!),
          ],
        );
      },
    );
  }

  Widget _buildQuestionCard(dynamic question) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              question is String ? question : question['question'] ?? 'Question',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Applicant should answer this in their video response',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoResponseSection(String videoUrl) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Video Response',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        _buildVideoPlayer(videoUrl),
      ],
    );
  }

  Widget _buildVideoCallAttendance() {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('interviewResponses')
          .doc(widget.application.applicationId)
          .snapshots(),
      builder: (context, snapshot) {
        final hasResponse = snapshot.hasData && snapshot.data!.exists;
        final response = hasResponse
            ? InterviewResponse.fromFirestore(snapshot.data!)
            : null;

        final attended = response?.status == 'attended';
        final recordedAt = response?.createdAt?.toDate();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Video Call Attendance',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            if (!hasResponse)
              _buildEmptyState('Attendance not yet recorded'),

            if (hasResponse) ...[
              Row(
                children: [
                  Icon(
                    attended ? Icons.check_circle : Icons.cancel,
                    color: attended ? Colors.green : Colors.red,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    attended ? 'Attended' : 'No Show',
                    style: TextStyle(
                      color: attended ? Colors.green : Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              if (recordedAt != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Recorded at: ${DateFormat.yMMMd().add_jm().format(recordedAt)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
              const SizedBox(height: 16),
              if (response?.meetingLink != null)
                _buildMeetingInfo(response!),
            ],
          ],
        );
      },
    );
  }

  Widget _buildMeetingInfo(InterviewResponse response) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Meeting Details',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        ListTile(
          leading: const Icon(Icons.video_call),
          title: Text(response.meetingPlatform ?? 'Video Call'),
          subtitle: Text(response.meetingLink ?? 'No link provided'),
          trailing: IconButton(
            icon: const Icon(Icons.open_in_new),
            onPressed: () => _launchMeetingUrl(response.meetingLink),
          ),
        ),
      ],
    );
  }

  Future<void> _launchMeetingUrl(String? url) async {
    if (url == null || url.isEmpty) return;
    // Implementation depends on url_launcher package
    // await launchUrl(Uri.parse(url));
  }

  Widget _buildEmptyState(String message) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Text(
          message,
          style: TextStyle(color: Colors.grey[600]),
        ),
      ),
    );
  }

  Widget _buildVideoPlayer(String videoUrl) {
    _initVideoPlayer(videoUrl);
    return Stack(
      alignment: Alignment.center,
      children: [
        FutureBuilder(
          future: _initializeVideoPlayerFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.done) {
              return AspectRatio(
                aspectRatio: _videoPlayerController!.value.aspectRatio,
                child: VideoPlayer(_videoPlayerController!),
              );
            } else {
              return AspectRatio(
                aspectRatio: 16 / 9,
                child: Container(
                  color: Colors.black,
                  child: const Center(child: CircularProgressIndicator()),
                ),
              );
            }
          },
        ),
        Positioned(
          child: IconButton(
            icon: Icon(
              _isVideoPlaying ? Icons.pause : Icons.play_arrow,
              size: 50,
              color: Colors.white.withOpacity(0.7),
            ),
            onPressed: _toggleVideoPlayback,
          ),
        ),
      ],
    );
  }

  Widget _buildResponseActions() {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('interviewResponses')
          .doc(widget.application.applicationId)
          .snapshots(),
      builder: (context, responseSnapshot) {
        final needsResubmission = responseSnapshot.hasData &&
            responseSnapshot.data!.exists &&
            (responseSnapshot.data!.data() as Map<String, dynamic>)['status'] == 'needsResubmission';

        return Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            // Mark Attendance Button - only for video call interviews
            if (widget.interviewType == InterviewType.videoCall)
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  side: BorderSide(color: Colors.blue.shade300),
                ),
                onPressed: () => _showAttendanceDialog(context, widget.application),
                child: const Text('Mark Attendance'),
              ),
            if (widget.interviewType == InterviewType.videoCall)
              const SizedBox(width: 12),

            // Reject Button
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                side: BorderSide(color: Colors.red.shade300),
              ),
              onPressed: () => _showRejectDialog(context, widget.application),
              child: const Text('Reject'),
            ),
            const SizedBox(width: 12),

            // Resubmit Button - only for questionnaire interviews and if not already needs resubmission
            if (widget.interviewType == InterviewType.questionnaire && !needsResubmission)
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  side: BorderSide(color: Colors.orange.shade300),
                ),
                onPressed: () => _showResubmitDialog(context, widget.application),
                child: const Text('Resubmit'),
              ),
            if (widget.interviewType == InterviewType.questionnaire && !needsResubmission)
              const SizedBox(width: 12),

            // Accept Button - only show if not already completed or hired
            if (widget.application.status != ApplicationStatus.interviewCompleted &&
                widget.application.status != ApplicationStatus.hired)
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                onPressed: () => _updateStatus(
                    context,
                    widget.application,
                    ApplicationStatus.interviewCompleted,
                    widget.interviewType == InterviewType.questionnaire
                        ? 'Questionnaire responses accepted'
                        : 'Video call completed'
                ),
                child: const Text('Accept'),
              ),
          ],
        );
      },
    );
  }

  void _showAttendanceDialog(BuildContext context, ApplicationModel application) {
    bool attended = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Mark Attendance'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  RadioListTile<bool>(
                    title: const Text('Attended'),
                    value: true,
                    groupValue: attended,
                    onChanged: (value) => setState(() => attended = value!),
                  ),
                  RadioListTile<bool>(
                    title: const Text('No Show'),
                    value: false,
                    groupValue: attended,
                    onChanged: (value) => setState(() => attended = value!),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    // Use batch to update both documents
                    final batch = FirebaseFirestore.instance.batch();

                    // Update interview response
                    final responseRef = FirebaseFirestore.instance
                        .collection('interviewResponses')
                        .doc(application.applicationId);
                    batch.update(responseRef, {
                      'status': attended ? 'attended' : 'no_show',
                      'attendedAt': FieldValue.serverTimestamp(),
                      'updatedAt': FieldValue.serverTimestamp(),
                    });

                    // Update application status if attended
                    if (attended) {
                      final applicationRef = FirebaseFirestore.instance
                          .collection('applications')
                          .doc(application.applicationId);
                      batch.update(applicationRef, {
                        'status': 'interviewCompleted',
                        'statusUpdatedDate': FieldValue.serverTimestamp(),
                        'statusNote': 'Applicant attended the video call interview',
                      });
                    }

                    await batch.commit();
                    Navigator.pop(context);
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showRejectDialog(BuildContext context, ApplicationModel application) {
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Reject Applicant'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Please provide a reason for rejection:'),
              const SizedBox(height: 16),
              TextField(
                controller: reasonController,
                decoration: const InputDecoration(
                  labelText: 'Reason',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (reasonController.text.isNotEmpty) {
                  await _updateStatus(
                    context,
                    application,
                    ApplicationStatus.rejected,
                    'Applicant rejected after interview',
                    rejectionReason: reasonController.text,
                  );
                  Navigator.pop(context);
                }
              },
              child: const Text('Confirm Rejection'),
            ),
          ],
        );
      },
    );
  }

  void _showResubmitDialog(BuildContext context, ApplicationModel application) {
    final feedbackController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Request Resubmission'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Please provide feedback for improvement:'),
              const SizedBox(height: 16),
              TextField(
                controller: feedbackController,
                decoration: const InputDecoration(
                  labelText: 'Feedback',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (feedbackController.text.isNotEmpty) {
                  try {
                    // Use batch to update both documents
                    final batch = FirebaseFirestore.instance.batch();

                    // Update application status
                    final applicationRef = FirebaseFirestore.instance
                        .collection('applications')
                        .doc(application.applicationId);
                    batch.update(applicationRef, {
                      'status': 'needsResubmission',
                      'statusUpdatedDate': FieldValue.serverTimestamp(),
                      'resubmissionFeedback': feedbackController.text,
                    });

                    // Update interview response
                    final responseRef = FirebaseFirestore.instance
                        .collection('interviewResponses')
                        .doc(application.applicationId);
                    batch.update(responseRef, {
                      'status': 'needsResubmission',
                      'feedback': feedbackController.text,
                      'updatedAt': FieldValue.serverTimestamp(),
                    });

                    await batch.commit();

                    // Send notification
                    await NotificationService.sendStatusNotification(
                      userId: application.jobSeekerId,
                      status: ApplicationStatus.needsResubmission,
                      resubmissionFeedback: feedbackController.text,
                    );

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Resubmission requested successfully'),
                        backgroundColor: Colors.green,
                      ),
                    );
                    Navigator.pop(context);
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Failed to request resubmission: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              child: const Text('Request Resubmission'),
            ),
          ],
        );
      },
    );
  }


  Future<void> _updateStatus(
      BuildContext context,
      ApplicationModel application,
      ApplicationStatus status,
      String statusNote, {
        String? rejectionReason,
      }) async {
    try {
      // Update application status
      final updateData = {
        'status': status.toString().split('.').last,
        'statusUpdatedDate': FieldValue.serverTimestamp(),
        'statusNote': statusNote,
      };

      if (rejectionReason != null) {
        updateData['rejectionReason'] = rejectionReason;
      }

      // Update both documents in a batch to ensure atomicity
      final batch = FirebaseFirestore.instance.batch();

      // Update application document
      final applicationRef = FirebaseFirestore.instance
          .collection('applications')
          .doc(application.applicationId);
      batch.update(applicationRef, updateData);

      // Update interview response document
      final responseRef = FirebaseFirestore.instance
          .collection('interviewResponses')
          .doc(application.applicationId);

      String responseStatus;
      switch (status) {
        case ApplicationStatus.interviewCompleted:
          responseStatus = 'completed';
          break;
        case ApplicationStatus.rejected:
          responseStatus = 'rejected';
          break;
        case ApplicationStatus.hired:
          responseStatus = 'hired';
          break;
        default:
          responseStatus = 'pending';
      }

      batch.update(responseRef, {
        'status': responseStatus,
        'updatedAt': FieldValue.serverTimestamp(),
        if (rejectionReason != null) 'feedback': rejectionReason,
      });

      await batch.commit();

      // Send appropriate notification
      await NotificationService.sendStatusNotification(
        userId: application.jobSeekerId,
        status: status,
        rejectionReason: rejectionReason,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Status updated to ${status.toString().split('.').last}'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update status: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

class _StatusInfo {
  final String label;
  final Color color;

  _StatusInfo(this.label, this.color);
}