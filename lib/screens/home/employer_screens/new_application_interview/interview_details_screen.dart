/*
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

import '../../../../models/job _seeker_models/job_seeker_model.dart';
import 'interview_details_model.dart';
import 'interview_schedule_model.dart';
import '../../../../models/applications_model.dart';

class InterviewDetailsScreen extends StatefulWidget {
  final String jobId;

  const InterviewDetailsScreen({Key? key, required this.jobId}) : super(key: key);

  @override
  _InterviewDetailsScreenState createState() => _InterviewDetailsScreenState();
}

class _InterviewDetailsScreenState extends State<InterviewDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  List<InterviewSchedule> _schedules = [];
  InterviewSchedule? _selectedSchedule;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadSchedules();
  }

  Future<void> _loadSchedules() async {
    setState(() => _isLoading = true);
    try {
      final query = await _firestore
          .collection('interviewSchedules')
          .where('jobId', isEqualTo: widget.jobId)
          .orderBy('scheduledDate', descending: false)
          .get();

      if (query.docs.isNotEmpty) {
        setState(() {
          _schedules = query.docs
              .map((doc) => InterviewSchedule.fromMap(doc.data(), doc.id))
              .toList();
          _selectedSchedule = _schedules.first;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load schedules: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Interview Management')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _schedules.isEmpty
          ? _buildEmptyState()
          : _buildMainContent(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.calendar_today, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          const Text(
            'No Interview Schedules',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          Text(
            'Create interview schedules first',
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    return Column(
      children: [
        _buildScheduleTabs(),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: _selectedSchedule == null
                ? const Center(child: Text('Select a schedule'))
                : _buildScheduleDetails(),
          ),
        ),
      ],
    );
  }

  Widget _buildScheduleTabs() {
    return SizedBox(
      height: 150,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _schedules.length,
        itemBuilder: (context, index) {
          final schedule = _schedules[index];
          return _ScheduleTab(
            schedule: schedule,
            isSelected: _selectedSchedule?.scheduleId == schedule.scheduleId,
            onTap: () => setState(() => _selectedSchedule = schedule),
          );
        },
      ),
    );
  }

  Widget _buildScheduleDetails() {
    return Form(
      key: _formKey,
      child: ListView(
        children: [
          _ScheduleHeader(schedule: _selectedSchedule!),
          const SizedBox(height: 24),
          _selectedSchedule!.interviewType == InterviewType.questionnaire
              ? _QuestionnaireForm(schedule: _selectedSchedule!)
              : _VideoCallForm(schedule: _selectedSchedule!),
          const SizedBox(height: 24),
          _SubmitButton(
            onPressed: _saveInterviewDetails,
            schedule: _selectedSchedule!,
          ),
          const SizedBox(height: 24),
          if (_selectedSchedule!.interviewDetailsId != null)
            _InterviewResponsesList(schedule: _selectedSchedule!),
        ],
      ),
    );
  }

  Future<void> _saveInterviewDetails() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedSchedule == null) return;

    setState(() => _isLoading = true);
    try {
      if (_selectedSchedule!.interviewType == InterviewType.videoCall) {
        await _saveVideoCallDetails();
      } else {
        await _saveQuestionnaireDetails();
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Interview details saved successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save details: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveVideoCallDetails() async {
    final meetingLink = _VideoCallForm.of(context)?.meetingLink ?? '';
    final meetingPlatform = _VideoCallForm.of(context)?.meetingPlatform ?? 'Zoom';

    final details = InterviewDetails(
      detailsId: _selectedSchedule!.interviewDetailsId ??
          _firestore.collection('interviewDetails').doc().id,
      scheduleId: _selectedSchedule!.scheduleId,
      jobId: widget.jobId,
      employerId: _auth.currentUser!.uid,
      meetingLink: meetingLink,
      meetingPlatform: meetingPlatform,
    );

    await _firestore.runTransaction((transaction) async {
      transaction.set(
        _firestore.collection('interviewDetails').doc(details.detailsId),
        details.toMap(),
      );
      transaction.update(
        _firestore.collection('interviewSchedules').doc(_selectedSchedule!.scheduleId),
        {'interviewDetailsId': details.detailsId},
      );
    });

    // Notify applicants
    final batch = _firestore.batch();
    for (final appId in _selectedSchedule!.applicationIds) {
      batch.update(
        _firestore.collection('applications').doc(appId),
        {
          'interviewDetailsId': details.detailsId,
          'statusNote': 'Video call details added. Platform: $meetingPlatform',
        },
      );
    }
    await batch.commit();
  }

  Future<void> _saveQuestionnaireDetails() async {
    final questions = _QuestionnaireForm.of(context)?.questions ?? [];
    final responseDeadline = _QuestionnaireForm.of(context)?.responseDeadline;

    final details = InterviewDetails(
      detailsId: _selectedSchedule!.interviewDetailsId ??
          _firestore.collection('interviewDetails').doc().id,
      scheduleId: _selectedSchedule!.scheduleId,
      jobId: widget.jobId,
      employerId: _auth.currentUser!.uid,
      questions: questions,
      responseDeadline: responseDeadline,
    );

    await _firestore.runTransaction((transaction) async {
      transaction.set(
        _firestore.collection('interviewDetails').doc(details.detailsId),
        details.toMap(),
      );
      transaction.update(
        _firestore.collection('interviewSchedules').doc(_selectedSchedule!.scheduleId),
        {'interviewDetailsId': details.detailsId},
      );
    });

    // Create response documents for each applicant
    final batch = _firestore.batch();
    for (final appId in _selectedSchedule!.applicationIds) {
      final responseDoc = _firestore.collection('interviewResponses').doc(appId);
      batch.set(responseDoc, {
        'applicationId': appId,
        'scheduleId': _selectedSchedule!.scheduleId,
        'jobId': widget.jobId,
        'status': 'pending',
        'questions': questions,
        'deadline': responseDeadline,
        'createdAt': DateTime.now(),
        'videoResponseUrl':null,
        'meetingLinkReceivedCheck':null
      });

      // Update application status note
      batch.update(
        _firestore.collection('applications').doc(appId),
        {
          'interviewDetailsId': details.detailsId,
          'statusNote': 'Questionnaire sent. Deadline: ${DateFormat.yMd().add_jm().format(responseDeadline!)}',
        },
      );
    }
    await batch.commit();
  }
}

class _ScheduleTab extends StatelessWidget {
  final InterviewSchedule schedule;
  final bool isSelected;
  final VoidCallback onTap;

  const _ScheduleTab({
    required this.schedule,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: 150,
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isSelected ? Theme.of(context).primaryColor.withOpacity(0.1) : Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? Theme.of(context).primaryColor : Colors.transparent,
          ),
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              DateFormat.MMMd().format(schedule.scheduledDate),
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              DateFormat.jm().format(schedule.scheduledDate),
              style: const TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 4),
            Chip(
              label: Text(
                schedule.interviewType.toString().split('.').last,
                style: const TextStyle(fontSize: 12),
              ),
              backgroundColor: isSelected ? Theme.of(context).primaryColor : Colors.grey,
              labelStyle: const TextStyle(color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScheduleHeader extends StatelessWidget {
  final InterviewSchedule schedule;

  const _ScheduleHeader({required this.schedule});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.calendar_today, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  'Interview Schedule',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 12),
            _DetailRow(
              icon: Icons.access_time,
              label: 'Date & Time',
              value: DateFormat.yMd().add_jm().format(schedule.scheduledDate),
            ),
            _DetailRow(
              icon: Icons.people,
              label: 'Applicants',
              value: '${schedule.applicationIds.length} candidates',
            ),
            _DetailRow(
              icon: Icons.video_call,
              label: 'Type',
              value: schedule.interviewType.toString().split('.').last,
            ),
            if (schedule.instructions != null) ...[
              const SizedBox(height: 8),
              _DetailRow(
                icon: Icons.note,
                label: 'Instructions',
                value: schedule.instructions!,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuestionnaireForm extends StatefulWidget {
  final InterviewSchedule schedule;
  const _QuestionnaireForm({required this.schedule});

  static _QuestionnaireFormState? of(BuildContext context) =>
      context.findAncestorStateOfType<_QuestionnaireFormState>();

  @override
  _QuestionnaireFormState createState() => _QuestionnaireFormState();
}

class _QuestionnaireFormState extends State<_QuestionnaireForm> {
  final List<TextEditingController> _questionControllers = [];
  DateTime? _responseDeadline;

  @override
  void initState() {
    super.initState();
    _loadExistingDetails();
  }

  @override
  void dispose() {
    for (var controller in _questionControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _loadExistingDetails() async {
    if (widget.schedule.interviewDetailsId == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('interviewDetails')
        .doc(widget.schedule.interviewDetailsId)
        .get();

    if (doc.exists) {
      final details = InterviewDetails.fromMap(doc.data()!, doc.id);
      setState(() {
        _responseDeadline = details.responseDeadline;
        _questionControllers.addAll(
          details.questions?.map((q) => TextEditingController(text: q)) ?? [],
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Questionnaire Details',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        const Text('Questions:', style: TextStyle(fontWeight: FontWeight.bold)),
        ..._questionControllers.map((controller) => Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: TextFormField(
            controller: controller,
            decoration: InputDecoration(
              hintText: 'Enter question',
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                icon: const Icon(Icons.remove_circle),
                onPressed: () => _removeQuestion(controller),
              ),
            ),
            validator: (value) => value?.isEmpty ?? true ? 'Question cannot be empty' : null,
          ),
        )).toList(),
        TextButton(
          child: const Text('+ Add Question'),
          onPressed: _addQuestion,
        ),
        const SizedBox(height: 16),
        const Text('Response Deadline:', style: TextStyle(fontWeight: FontWeight.bold)),
        TextButton(
          child: Text(
            _responseDeadline == null
                ? 'Select Deadline'
                : DateFormat.yMd().add_jm().format(_responseDeadline!),
          ),
          onPressed: () async {
            final date = await showDatePicker(
              context: context,
              initialDate: DateTime.now().add(const Duration(days: 7)),
              firstDate: DateTime.now(),
              lastDate: DateTime.now().add(const Duration(days: 365)),
            );
            if (date != null) {
              final time = await showTimePicker(
                context: context,
                initialTime: const TimeOfDay(hour: 23, minute: 59),
              );
              if (time != null) {
                setState(() {
                  _responseDeadline = DateTime(
                    date.year,
                    date.month,
                    date.day,
                    time.hour,
                    time.minute,
                  );
                });
              }
            }
          },
        ),
      ],
    );
  }

  void _addQuestion() {
    setState(() {
      _questionControllers.add(TextEditingController());
    });
  }

  void _removeQuestion(TextEditingController controller) {
    setState(() {
      _questionControllers.remove(controller);
    });
  }

  List<String> get questions => _questionControllers.map((c) => c.text).toList();
  DateTime? get responseDeadline => _responseDeadline;
}

class _VideoCallForm extends StatefulWidget {
  final InterviewSchedule schedule;
  const _VideoCallForm({required this.schedule});

  static _VideoCallFormState? of(BuildContext context) =>
      context.findAncestorStateOfType<_VideoCallFormState>();

  @override
  _VideoCallFormState createState() => _VideoCallFormState();
}

class _VideoCallFormState extends State<_VideoCallForm> {
  final _meetingLinkController = TextEditingController();
  String _meetingPlatform = 'Zoom';

  @override
  void initState() {
    super.initState();
    _loadExistingDetails();
  }

  @override
  void dispose() {
    _meetingLinkController.dispose();
    super.dispose();
  }

  Future<void> _loadExistingDetails() async {
    if (widget.schedule.interviewDetailsId == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('interviewDetails')
        .doc(widget.schedule.interviewDetailsId)
        .get();

    if (doc.exists) {
      final details = InterviewDetails.fromMap(doc.data()!, doc.id);
      setState(() {
        _meetingLinkController.text = details.meetingLink ?? '';
        _meetingPlatform = details.meetingPlatform ?? 'Zoom';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Video Call Details',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _meetingLinkController,
          decoration: const InputDecoration(
            labelText: 'Meeting Link',
            border: OutlineInputBorder(),
            hintText: 'https://zoom.us/j/123456789',
          ),
          validator: (value) => value?.isEmpty ?? true ? 'Meeting link is required' : null,
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          value: _meetingPlatform,
          decoration: const InputDecoration(
            labelText: 'Platform',
            border: OutlineInputBorder(),
          ),
          items: ['Zoom', 'Google Meet', 'Microsoft Teams', 'Other']
              .map((platform) => DropdownMenuItem(
            value: platform,
            child: Text(platform),
          ))
              .toList(),
          onChanged: (value) => setState(() => _meetingPlatform = value!),
        ),
      ],
    );
  }

  String get meetingLink => _meetingLinkController.text;
  String get meetingPlatform => _meetingPlatform;
}

class _SubmitButton extends StatelessWidget {
  final VoidCallback onPressed;
  final InterviewSchedule schedule;

  const _SubmitButton({
    required this.onPressed,
    required this.schedule,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        onPressed: onPressed,
        child: Text(
          schedule.interviewDetailsId == null
              ? 'Create Interview Details'
              : 'Update Interview Details',
          style: const TextStyle(fontSize: 16),
        ),
      ),
    );
  }
}

class _InterviewResponsesList extends StatelessWidget {
  final InterviewSchedule schedule;

  const _InterviewResponsesList({required this.schedule});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Applicant Responses',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('applications')
              .where('interviewScheduleId', isEqualTo: schedule.scheduleId)
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final applications = snapshot.data!.docs.map((doc) {
              return ApplicationModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
            }).toList();

            if (applications.isEmpty) {
              return const Center(child: Text('No applicants found'));
            }

            return Column(
              children: applications.map((app) => _ApplicantResponseCard(
                application: app,
                interviewType: schedule.interviewType,
              )).toList(),
            );
          },
        ),
      ],
    );
  }
}

class _ApplicantResponseCard extends StatelessWidget {
  final ApplicationModel application;
  final InterviewType interviewType;

  const _ApplicantResponseCard({
    required this.application,
    required this.interviewType,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FutureBuilder<DocumentSnapshot>(
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
                    snapshot.data!.data() as Map<String, dynamic>);

                return ListTile(
                  leading: CircleAvatar(
                    backgroundImage: jobSeeker.profilePictureUrl != null
                        ? NetworkImage(jobSeeker.profilePictureUrl!)
                        : null,
                    child: jobSeeker.profilePictureUrl == null
                        ? const Icon(Icons.person)
                        : null,
                  ),
                  title: Text(jobSeeker.name),
                  subtitle: Text(jobSeeker.userTitle ?? ''),
                );
              },
            ),
            const SizedBox(height: 16),
            if (interviewType == InterviewType.questionnaire)
              _buildQuestionnaireResponse(),
            if (interviewType == InterviewType.videoCall)
              _buildVideoCallConfirmation(),
            const SizedBox(height: 16),
            if (interviewType == InterviewType.questionnaire &&
                application.status == ApplicationStatus.interviewScheduled)
              _buildResponseActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionnaireResponse() {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('interviewResponses')
          .doc(application.applicationId)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Text(
            'No response submitted yet',
            style: TextStyle(color: Colors.grey),
          );
        }

        final response = snapshot.data!.data() as Map<String, dynamic>;
        final submittedAt = (response['submittedAt'] as Timestamp).toDate();
        final answers = response['answers'] as List<dynamic>? ?? [];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Submitted: ${DateFormat.yMd().add_jm().format(submittedAt)}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            ...answers.map((answer) {
              final qa = answer as Map<String, dynamic>;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      qa['question'],
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    qa['videoUrl'] != null
                        ? InkWell(
                      onTap: () => _playVideo(qa['videoUrl']),
                      child: const Text(
                        'View Video Response',
                        style: TextStyle(color: Colors.blue),
                      ),
                    )
                        : Text(qa['answer'] ?? 'No answer provided'),
                  ],
                ),
              );
            }),
          ],
        );
      },
    );
  }

  Widget _buildVideoCallConfirmation() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Meeting details have been shared with the applicant',
          style: TextStyle(color: Colors.green),
        ),
        SizedBox(height: 8),
        Text(
          'Awaiting confirmation of attendance',
          style: TextStyle(fontStyle: FontStyle.italic),
        ),
      ],
    );
  }

  Widget _buildResponseActions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(
          onPressed: () => _updateStatus(ApplicationStatus.rejected),
          child: const Text('Reject'),
        ),
        const SizedBox(width: 16),
        ElevatedButton(
          onPressed: () => _updateStatus(ApplicationStatus.interviewCompleted),
          child: const Text('Accept'),
        ),
      ],
    );
  }

  void _playVideo(String videoUrl) {
    // TODO: Implement video player
  }

  Future<void> _updateStatus(ApplicationStatus status) async {
    try {
      await FirebaseFirestore.instance
          .collection('applications')
          .doc(application.applicationId)
          .update({
        'status': status.toString().split('.').last,
        'statusUpdatedDate': DateTime.now(),
        'statusNote': status == ApplicationStatus.interviewCompleted
            ? 'Interview responses accepted'
            : 'Interview responses rejected',
      });
    } catch (e) {
      // Error handling would be done by the parent widget
      rethrow;
    }
  }
}
*/
