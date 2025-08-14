import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../models/applications_model.dart';
import 'interview_details_model.dart';
import 'interview_responses_screen.dart';
import 'interview_schedule_model.dart';
import 'interview_auto_sender.dart'; // New class for auto-sending

class InterviewDetailsEditor extends StatefulWidget {
  final InterviewSchedule schedule;
  final String jobId;

  const InterviewDetailsEditor({
    Key? key,
    required this.schedule,
    required this.jobId,
  }) : super(key: key);

  @override
  State<InterviewDetailsEditor> createState() => _InterviewDetailsEditorState();
}

class _InterviewDetailsEditorState extends State<InterviewDetailsEditor> {
  final _formKey = GlobalKey<FormState>();
  final _scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  bool _isLoading = false;
  bool _isEditing = false;
  DateTime? _responseDeadline;
  String _meetingPlatform = 'Zoom';
  final _meetingLinkController = TextEditingController();
  final List<TextEditingController> _questionControllers = [];
  bool _autoSendEnabled = false;
  String _currentStatus = 'draft'; // Track current status
  static const int MIN_DAYS_AFTER_SCHEDULED_DATE = 1; // Change from 3 to 1 or whatever minimum you want

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
    _meetingLinkController.dispose();
    super.dispose();
  }

  Future<void> _loadExistingDetails() async {
    if (widget.schedule.interviewDetailsId == null) return;

    setState(() => _isLoading = true);
    try {
      final doc = await _firestore
          .collection('interviewDetails')
          .doc(widget.schedule.interviewDetailsId)
          .get();

      if (doc.exists) {
        final details = InterviewDetails.fromMap(doc.data()!, doc.id);
        _initializeFormWithDetails(details);
        _currentStatus = details.status; // Set current status

        // Check if auto-send is already scheduled
        final autoSendDoc = await _firestore
            .collection('interviewAutoSends')
            .doc(widget.schedule.scheduleId)
            .get();
        setState(() {
          _autoSendEnabled = autoSendDoc.exists;
        });
      }
    } on FirebaseException catch (e) {
      _showErrorSnackbar('Failed to load details: ${e.message}');
    } catch (e) {
      _showErrorSnackbar('An unexpected error occurred');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _initializeFormWithDetails(InterviewDetails details) {
    setState(() {
      _isEditing = true;
      if (widget.schedule.interviewType == InterviewType.questionnaire) {
        _responseDeadline = details.responseDeadline;
        _questionControllers.clear();
        _questionControllers.addAll(
          details.questions?.map((q) => TextEditingController(text: q)) ?? [],
        );
      } else {
        _meetingLinkController.text = details.meetingLink ?? '';
        _meetingPlatform = details.meetingPlatform ?? 'Zoom';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldMessenger(
      key: _scaffoldMessengerKey,
      child: Scaffold(
        appBar: AppBar(
          title: Text(_isEditing ? 'Edit Interview Details' : 'Create Interview Details'),
          actions: [
            if (_isEditing)
              IconButton(
                icon: const Icon(Icons.visibility),
                onPressed: _viewResponses,
                tooltip: 'View Responses',
              ),
          ],
        ),
        body: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatusBanner(),
            const SizedBox(height: 16),
            _buildScheduleCard(),
            const SizedBox(height: 24),
            widget.schedule.interviewType == InterviewType.questionnaire
                ? _buildQuestionnaireSection()
                : _buildVideoCallSection(),
            const SizedBox(height: 24),
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBanner() {
    Color backgroundColor;
    IconData icon;
    String statusText;

    if (_currentStatus == 'sent') {
      backgroundColor = Colors.green.withOpacity(0.2);
      icon = Icons.check_circle;
      statusText = 'Interview details have been sent to applicants';
    } else {
      backgroundColor = Colors.orange.withOpacity(0.2);
      icon = Icons.edit;
      statusText = 'Interview details are in draft mode (not sent yet)';
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _currentStatus == 'sent' ? Colors.green : Colors.orange,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: _currentStatus == 'sent' ? Colors.green : Colors.orange),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              statusText,
              style: TextStyle(
                color: _currentStatus == 'sent' ? Colors.green : Colors.orange,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.calendar_today, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text(
                  'Scheduled Interview',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildDetailRow(
              Icons.access_time,
              DateFormat.yMMMd().add_jm().format(widget.schedule.scheduledDate),
            ),
            _buildDetailRow(
              Icons.people,
              '${widget.schedule.applicationIds.length} applicants',
            ),
            _buildDetailRow(
              Icons.category,
              'Type: ${widget.schedule.interviewType.toString().split('.').last}',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Text(text, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }

  Widget _buildQuestionnaireSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Video Questionnaire Details'),
        const SizedBox(height: 12),
        Text(
          'Applicants will receive these questions on the scheduled date and respond with video answers',
          style: TextStyle(color: Colors.grey[600]),
        ),
        const SizedBox(height: 16),
        _buildQuestionsList(),
        _buildAddQuestionButton(),
        const SizedBox(height: 16),
        _buildDeadlinePicker(),
        if (_isEditing) _buildAutoSendToggle(),
      ],
    );
  }

  Widget _buildAutoSendToggle() {
    return Column(
      children: [
        const SizedBox(height: 16),
        SwitchListTile(
          title: const Text('Send Automatically on Scheduled Date'),
          subtitle: const Text('System will send questions automatically at the scheduled time'),
          value: _autoSendEnabled,
          onChanged: (value) async {
            setState(() => _autoSendEnabled = value);
            if (value) {
              await InterviewAutoSender.scheduleAutoSend(
                schedule: widget.schedule,
                jobId: widget.jobId,
                employerId: _auth.currentUser?.uid ?? '',
              );
              _showSuccessSnackbar('Auto-send scheduled successfully');
            } else {
              await InterviewAutoSender.cancelAutoSend(widget.schedule.scheduleId);
              _showSuccessSnackbar('Auto-send cancelled');
            }
          },
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildQuestionsList() {
    if (_questionControllers.isEmpty) {
      return Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'No questions added yet',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ),
      );
    }

    return Column(
      children: _questionControllers
          .asMap()
          .map((index, controller) => MapEntry(
        index,
        _buildQuestionCard(controller, index + 1),
      ))
          .values
          .toList(),
    );
  }

  Widget _buildQuestionCard(TextEditingController controller, int questionNumber) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 12,
              backgroundColor: Theme.of(context).primaryColor.withOpacity(0.2),
              child: Text(
                '$questionNumber',
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).primaryColor,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: controller,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText: 'Enter question...',
                ),
                validator: (value) =>
                value?.isEmpty ?? true ? 'Required' : null,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _removeQuestion(controller),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddQuestionButton() {
    return TextButton.icon(
      icon: Icon(Icons.add, color: Theme.of(context).primaryColor),
      label: Text(
        'Add Question',
        style: TextStyle(color: Theme.of(context).primaryColor),
      ),
      onPressed: _addQuestion,
    );
  }

  Widget _buildDeadlinePicker() {
    final minDeadlineDate = widget.schedule.scheduledDate.add(const Duration(days: MIN_DAYS_AFTER_SCHEDULED_DATE));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Response Deadline',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          'Must be at least $MIN_DAYS_AFTER_SCHEDULED_DATE day${MIN_DAYS_AFTER_SCHEDULED_DATE > 1 ? "s" : ""} after the interview date',
          style: TextStyle(color: Colors.grey[600], fontSize: 12),
        ),
        const SizedBox(height: 8),
        OutlinedButton(
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            side: BorderSide(color: Colors.grey[300]!),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          onPressed: _selectDeadline,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _responseDeadline == null
                    ? 'Select Deadline'
                    : DateFormat.yMMMd().add_jm().format(_responseDeadline!),
              ),
              const Icon(Icons.calendar_today),
            ],
          ),
        ),
        if (_responseDeadline != null &&
            _responseDeadline!.isBefore(minDeadlineDate))
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Deadline must be at least $MIN_DAYS_AFTER_SCHEDULED_DATE day${MIN_DAYS_AFTER_SCHEDULED_DATE > 1 ? "s" : ""} after the interview date', style: TextStyle(color: Colors.red),
            ),
          ),
      ],
    );
  }

  Widget _buildVideoCallSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Video Call Details'),
        const SizedBox(height: 12),
        Text(
          'Applicants will receive this meeting link at the scheduled time',
          style: TextStyle(color: Colors.grey[600]),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _meetingLinkController,
          decoration: InputDecoration(
            labelText: 'Meeting Link',
            hintText: 'https://zoom.us/j/1234567890',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            filled: true,
            fillColor: Colors.grey[50],
            prefixIcon: const Icon(Icons.link),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please provide a meeting link';
            }
            final uri = Uri.tryParse(value);
            if (uri == null || !uri.hasAbsolutePath) {
              return 'Please enter a valid URL';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          value: _meetingPlatform,
          decoration: InputDecoration(
            labelText: 'Platform',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            filled: true,
            fillColor: Colors.grey[50],
          ),
          items: _buildPlatformDropdownItems(),
          onChanged: (value) => setState(() => _meetingPlatform = value!),
        ),
      ],
    );
  }

  List<DropdownMenuItem<String>> _buildPlatformDropdownItems() {
    return ['Zoom', 'Google Meet', 'Microsoft Teams', 'Other']
        .map((platform) => DropdownMenuItem(
      value: platform,
      child: Text(platform),
    ))
        .toList();
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        _buildSaveDraftButton(),
        const SizedBox(height: 12),
        _buildSendButton(),
      ],
    );
  }

  Widget _buildSaveDraftButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          side: BorderSide(color: Theme.of(context).primaryColor),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        onPressed: _saveAsDraft,
        child: const Text('SAVE AS DRAFT'),
      ),
    );
  }

  Widget _buildSendButton() {
    final now = DateTime.now();
    final isOnOrAfterScheduledTime =
        now.isAfter(widget.schedule.scheduledDate) ||
            now.isAtSameMomentAs(widget.schedule.scheduledDate);
    final minDeadlineDate = widget.schedule.scheduledDate.add(const Duration(days: MIN_DAYS_AFTER_SCHEDULED_DATE));
    final isDeadlineValid = _responseDeadline == null ||
        (_responseDeadline!.isAfter(minDeadlineDate) &&
            _responseDeadline!.isAfter(widget.schedule.scheduledDate));

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        onPressed: _isLoading
            ? null
            : () {
          if (widget.schedule.interviewType == InterviewType.questionnaire &&
              !isOnOrAfterScheduledTime) {
            _showErrorSnackbar(
                'Can only send questions on or after the scheduled date (${DateFormat.yMd().format(widget.schedule.scheduledDate)})');
            return;
          }
          if (widget.schedule.interviewType == InterviewType.questionnaire &&
              !isDeadlineValid) {
            _showErrorSnackbar(
                'Response deadline must be at least $MIN_DAYS_AFTER_SCHEDULED_DATE day${MIN_DAYS_AFTER_SCHEDULED_DATE > 1 ? "s" : ""} after the scheduled date');
            return;
          }
          _sendToApplicants();
        },
        child: _isLoading
            ? const SizedBox(
          height: 24,
          width: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Colors.white,
          ),
        )
            : const Text('SEND TO APPLICANTS'),
      ),
    );
  }

  Future<void> _selectDeadline() async {
    final minDate = widget.schedule.scheduledDate.add(const Duration(days: MIN_DAYS_AFTER_SCHEDULED_DATE));
    final initialDate = _responseDeadline ?? minDate;

    final date = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: minDate,
      lastDate: minDate.add(const Duration(days: 365)),
    );
    if (date == null) return;

    final time = await showTimePicker(
      context: context,
      initialTime: _responseDeadline != null
          ? TimeOfDay.fromDateTime(_responseDeadline!)
          : const TimeOfDay(hour: 23, minute: 59),
    );
    if (time == null) return;

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

  void _addQuestion() {
    setState(() {
      _questionControllers.add(TextEditingController());
    });
  }

  void _removeQuestion(TextEditingController controller) {
    setState(() {
      _questionControllers.remove(controller);
      controller.dispose();
    });
  }

  void _viewResponses() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => InterviewResponsesScreen(schedule: widget.schedule),
      ),
    );
  }

  Future<void> _saveAsDraft() async {
    if (!_validateForm()) return;

    setState(() => _isLoading = true);
    try {
      if (widget.schedule.interviewType == InterviewType.questionnaire) {
        await _saveQuestionnaireDetails(status: 'draft');
      } else {
        await _saveVideoCallDetails(status: 'draft');
      }
      setState(() {
        _currentStatus = 'draft';
      });
      _showSuccessSnackbar('Interview details saved as draft');
    } catch (e) {
      _handleError(e);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _sendToApplicants() async {
    if (!_validateForm()) return;

    // Additional validation for questionnaire type
    if (widget.schedule.interviewType == InterviewType.questionnaire) {
      if (_responseDeadline == null) {
        _showErrorSnackbar('Please set a response deadline');
        return;
      }

      final minDeadlineDate = widget.schedule.scheduledDate.add(const Duration(days: MIN_DAYS_AFTER_SCHEDULED_DATE));
      if (_responseDeadline!.isBefore(minDeadlineDate)) {
        _showErrorSnackbar('Response deadline must be at least $MIN_DAYS_AFTER_SCHEDULED_DATE day${MIN_DAYS_AFTER_SCHEDULED_DATE > 1 ? "s" : ""} after the scheduled date');
        return;
      }

      final now = DateTime.now();
      if (now.isBefore(widget.schedule.scheduledDate)) {
        _showErrorSnackbar('Can only send questions on or after the scheduled date');
        return;
      }
    }

    setState(() => _isLoading = true);
    try {
      if (widget.schedule.interviewType == InterviewType.questionnaire) {
        await _saveQuestionnaireDetails(status: 'sent');
      } else {
        await _saveVideoCallDetails(status: 'sent');
      }
      setState(() {
        _currentStatus = 'sent';
      });
      _showSuccessSnackbar('Interview details sent to applicants');
      if (mounted) Navigator.pop(context);
    } catch (e) {
      _handleError(e);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  bool _validateForm() {
    if (!_formKey.currentState!.validate()) {
      _showErrorSnackbar('Please fill all required fields');
      return false;
    }
    return true;
  }

  Future<void> _saveQuestionnaireDetails({required String status}) async {
    final details = InterviewDetails(
      detailsId: widget.schedule.interviewDetailsId ??
          _firestore.collection('interviewDetails').doc().id,
      scheduleId: widget.schedule.scheduleId,
      jobId: widget.jobId,
      employerId: _auth.currentUser?.uid ?? '',
      questions: _questionControllers.map((c) => c.text).toList(),
      responseDeadline: _responseDeadline,
      status: status,
    );

    await _firestore.runTransaction((transaction) async {
      transaction.set(
        _firestore.collection('interviewDetails').doc(details.detailsId),
        details.toMap(),
      );
      transaction.update(
        _firestore
            .collection('interviewSchedules')
            .doc(widget.schedule.scheduleId),
        {'interviewDetailsId': details.detailsId},
      );
    });

    if (status == 'sent') {
      await _notifyApplicants(details);
    }
  }

  Future<void> _saveVideoCallDetails({required String status}) async {
    final details = InterviewDetails(
      detailsId: widget.schedule.interviewDetailsId ??
          _firestore.collection('interviewDetails').doc().id,
      scheduleId: widget.schedule.scheduleId,
      jobId: widget.jobId,
      employerId: _auth.currentUser?.uid ?? '',
      meetingLink: _meetingLinkController.text,
      meetingPlatform: _meetingPlatform,
      status: status,
    );

    await _firestore.runTransaction((transaction) async {
      transaction.set(
        _firestore.collection('interviewDetails').doc(details.detailsId),
        details.toMap(),
      );
      transaction.update(
        _firestore
            .collection('interviewSchedules')
            .doc(widget.schedule.scheduleId),
        {'interviewDetailsId': details.detailsId},
      );
    });

    if (status == 'sent') {
      await _notifyApplicants(details);

      // Store meeting info in all response documents
      final batch = _firestore.batch();
      for (final appId in widget.schedule.applicationIds) {
        final responseRef = _firestore.collection('interviewResponses').doc(appId);
        batch.set(
          responseRef,
          {
            'meetingLink': _meetingLinkController.text,
            'meetingPlatform': _meetingPlatform,
            'status': 'pending',
            'createdAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
      }
      await batch.commit();
    }
  }

  Future<void> _notifyApplicants(InterviewDetails details) async {
    final batch = _firestore.batch();

    for (final appId in widget.schedule.applicationIds) {
      // Create/update response document for both interview types
      final responseDoc = _firestore.collection('interviewResponses').doc(appId);

      if (widget.schedule.interviewType == InterviewType.questionnaire) {
        batch.set(
          responseDoc,
          {
            'applicationId': appId,
            'scheduleId': widget.schedule.scheduleId,
            'jobId': widget.jobId,
            'status': 'pending',
            'questions': details.questions,
            'deadline': details.responseDeadline,
            'videoResponseUrl': null,
            'createdAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
      } else {
        batch.set(
          responseDoc,
          {
            'applicationId': appId,
            'scheduleId': widget.schedule.scheduleId,
            'jobId': widget.jobId,
            'status': 'pending',
            'meetingLink': details.meetingLink,
            'meetingPlatform': details.meetingPlatform,
            'createdAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
      }

      batch.update(
        _firestore.collection('applications').doc(appId),
        {
          'status': ApplicationStatus.interviewStarted.toString().split('.').last,
          'interviewDetailsId': details.detailsId,
          'statusNote': widget.schedule.interviewType ==
              InterviewType.questionnaire
              ? 'Questionnaire sent. Deadline: ${DateFormat.yMd().add_jm().format(details.responseDeadline!)}'
              : 'Video call details added. Platform: ${details.meetingPlatform}',
        },
      );
    }
    await batch.commit();
  }

  void _showSuccessSnackbar(String message) {
    _scaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  void _showErrorSnackbar(String message) {
    _scaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  void _handleError(dynamic error) {
    if (error is FirebaseException) {
      _showErrorSnackbar('Firebase error: ${error.message}');
    } else {
      _showErrorSnackbar('An unexpected error occurred');
    }
  }
}