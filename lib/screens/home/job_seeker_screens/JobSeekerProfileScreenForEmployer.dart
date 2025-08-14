import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../models/employer_model/employer_model.dart';
import '../../../models/job _seeker_models/education_model.dart';
import '../../../models/job _seeker_models/job_seeker_model.dart';
import '../../../models/job _seeker_models/work_experience_model.dart';

import '../../chat_screens/chat_model.dart';
import '../../chat_screens/chat_screen.dart';
import '../../chat_screens/chat_service.dart';

class JobSeekerProfileScreenForEmployer extends StatefulWidget {
  final String jobSeekerId;

  const JobSeekerProfileScreenForEmployer({
    super.key,
    required this.jobSeekerId,
  });

  @override
  State<JobSeekerProfileScreenForEmployer> createState() =>
      _JobSeekerProfileScreenForEmployerState();
}

class _JobSeekerProfileScreenForEmployerState
    extends State<JobSeekerProfileScreenForEmployer> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late Future<JobSeeker> _jobSeekerFuture;

  @override
  void initState() {
    super.initState();
    _jobSeekerFuture = _fetchJobSeekerData();
  }

  Future<JobSeeker> _fetchJobSeekerData() async {
    try {
      final doc =
      await _firestore.collection('jobSeekers').doc(widget.jobSeekerId).get();
      if (!doc.exists) throw Exception('Profile not found');
      return JobSeeker.fromMap(doc.data()!);
    } catch (e) {
      debugPrint('Error fetching job seeker data: $e');
      rethrow;
    }
  }

  Future<void> _launchURL(String url) async {
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open the URL')),
      );
    }
  }

  Future<void> _startChat(BuildContext context, JobSeeker jobSeeker) async {
    final currentUser = Provider.of<User?>(context, listen: false);
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You need to be logged in to start a chat')),
      );
      return;
    }

    final chatService = Provider.of<ChatService>(context, listen: false);

    try {
      // Fetch employer data
      final employerDoc = await _firestore
          .collection('employers')
          .doc(currentUser.uid)
          .get();

      if (!employerDoc.exists) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Employer profile not found')),
        );
        return;
      }

      final employer = Employer.fromMap(employerDoc.data()!);

      // Create a temporary chat room object (not saved to DB yet)
      final tempChatRoom = ChatRoom(
        id: '', // Will be generated when first message is sent
        employerId: currentUser.uid,
        jobSeekerId: jobSeeker.userId,
        employerName: employer.companyName,
        jobSeekerName: jobSeeker.name,
        employerLogoUrl: employer.logoUrl,
        jobSeekerProfileUrl: jobSeeker.profilePictureUrl,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        lastMessage: '',
        hasUnreadMessages: false,
      );

      // Navigate to chat screen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatScreen(
            chatRoom: tempChatRoom,
            currentUserId: currentUser.uid,
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to start chat: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Candidate Profile'),
        centerTitle: true,
        actions: [
          FutureBuilder<JobSeeker>(
            future: _jobSeekerFuture,
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                return IconButton(
                  icon: const Icon(Icons.chat),
                  tooltip: 'Message Candidate',
                  onPressed: () => _startChat(context, snapshot.data!),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: FutureBuilder<JobSeeker>(
        future: _jobSeekerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 48),
                  const SizedBox(height: 16),
                  Text(
                    'Failed to load profile',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    snapshot.error.toString(),
                    style: Theme.of(context).textTheme.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _jobSeekerFuture = _fetchJobSeekerData();
                      });
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final jobSeeker = snapshot.data!;
          return RefreshIndicator(
            onRefresh: () async {
              setState(() {
                _jobSeekerFuture = _fetchJobSeekerData();
              });
            },
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildProfileHeader(jobSeeker),
                  const SizedBox(height: 24),
                  _buildBasicInfoSection(jobSeeker),
                  const SizedBox(height: 24),
                  _buildAboutSection(jobSeeker),
                  const SizedBox(height: 24),
                  _buildSkillsSection(jobSeeker),
                  const SizedBox(height: 24),
                  _buildEducationSection(jobSeeker),
                  const SizedBox(height: 24),
                  _buildWorkExperienceSection(jobSeeker),
                  const SizedBox(height: 24),
                  _buildContactSection(jobSeeker),
                  if (jobSeeker.resumeUrl != null) ...[
                    const SizedBox(height: 24),
                    _buildResumeButton(jobSeeker),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfileHeader(JobSeeker jobSeeker) {
    return Column(
      children: [
        CircleAvatar(
          radius: 60,
          backgroundColor: Colors.grey[200],
          backgroundImage: jobSeeker.profilePictureUrl != null
              ? NetworkImage(jobSeeker.profilePictureUrl!)
              : const AssetImage('assets/default_avatar.png') as ImageProvider,
          child: jobSeeker.profilePictureUrl == null
              ? const Icon(Icons.person, size: 60, color: Colors.grey)
              : null,
        ),
        const SizedBox(height: 16),
        Column(
          children: [
            Text(
              jobSeeker.name,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            if (jobSeeker.userTitle != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  jobSeeker.userTitle!,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.blue[700],
                  ),
                ),
              ),
            if (jobSeeker.region != null || jobSeeker.city != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.location_on, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      [jobSeeker.city, jobSeeker.region]
                          .where((e) => e != null)
                          .join(', '),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 8),
            if (jobSeeker.isVerified == true)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.green),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.verified, color: Colors.green[800], size: 16),
                    const SizedBox(width: 4),
                    Text(
                      'Verified Candidate',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.green[800],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildBasicInfoSection(JobSeeker jobSeeker) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Basic Information',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const Divider(height: 20),
            _buildInfoTile('Full Name', jobSeeker.name, Icons.person),
            _buildInfoTile('Gender', jobSeeker.sex, Icons.transgender),
            if (jobSeeker.userTitle != null)
              _buildInfoTile('Title', jobSeeker.userTitle!, Icons.work_outline),
            if (jobSeeker.region != null || jobSeeker.city != null)
              _buildInfoTile(
                'Location',
                [jobSeeker.city, jobSeeker.region]
                    .where((e) => e != null)
                    .join(', '),
                Icons.location_on,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAboutSection(JobSeeker jobSeeker) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'About',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const Divider(height: 20),
            Text(
              jobSeeker.aboutMe ?? 'No information provided',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSkillsSection(JobSeeker jobSeeker) {
    if (jobSeeker.skills == null || jobSeeker.skills!.isEmpty) {
      return Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'No skills listed',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey,
            ),
          ),
        ),
      );
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Skills',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const Divider(height: 20),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: jobSeeker.skills!
                  .map((skill) => Chip(label: Text(skill)))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEducationSection(JobSeeker jobSeeker) {
    if (jobSeeker.educationHistory == null ||
        jobSeeker.educationHistory!.isEmpty) {
      return Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'No education history',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey,
            ),
          ),
        ),
      );
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Education',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const Divider(height: 20),
            Column(
              children: jobSeeker.educationHistory!
                  .map((education) => _buildEducationItem(education))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEducationItem(Education education) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            education.degree,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          Text(education.institution),
          if (education.fieldOfStudy != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                education.fieldOfStudy!,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              education.durationText,
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
          const SizedBox(height: 8),
          const Divider(height: 1),
        ],
      ),
    );
  }

  Widget _buildWorkExperienceSection(JobSeeker jobSeeker) {
    if (jobSeeker.workExperience == null || jobSeeker.workExperience!.isEmpty) {
      return Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'No work experience',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey,
            ),
          ),
        ),
      );
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Work Experience',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const Divider(height: 20),
            Column(
              children: jobSeeker.workExperience!
                  .map((experience) => _buildWorkExperienceItem(experience))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkExperienceItem(WorkExperience experience) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            experience.positionTitle,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          Text(experience.company),
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              experience.durationText,
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
          if (experience.description != null) ...[
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                experience.description!,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ],
          const SizedBox(height: 8),
          const Divider(height: 1),
        ],
      ),
    );
  }

  Widget _buildContactSection(JobSeeker jobSeeker) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Contact Information',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const Divider(height: 20),
            _buildInfoTile('Email', jobSeeker.email, Icons.email),
            _buildInfoTile('Phone', jobSeeker.contactNumber, Icons.phone),
            if (jobSeeker.portfolioLinks != null &&
                jobSeeker.portfolioLinks!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Portfolio Links',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              ...jobSeeker.portfolioLinks!
                  .map((link) => _buildPortfolioLink(link))
                  .toList(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPortfolioLink(String link) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => _launchURL(link),
        child: Row(
          children: [
            const Icon(Icons.link, size: 20, color: Colors.blue),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                link,
                style: const TextStyle(
                  color: Colors.blue,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResumeButton(JobSeeker jobSeeker) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        icon: const Icon(Icons.description),
        label: const Text('View Resume'),
        onPressed: () => _launchURL(jobSeeker.resumeUrl!),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoTile(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}