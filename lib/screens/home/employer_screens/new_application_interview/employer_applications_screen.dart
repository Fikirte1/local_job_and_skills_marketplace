import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../../models/applications_model.dart';
import '../../job_seeker_screens/JobSeekerProfileScreenForEmployer.dart';
import 'interview_management_screen.dart';
import 'interview_schedule_screen.dart';
import 'interview_details_screen.dart';

class EmployerApplicationsScreen extends StatefulWidget {
  final String jobId;

  const EmployerApplicationsScreen({Key? key, required this.jobId}) : super(key: key);

  @override
  _EmployerApplicationsScreenState createState() => _EmployerApplicationsScreenState();
}

class _EmployerApplicationsScreenState extends State<EmployerApplicationsScreen> {
  ApplicationStatus? _filterStatus;
  List<String> _selectedApplicationIds = [];
  bool _isLoading = false;
  bool _hasAcceptedApplications = false;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    _checkForAcceptedApplications();
  }

  Future<void> _checkForAcceptedApplications() async {
    final query = await _firestore
        .collection('applications')
        .where('jobId', isEqualTo: widget.jobId)
        .where('status', isEqualTo: ApplicationStatus.acceptedForInterview.toString().split('.').last)
        .limit(1)
        .get();

    setState(() {
      _hasAcceptedApplications = query.docs.isNotEmpty;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Job Applications'),
        actions: [
          _buildStatusFilterDropdown(),
          if (_selectedApplicationIds.isNotEmpty) ...[
            _buildActionButton(
              icon: Icons.check_circle,
              tooltip: 'Accept selected for interview',
              onPressed: _showAcceptConfirmationDialog,
            ),
            _buildActionButton(
              icon: Icons.cancel,
              tooltip: 'Reject selected',
              onPressed: _showRejectConfirmationDialog,
            ),
          ],
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildApplicationsList(),
      floatingActionButton: _buildInterviewManagementButtons(),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
  }) {
    return IconButton(
      icon: Icon(icon),
      onPressed: onPressed,
      tooltip: tooltip,
    );
  }

  Widget _buildStatusFilterDropdown() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: DropdownButton<ApplicationStatus?>(
        value: _filterStatus,
        hint: const Text('Filter'),
        icon: const Icon(Icons.filter_list),
        onChanged: (ApplicationStatus? newValue) {
          setState(() {
            _filterStatus = newValue;
            _selectedApplicationIds.clear();
          });
        },
        items: [
          const DropdownMenuItem<ApplicationStatus?>(
            value: null,
            child: Text('All Applications'),
          ),
          ...ApplicationStatus.values.map((status) {
            return DropdownMenuItem<ApplicationStatus>(
              value: status,
              child: Text(_getStatusDisplayName(status)),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildApplicationsList() {
    Query query = _firestore
        .collection('applications')
        .where('jobId', isEqualTo: widget.jobId)
        .orderBy('appliedDate', descending: true);

    if (_filterStatus != null) {
      query = query.where('status', isEqualTo: _filterStatus.toString().split('.').last);
    }

    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return ErrorMessageWidget(error: snapshot.error.toString());
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LoadingIndicator();
        }

        final applications = snapshot.data!.docs.map((doc) {
          return ApplicationModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
        }).toList();

        if (applications.isEmpty) {
          return EmptyStateWidget(filterStatus: _filterStatus);
        }

        // Sort applications by compatibility score (highest first)
        applications.sort((a, b) {
          final scoreA = a.compatibilityScore ?? 0;
          final scoreB = b.compatibilityScore ?? 0;
          return scoreB.compareTo(scoreA);
        });

        return ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: applications.length,
          itemBuilder: (context, index) {
            final application = applications[index];
            return ApplicationCard(
              application: application,
              isSelected: _selectedApplicationIds.contains(application.applicationId),
              onSelect: (selected) => _handleApplicationSelection(application.applicationId, selected),
              onTap: () => _showApplicationDetails(application),
            );
          },
        );
      },
    );
  }

  Widget _buildInterviewManagementButtons() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        FloatingActionButton(
          heroTag: 'schedule',
          backgroundColor: Theme.of(context).primaryColor,
          child: const Icon(Icons.schedule),
          onPressed: () => _navigateToInterviewSchedule(),
          tooltip: 'Schedule Interviews',
        ),
        const SizedBox(height: 16),
        FloatingActionButton(
          heroTag: 'details',
          backgroundColor: Colors.orange,
          child: const Icon(Icons.assignment),
          onPressed: () => _navigateToInterviewDetails(),
          tooltip: 'Add Interview Details',
        ),
      ],
    );
  }

  Future<void> _navigateToInterviewSchedule() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => InterviewScheduleScreen(jobId: widget.jobId),
      ),
    );
    if (result == true) {
      setState(() {
        _filterStatus = ApplicationStatus.interviewScheduled;
        _selectedApplicationIds.clear();
      });
    }
  }

  Future<void> _navigateToInterviewDetails() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => InterviewManagementScreen(jobId: widget.jobId),
      ),
    );
    if (result == true) {
      setState(() {});
    }
  }

  void _handleApplicationSelection(String applicationId, bool selected) {
    setState(() {
      if (selected) {
        _selectedApplicationIds.add(applicationId);
      } else {
        _selectedApplicationIds.remove(applicationId);
      }
    });
  }

  Future<void> _showApplicationDetails(ApplicationModel application) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => JobSeekerProfileScreenForEmployer(
          jobSeekerId: application.jobSeekerId,
        ),
      ),
    );
  }

  Future<void> _showAcceptConfirmationDialog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => ConfirmationDialog(
        title: 'Accept for Interview',
        content: 'Are you sure you want to accept ${_selectedApplicationIds.length} application(s) for interview?',
        confirmText: 'Accept',
      ),
    );

    if (confirmed == true) {
      await _updateApplicationsStatus(
        status: ApplicationStatus.acceptedForInterview,
        statusNote: 'Accepted for interview',
        successMessage: '${_selectedApplicationIds.length} applications accepted for interview',
      );
    }
  }

  Future<void> _showRejectConfirmationDialog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => ConfirmationDialog(
        title: 'Reject Applications',
        content: 'Are you sure you want to reject ${_selectedApplicationIds.length} application(s)?',
        confirmText: 'Reject',
        isDestructive: true,
      ),
    );

    if (confirmed == true) {
      await _updateApplicationsStatus(
        status: ApplicationStatus.rejected,
        statusNote: 'Application rejected',
        successMessage: '${_selectedApplicationIds.length} applications rejected',
      );
    }
  }

  Future<void> _updateApplicationsStatus({
    required ApplicationStatus status,
    required String statusNote,
    required String successMessage,
  }) async {
    setState(() => _isLoading = true);

    final batch = _firestore.batch();
    final now = DateTime.now();

    for (final appId in _selectedApplicationIds) {
      final appRef = _firestore.collection('applications').doc(appId);
      batch.update(appRef, {
        'status': status.toString().split('.').last,
        'statusUpdatedDate': now,
        'statusNote': statusNote,
      });
    }

    try {
      await batch.commit();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(successMessage),
          behavior: SnackBarBehavior.floating,
        ),
      );
      setState(() {
        _selectedApplicationIds.clear();
        _isLoading = false;
        if (status == ApplicationStatus.acceptedForInterview) {
          _hasAcceptedApplications = true;
        }
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update applications: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  String _getStatusDisplayName(ApplicationStatus status) {
    switch (status) {
      case ApplicationStatus.applied:
        return 'Applied';
      case ApplicationStatus.acceptedForInterview:
        return 'Interview Stage';
      case ApplicationStatus.rejected:
        return 'Rejected';
      case ApplicationStatus.interviewScheduled:
        return 'Scheduled';
      case ApplicationStatus.interviewCompleted:
        return 'Completed';
      case ApplicationStatus.hired:
        return 'Hired';
      case ApplicationStatus.winnerAnnounced:
        return 'Winner';
      default:
        return status.toString().split('.').last;
    }
  }
}

class ApplicationCard extends StatelessWidget {
  final ApplicationModel application;
  final bool isSelected;
  final Function(bool) onSelect;
  final VoidCallback onTap;

  const ApplicationCard({
    Key? key,
    required this.application,
    required this.isSelected,
    required this.onSelect,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isSelectable = application.status == ApplicationStatus.applied ||
        application.status == ApplicationStatus.acceptedForInterview;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (isSelectable)
                    Checkbox(
                      value: isSelected,
                      onChanged: (bool? selected) {
                        if (selected != null) {
                          onSelect(selected);
                        }
                      },
                    ),
                  Expanded(
                    child: FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance
                          .collection('jobSeekers')
                          .doc(application.jobSeekerId)
                          .get(),
                      builder: (context, snapshot) {
                        if (snapshot.hasData) {
                          final jobSeeker = snapshot.data!.data() as Map<String, dynamic>;
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                jobSeeker['name'] ?? 'Unknown Job Seeker',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (application.compatibilityScore != null)
                                Text(
                                  'Compatibility: ${application.compatibilityScore!.toStringAsFixed(1)}%',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[700],
                                  ),
                                ),
                            ],
                          );
                        }
                        return const Text('Loading...');
                      },
                    ),
                  ),
                  StatusBadge(status: application.status),
                ],
              ),
              const SizedBox(height: 8),
              ApplicationTimeline(application: application),
              if (application.statusNote != null) ...[
                const SizedBox(height: 8),
                StatusNoteText(note: application.statusNote!),
              ],
              if (application.status == ApplicationStatus.interviewScheduled ||
                  application.status == ApplicationStatus.interviewCompleted)
                InterviewScheduleInfo(application: application),
            ],
          ),
        ),
      ),
    );
  }
}

class StatusBadge extends StatelessWidget {
  final ApplicationStatus status;

  const StatusBadge({Key? key, required this.status}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _getStatusColor(status),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        _getStatusDisplayName(status),
        style: const TextStyle(
          fontSize: 12,
          color: Colors.white,
        ),
      ),
    );
  }

  Color _getStatusColor(ApplicationStatus status) {
    switch (status) {
      case ApplicationStatus.applied:
        return Colors.blue;
      case ApplicationStatus.acceptedForInterview:
        return Colors.green;
      case ApplicationStatus.rejected:
        return Colors.red;
      case ApplicationStatus.interviewScheduled:
        return Colors.purple;
      case ApplicationStatus.interviewCompleted:
        return Colors.deepPurple;
      case ApplicationStatus.hired:
        return Colors.teal;
      case ApplicationStatus.winnerAnnounced:
        return Colors.amber;
      default:
        return Colors.grey;
    }
  }

  String _getStatusDisplayName(ApplicationStatus status) {
    switch (status) {
      case ApplicationStatus.applied:
        return 'Applied';
      case ApplicationStatus.acceptedForInterview:
        return 'Interview Stage';
      case ApplicationStatus.rejected:
        return 'Rejected';
      case ApplicationStatus.interviewScheduled:
        return 'Scheduled';
      case ApplicationStatus.interviewCompleted:
        return 'Completed';
      case ApplicationStatus.hired:
        return 'Hired';
      case ApplicationStatus.winnerAnnounced:
        return 'Winner';
      default:
        return status.toString().split('.').last;
    }
  }
}

class ApplicationTimeline extends StatelessWidget {
  final ApplicationModel application;

  const ApplicationTimeline({Key? key, required this.application}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.access_time, size: 14, color: Colors.grey),
        const SizedBox(width: 4),
        Text(
          'Applied: ${DateFormat.yMd().add_jm().format(application.appliedDate)}',
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }
}

class StatusNoteText extends StatelessWidget {
  final String note;

  const StatusNoteText({Key? key, required this.note}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Text(
      note,
      style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
    );
  }
}

class InterviewScheduleInfo extends StatelessWidget {
  final ApplicationModel application;

  const InterviewScheduleInfo({Key? key, required this.application}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot>(
      future: application.interviewScheduleId != null
          ? FirebaseFirestore.instance
          .collection('interviewSchedules')
          .doc(application.interviewScheduleId)
          .get()
          : null,
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data!.exists) {
          final scheduleData = snapshot.data!.data() as Map<String, dynamic>;
          final scheduleDate = (scheduleData['scheduledDate'] as Timestamp).toDate();
          final interviewType = scheduleData['interviewType'] == 'videoCall'
              ? 'Video Call'
              : 'Questionnaire';

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    'Scheduled: ${DateFormat.yMd().add_jm().format(scheduleDate)}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.video_call, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    'Type: $interviewType',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ],
          );
        }
        return const SizedBox();
      },
    );
  }
}

class ConfirmationDialog extends StatelessWidget {
  final String title;
  final String content;
  final String confirmText;
  final bool isDestructive;

  const ConfirmationDialog({
    Key? key,
    required this.title,
    required this.content,
    required this.confirmText,
    this.isDestructive = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title),
      content: Text(content),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: isDestructive ? Colors.red : Theme.of(context).primaryColor,
          ),
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(confirmText),
        ),
      ],
    );
  }
}

class ErrorMessageWidget extends StatelessWidget {
  final String error;

  const ErrorMessageWidget({Key? key, required this.error}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          const Text(
            'Error loading applications',
            style: TextStyle(fontSize: 18, color: Colors.red),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: const TextStyle(color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class LoadingIndicator extends StatelessWidget {
  const LoadingIndicator({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }
}

class EmptyStateWidget extends StatelessWidget {
  final ApplicationStatus? filterStatus;

  const EmptyStateWidget({Key? key, this.filterStatus}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.people_outline, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            filterStatus == null
                ? 'No applications found'
                : 'No ${_getStatusDisplayName(filterStatus!).toLowerCase()} applications',
            style: const TextStyle(color: Colors.grey, fontSize: 18),
          ),
        ],
      ),
    );
  }

  String _getStatusDisplayName(ApplicationStatus? status) {
    if (status == null) return '';
    switch (status) {
      case ApplicationStatus.applied:
        return 'Applied';
      case ApplicationStatus.acceptedForInterview:
        return 'Interview Stage';
      case ApplicationStatus.rejected:
        return 'Rejected';
      case ApplicationStatus.interviewScheduled:
        return 'Scheduled';
      case ApplicationStatus.interviewCompleted:
        return 'Completed';
      case ApplicationStatus.hired:
        return 'Hired';
      case ApplicationStatus.winnerAnnounced:
        return 'Winner';
      default:
        return status.toString().split('.').last;
    }
  }
}