import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

import 'interview_details_editor.dart';
import 'interview_responses_screen.dart';
import 'interview_schedule_model.dart';

class InterviewManagementScreen extends StatefulWidget {
  final String jobId;

  const InterviewManagementScreen({Key? key, required this.jobId}) : super(key: key);

  @override
  _InterviewManagementScreenState createState() => _InterviewManagementScreenState();
}

class _InterviewManagementScreenState extends State<InterviewManagementScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<InterviewSchedule> _schedules = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSchedules();
  }

  Future<void> _loadSchedules() async {
    try {
      final query = await _firestore
          .collection('interviewSchedules')
          .where('jobId', isEqualTo: widget.jobId)
          .orderBy('scheduledDate', descending: false)
          .get();

      setState(() {
        _schedules = query.docs
            .map((doc) => InterviewSchedule.fromMap(doc.data(), doc.id))
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load schedules: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Interview Schedules')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _schedules.isEmpty
          ? _buildEmptyState()
          : _buildScheduleList(),
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

  Widget _buildScheduleList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _schedules.length,
      itemBuilder: (context, index) {
        final schedule = _schedules[index];
        return _ScheduleCard(
          schedule: schedule,
          onTap: () => _navigateToDetailsEditor(schedule),
          onViewResponses: () => _navigateToResponsesScreen(schedule),
        );
      },
    );
  }

// Add this new method to _InterviewManagementScreenState
  void _navigateToResponsesScreen(InterviewSchedule schedule) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => InterviewResponsesScreen(schedule: schedule),
      ),
    );
  }

  void _navigateToDetailsEditor(InterviewSchedule schedule) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => InterviewDetailsEditor(
          schedule: schedule,
          jobId: widget.jobId,
        ),
      ),
    ).then((_) => _loadSchedules());
  }
}

class _ScheduleCard extends StatelessWidget {
  final InterviewSchedule schedule;
  final VoidCallback onTap;
  final VoidCallback? onViewResponses;

  const _ScheduleCard({
    required this.schedule,
    required this.onTap,
    this.onViewResponses,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    DateFormat.yMd().add_jm().format(schedule.scheduledDate),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Chip(
                    label: Text(
                      schedule.interviewType.toString().split('.').last,
                    ),
                    backgroundColor: Theme.of(context).primaryColor,
                    labelStyle: const TextStyle(color: Colors.white),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '${schedule.applicationIds.length} applicants',
                style: const TextStyle(color: Colors.grey),
              ),
              if (schedule.interviewDetailsId != null) ...[
                const SizedBox(height: 8),
                const Text(
                  'Details added',
                  style: TextStyle(color: Colors.green),
                ),
              ],
              const SizedBox(height: 8),
              if (onViewResponses != null)
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: onViewResponses,
                    child: const Text('View Responses'),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}