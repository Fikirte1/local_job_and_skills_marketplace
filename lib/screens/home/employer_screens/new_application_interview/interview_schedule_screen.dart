import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

import '../../../../models/applications_model.dart';
import '../../../../models/job _seeker_models/job_seeker_model.dart';
import 'interview_schedule_model.dart';

class InterviewScheduleScreen extends StatefulWidget {
  final String jobId;

  const InterviewScheduleScreen({Key? key, required this.jobId}) : super(key: key);

  @override
  _InterviewScheduleScreenState createState() => _InterviewScheduleScreenState();
}

class _InterviewScheduleScreenState extends State<InterviewScheduleScreen> {
  final _formKey = GlobalKey<FormState>();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  DateTime _selectedDate = DateTime.now().add(Duration(days: 1));
  TimeOfDay _selectedTime = TimeOfDay(hour: 9, minute: 0);
  InterviewType _interviewType = InterviewType.videoCall;
  String _instructions = '';
  String? _currentEmployerId;
  bool _isScheduling = false;

  @override
  void initState() {
    super.initState();
    _getCurrentEmployerId();
  }

  Future<void> _getCurrentEmployerId() async {
    final user = _auth.currentUser;
    if (user != null) {
      setState(() {
        _currentEmployerId = user.uid;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Schedule Interviews'),
        elevation: 3,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeaderSection(),
              SizedBox(height: 24),
              _buildApplicantSelectionSection(),
              SizedBox(height: 24),
              _buildDateTimePicker(),
              SizedBox(height: 24),
              _buildInterviewTypeSelector(),
              SizedBox(height: 24),
              _buildInstructionsField(),
              SizedBox(height: 32),
              _buildScheduleButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Schedule Interviews',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 8),
        Text(
          'Select applicants, set interview details, and choose the interview format',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildApplicantSelectionSection() {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.people_alt, color: Theme.of(context).primaryColor),
                SizedBox(width: 8),
                Text(
                  'Selected Applicants',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            _buildApplicationsList(),
          ],
        ),
      ),
    );
  }

  Widget _buildApplicationsList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('applications')
          .where('jobId', isEqualTo: widget.jobId)
          .where('status', isEqualTo: ApplicationStatus.acceptedForInterview.toString().split('.').last)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(child: CircularProgressIndicator());
        }

        final applications = snapshot.data!.docs.map((doc) {
          return ApplicationModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
        }).toList();

        if (applications.isEmpty) {
          return Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Text(
              'No applications accepted for interview yet',
              style: TextStyle(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          );
        }

        return Column(
          children: applications.map((app) => FutureBuilder<DocumentSnapshot>(
            future: _firestore.collection('jobSeekers').doc(app.jobSeekerId).get(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return ListTile(
                  leading: CircleAvatar(child: Icon(Icons.person)),
                  title: Text('Loading...'),
                );
              }

              final jobSeekerData = snapshot.data!.data() as Map<String, dynamic>;
              final jobSeeker = JobSeeker.fromMap(jobSeekerData);

              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundImage: jobSeeker.profilePictureUrl != null
                      ? NetworkImage(jobSeeker.profilePictureUrl!)
                      : null,
                  child: jobSeeker.profilePictureUrl == null
                      ? Icon(Icons.person)
                      : null,
                ),
                title: Text(jobSeeker.name),
                subtitle: Text(jobSeeker.userTitle ?? 'No title provided'),
                trailing: Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Accepted',
                    style: TextStyle(color: Colors.green),
                  ),
                ),
              );
            },
          )).toList(),
        );
      },
    );
  }

  Widget _buildDateTimePicker() {
    final scheduledDateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.calendar_today, color: Theme.of(context).primaryColor),
                SizedBox(width: 8),
                Text(
                  'Interview Date & Time',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      side: BorderSide(color: Colors.grey[300]!),
                    ),
                    child: Text(DateFormat.yMd().format(_selectedDate)),
                    onPressed: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: _selectedDate,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(Duration(days: 365)),
                      );
                      if (date != null) {
                        setState(() => _selectedDate = date);
                      }
                    },
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      side: BorderSide(color: Colors.grey[300]!),
                    ),
                    child: Text(_selectedTime.format(context)),
                    onPressed: () async {
                      final time = await showTimePicker(
                        context: context,
                        initialTime: _selectedTime,
                      );
                      if (time != null) {
                        setState(() => _selectedTime = time);
                      }
                    },
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue[700]),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Interview scheduled for:\n${DateFormat.yMd().add_jm().format(scheduledDateTime)}',
                      style: TextStyle(color: Colors.blue[800]),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInterviewTypeSelector() {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.video_call, color: Theme.of(context).primaryColor),
                SizedBox(width: 8),
                Text(
                  'Interview Format',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            _buildInterviewTypeCard(
              InterviewType.videoCall,
              'Video Call Interview',
              'You will send applicants a meeting URL at the scheduled time',
              Icons.videocam,
            ),
            SizedBox(height: 12),
            _buildInterviewTypeCard(
              InterviewType.questionnaire,
              'Video Questionnaire',
              'You will send applicants questions to respond with video answers',
              Icons.assignment,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInterviewTypeCard(
      InterviewType type,
      String title,
      String description,
      IconData icon,
      ) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () {
        setState(() {
          _interviewType = type;
        });
      },
      child: Container(
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _interviewType == type ? Colors.blue[50] : Colors.grey[50],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: _interviewType == type ? Theme.of(context).primaryColor : Colors.grey[200]!,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _interviewType == type ? Theme.of(context).primaryColor : Colors.grey[300],
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.white, size: 20),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _interviewType == type ? Theme.of(context).primaryColor : Colors.black,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Radio<InterviewType>(
              value: type,
              groupValue: _interviewType,
              onChanged: (value) {
                setState(() {
                  _interviewType = value!;
                });
              },
              activeColor: Theme.of(context).primaryColor,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInstructionsField() {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.notes, color: Theme.of(context).primaryColor),
                SizedBox(width: 8),
                Text(
                  'Additional Instructions',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            TextFormField(
              decoration: InputDecoration(
                hintText: 'Provide any special instructions for applicants...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                filled: true,
                fillColor: Colors.grey[50],
              ),
              maxLines: 4,
              onChanged: (value) => _instructions = value,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please provide interview instructions';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScheduleButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        onPressed: _isScheduling ? null : () => _confirmScheduleInterviews(),
        child: _isScheduling
            ? SizedBox(
          height: 24,
          width: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Colors.white,
          ),
        )
            : Text('Schedule Interview'),
      ),
    );
  }

  Future<void> _confirmScheduleInterviews() async {
    if (!_formKey.currentState!.validate()) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirm Interview Schedule'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('You are about to schedule interviews with the following details:'),
            SizedBox(height: 16),
            Text(
              'Date: ${DateFormat.yMd().add_jm().format(DateTime(
                _selectedDate.year,
                _selectedDate.month,
                _selectedDate.day,
                _selectedTime.hour,
                _selectedTime.minute,
              ))}',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'Type: ${_interviewType == InterviewType.videoCall ? 'Video Call' : 'Video Questionnaire'}',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Text(
              _interviewType == InterviewType.videoCall
                  ? 'Applicants will receive a meeting URL at the scheduled time'
                  : 'Applicants will receive questions to respond with video answers',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Confirm'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _scheduleInterviews();
    }
  }

  Future<void> _scheduleInterviews() async {
    if (!_formKey.currentState!.validate()) return;
    if (_currentEmployerId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: No employer ID found')),
      );
      return;
    }

    setState(() => _isScheduling = true);

    final scheduledDateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    // Get all applications accepted for interview
    final query = await _firestore
        .collection('applications')
        .where('jobId', isEqualTo: widget.jobId)
        .where('status', isEqualTo: ApplicationStatus.acceptedForInterview.toString().split('.').last)
        .get();

    if (query.docs.isEmpty) {
      setState(() => _isScheduling = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No applications to schedule')),
      );
      return;
    }

    final applicationIds = query.docs.map((doc) => doc.id).toList();

    try {
      // Create the interview schedule
      final schedule = InterviewSchedule(
        scheduleId: _firestore.collection('interviewSchedules').doc().id,
        jobId: widget.jobId,
        employerId: _currentEmployerId!,
        applicationIds: applicationIds,
        scheduledDate: scheduledDateTime,
        interviewType: _interviewType,
        createdAt: DateTime.now(),
        instructions: _instructions,
      );

      // Update all applications to interviewScheduled status
      final batch = _firestore.batch();
      for (final appId in applicationIds) {
        final appRef = _firestore.collection('applications').doc(appId);
        batch.update(appRef, {
          'status': ApplicationStatus.interviewScheduled.toString().split('.').last,
          'statusUpdatedDate': DateTime.now(),
          'statusNote': 'Interview scheduled for ${DateFormat.yMd().add_jm().format(scheduledDateTime)}. '
              '${_instructions.isNotEmpty ? 'Instructions: $_instructions' : ''}',
          'interviewScheduleId': schedule.scheduleId,
        });
      }

      // Commit both operations in a transaction
      await _firestore.runTransaction((transaction) async {
        transaction.set(
          _firestore.collection('interviewSchedules').doc(schedule.scheduleId),
          schedule.toMap(),
        );
        await batch.commit();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Interview scheduled successfully'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to schedule interview: $e'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isScheduling = false);
    }
  }
}