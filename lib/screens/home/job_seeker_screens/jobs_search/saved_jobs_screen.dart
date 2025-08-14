import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:local_job_and_skills_marketplace/models/job_model.dart';
import 'package:local_job_and_skills_marketplace/models/employer_model/employer_model.dart';
import 'package:local_job_and_skills_marketplace/screens/home/job_seeker_screens/jobs_search/job_card.dart';

class SavedJobsScreen extends StatefulWidget {
  const SavedJobsScreen({Key? key}) : super(key: key);

  @override
  _SavedJobsScreenState createState() => _SavedJobsScreenState();
}

class _SavedJobsScreenState extends State<SavedJobsScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isLoading = true;
  List<Map<String, dynamic>> _savedJobs = [];

  @override
  void initState() {
    super.initState();
    _fetchSavedJobs();
  }

  Future<void> _fetchSavedJobs() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    setState(() => _isLoading = true);

    try {
      final snapshot = await _firestore
          .collection('savedJobs')
          .where('userId', isEqualTo: userId)
          .orderBy('savedAt', descending: true)
          .get();

      final jobs = snapshot.docs.map((doc) => doc.data()).toList();

      setState(() {
        _savedJobs = jobs;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching saved jobs: ${e.toString()}')),
      );
    }
  }

  Future<void> _removeSavedJob(String jobId) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    try {
      await _firestore
          .collection('savedJobs')
          .doc('${userId}_$jobId')
          .delete();

      setState(() {
        _savedJobs.removeWhere((job) => job['jobId'] == jobId);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Job removed from saved')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error removing job: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Saved Jobs'),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _savedJobs.isEmpty
          ? const Center(
        child: Text(
          'No saved jobs yet',
          style: TextStyle(fontSize: 16),
        ),
      )
          : RefreshIndicator(
        onRefresh: _fetchSavedJobs,
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _savedJobs.length,
          itemBuilder: (context, index) {
            final savedJob = _savedJobs[index];
            final job = JobModel.fromMap(savedJob['jobData'],savedJob['jobId']);
            final employer = Employer.fromMap(savedJob['employerData']);

            return Column(
              children: [
                JobCard(
                  job: job,
                  employer: employer,
                  onSave: () => _removeSavedJob(job.jobId),
                  showSaveButton: true,
                ),
                const SizedBox(height: 12),
              ],
            );
          },
        ),
      ),
    );
  }
}