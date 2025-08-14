import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:local_job_and_skills_marketplace/screens/home/job_seeker_screens/coin_system/coin_purchase_flow.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';

// Import your models
import '../../../models/job _seeker_models/education_model.dart';
import '../../../models/job _seeker_models/job_seeker_model.dart';
import '../../../models/job _seeker_models/work_experience_model.dart';

// Import edit screens
import '../../../services/auth_service.dart';
import '../../auth/signIn_screen.dart';
import 'EditProfileJobSeeker/EditAboutScreen.dart';
import 'EditProfileJobSeeker/EditBasicInfoScreen.dart';
import 'EditProfileJobSeeker/EditDocumentsScreen.dart';
import 'EditProfileJobSeeker/EditEducationScreen.dart';
import 'EditProfileJobSeeker/EditExperienceScreen.dart';
import 'EditProfileJobSeeker/EditSkillsScreen.dart';
import 'EditProfileJobSeeker/profile_completion_widget.dart';
import 'coin_system/CoinBalanceDisplay.dart';
import 'coin_system/JobSeekerCoinDashboard.dart';

class JobSeekerProfileScreen extends StatefulWidget {
  const JobSeekerProfileScreen({super.key});

  @override
  State<JobSeekerProfileScreen> createState() => _JobSeekerProfileScreenState();
}

class _JobSeekerProfileScreenState extends State<JobSeekerProfileScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _imagePicker = ImagePicker();
  late Future<JobSeeker> _jobSeekerFuture;
  final _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _jobSeekerFuture = _fetchJobSeekerData();
  }

  Future<void> _logout() async {
    try {
      await _authService.logout();
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) =>  SignInScreen()),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error during logout: ${e.toString()}')),
      );
    }
  }

  Future<JobSeeker> _fetchJobSeekerData() async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not logged in');

      final doc = await _firestore.collection('jobSeekers').doc(user.uid).get();
      if (!doc.exists) throw Exception('Profile not found');

      final jobSeeker = JobSeeker.fromMap(doc.data()!);

      // Check and update profile completion status if needed
      if (!jobSeeker.isProfileComplete && jobSeeker.checkProfileComplete()) {
        await _firestore.collection('jobSeekers').doc(user.uid).update({
          'isProfileComplete': true,
        });
        return jobSeeker.copyWith(isProfileComplete: true);
      }

      return jobSeeker;
    } catch (e) {
      debugPrint('Error fetching job seeker data: $e');
      rethrow;
    }
  }

  void _navigateToEditScreen(String field) async {
    // First await the future to get the actual JobSeeker object
    final jobSeeker = await _jobSeekerFuture;

    switch (field) {
      case 'userTitle':
      case 'region':
      case 'city':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EditBasicInfoScreen(jobSeeker: jobSeeker),
          ),
        ).then((_) => _refreshData());
        break;
      case 'skills':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EditSkillsScreen(jobSeeker: jobSeeker),
          ),
        ).then((_) => _refreshData());
        break;
      case 'aboutMe':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EditAboutScreen(jobSeeker: jobSeeker),
          ),
        ).then((_) => _refreshData());
        break;
      case 'profilePictureUrl':
        _updateProfilePicture();
        break;
      case 'resumeUrl':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EditDocumentsScreen(jobSeeker: jobSeeker),
          ),
        ).then((_) => _refreshData());
        break;
      case 'educationHistory':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EditEducationScreen(education: null),
          ),
        ).then((_) => _refreshData());
        break;
      case 'workExperience':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EditExperienceScreen(experience: null),
          ),
        ).then((_) => _refreshData());
        break;
    }
  }

  void _refreshData() {
    setState(() {
      _jobSeekerFuture = _fetchJobSeekerData();
    });
  }

  Future<void> _updateProfilePicture() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final pickedFile = await _imagePicker.pickImage(source: ImageSource.gallery);
      if (pickedFile == null) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Uploading profile picture...')),
      );

      final file = File(pickedFile.path);
      final ref = _storage.ref().child('profile_pictures/${user.uid}');
      final uploadTask = ref.putFile(file);
      final snapshot = await uploadTask.whenComplete(() {});
      final downloadUrl = await snapshot.ref.getDownloadURL();

      await _firestore.collection('jobSeekers').doc(user.uid).update({
        'profilePictureUrl': downloadUrl,
      });

      _refreshData();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile picture updated successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update profile picture: $e')),
      );
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        centerTitle: true,
        elevation: 3,
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
                    onPressed: _refreshData,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final jobSeeker = snapshot.data!;
          return RefreshIndicator(
            onRefresh: () async => _refreshData(),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildProfileHeader(jobSeeker),
                  const SizedBox(height: 24),
                  _buildCoinSection(jobSeeker), // Add this line
                  const SizedBox(height: 24),
                  ProfileCompletionWidget(
                    jobSeeker: jobSeeker,
                    onFieldPressed: _navigateToEditScreen,
                  ),
                  const SizedBox(height: 24),
                  _buildBasicInfoSection(jobSeeker),
                  const SizedBox(height: 24),
                  _buildAboutSection(jobSeeker),
                  const SizedBox(height: 24),
                  _buildSkillsSection(jobSeeker),
                  const SizedBox(height: 24),
                  _buildEducationSection(jobSeeker),
                  const SizedBox(height: 24),
                  _buildExperienceSection(jobSeeker),
                  const SizedBox(height: 24),
                  _buildDocumentsSection(jobSeeker),
                  const SizedBox(height: 24),
                  _buildVerificationSection(jobSeeker),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _logout,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.redAccent,
                        elevation: 2,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: Colors.redAccent.withOpacity(0.4)),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                      child: const Text('Log Out'),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

// Update the _buildProfileHeader method in JobSeekerProfileScreen
  Widget _buildProfileHeader(JobSeeker jobSeeker) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            GestureDetector(
              onTap: _updateProfilePicture,
              child: CircleAvatar(
                radius: 60,
                backgroundColor: Colors.grey[200],
                backgroundImage: jobSeeker.profilePictureUrl != null
                    ? NetworkImage(jobSeeker.profilePictureUrl!)
                    : const AssetImage('assets/default_profile.png') as ImageProvider,
                child: jobSeeker.profilePictureUrl == null
                    ? const Icon(Icons.person, size: 60, color: Colors.grey)
                    : null,
              ),
            ),
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.blue,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: const Icon(
                Icons.camera_alt,
                size: 20,
                color: Colors.white,
              ),
            ),
          ],
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
            // Add Coin Balance Display here
            const SizedBox(height: 8),
            const CoinBalanceDisplay(size: 'medium'),
            const SizedBox(height: 8),
            if (jobSeeker.region != null || jobSeeker.city != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.location_on, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      [jobSeeker.city, jobSeeker.region].where((e) => e != null).join(', '),
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
                      'Verified Profile',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.green[800],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              )
            else
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.orange),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.info_outline, color: Colors.orange[800], size: 16),
                    const SizedBox(width: 4),
                    Text(
                      'Not Verified',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.orange[800],
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


  // Add this new method to create a coin management section
  Widget _buildCoinSection(JobSeeker jobSeeker) {
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'My Coins',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: 20),
            const Center(
              child: CoinBalanceDisplay(size: 'large'),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.shopping_cart),
                    label: const Text('Buy More'),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const JobSeekerCoinDashboard(),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '1 coin = 1 job application',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey,
                fontWeight: FontWeight.bold,
                fontSize: 17,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Basic Information',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  tooltip: 'Edit Basic Info',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EditBasicInfoScreen(jobSeeker: jobSeeker),
                      ),
                    ).then((_) => setState(() {
                      _jobSeekerFuture = _fetchJobSeekerData();
                    }));
                  },
                ),
              ],
            ),
            const Divider(height: 20),
            _buildInfoTile('Email', jobSeeker.email, Icons.email),
            _buildInfoTile('Phone', jobSeeker.contactNumber, Icons.phone),
            _buildInfoTile('Gender', jobSeeker.sex, Icons.person_outline),
            if (jobSeeker.languages != null && jobSeeker.languages!.isNotEmpty)
              _buildInfoTile(
                'Languages',
                jobSeeker.languages!.join(', '),
                Icons.language,
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'About Me',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  tooltip: 'Edit About Me',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EditAboutScreen(jobSeeker: jobSeeker),
                      ),
                    ).then((_) => setState(() {
                      _jobSeekerFuture = _fetchJobSeekerData();
                    }));
                  },
                ),
              ],
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Skills',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  tooltip: 'Edit Skills',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EditSkillsScreen(jobSeeker: jobSeeker),
                      ),
                    ).then((_) => setState(() {
                      _jobSeekerFuture = _fetchJobSeekerData();
                    }));
                  },
                ),
              ],
            ),
            const Divider(height: 20),
            if (jobSeeker.skills == null || jobSeeker.skills!.isEmpty)
              Text(
                'No skills added',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey,
                ),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: jobSeeker.skills!
                    .map((skill) => Chip(
                  label: Text(skill),
                  backgroundColor: Colors.blue[50],
                  labelStyle: TextStyle(color: Colors.blue[800]),
                  deleteIcon: const Icon(Icons.close, size: 16),
                  onDeleted: () {
                    // In a real app, you would implement skill deletion here
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Long press to edit skills')),
                    );
                  },
                ))
                    .toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEducationSection(JobSeeker jobSeeker) {
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Education',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  tooltip: 'Add Education',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EditEducationScreen(education: null),
                      ),
                    ).then((_) => setState(() {
                      _jobSeekerFuture = _fetchJobSeekerData();
                    }));
                  },
                ),
              ],
            ),
            const Divider(height: 20),
            if (jobSeeker.educationHistory == null || jobSeeker.educationHistory!.isEmpty)
              Text(
                'No education history added',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey,
                ),
              )
            else
              Column(
                children: jobSeeker.educationHistory!
                    .map((education) => _buildEducationTile(education))
                    .toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEducationTile(Education education) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[200]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        leading: const Icon(Icons.school, color: Colors.blue),
        title: Text(
          education.degree,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              education.institution,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 2),
            Text(
              education.fieldOfStudy,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 2),
            Text(
              education.durationText,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey,
              ),
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: Text('Edit'),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
          onSelected: (value) {
            if (value == 'edit') {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EditEducationScreen(education: education),
                ),
              ).then((_) => setState(() {
                _jobSeekerFuture = _fetchJobSeekerData();
              }));
            } else if (value == 'delete') {
              _deleteEducation(education.id);
            }
          },
        ),
      ),
    );
  }

  Future<void> _deleteEducation(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Education?'),
        content: const Text('Are you sure you want to delete this education entry?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final user = _auth.currentUser;
      if (user == null) return;

      await _firestore.collection('jobSeekers').doc(user.uid).update({
        'educationHistory': FieldValue.arrayRemove([
          {'id': id}
        ]),
      });

      setState(() {
        _jobSeekerFuture = _fetchJobSeekerData();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Education deleted successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete education: $e')),
      );
    }
  }

  Widget _buildExperienceSection(JobSeeker jobSeeker) {
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Work Experience',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  tooltip: 'Add Experience',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EditExperienceScreen(experience: null),
                      ),
                    ).then((_) => setState(() {
                      _jobSeekerFuture = _fetchJobSeekerData();
                    }));
                  },
                ),
              ],
            ),
            const Divider(height: 20),
            if (jobSeeker.workExperience == null || jobSeeker.workExperience!.isEmpty)
              Text(
                'No work experience added',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey,
                ),
              )
            else
              Column(
                children: jobSeeker.workExperience!
                    .map((experience) => _buildExperienceTile(experience))
                    .toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildExperienceTile(WorkExperience experience) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[200]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        leading: const Icon(Icons.work, color: Colors.green),
        title: Text(
          experience.positionTitle,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              experience.company,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            if (experience.description != null) ...[
              const SizedBox(height: 4),
              Text(
                experience.description!,
                style: Theme.of(context).textTheme.bodySmall,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 2),
            Text(
              experience.durationText,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey,
              ),
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: Text('Edit'),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
          onSelected: (value) {
            if (value == 'edit') {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EditExperienceScreen(experience: experience),
                ),
              ).then((_) => setState(() {
                _jobSeekerFuture = _fetchJobSeekerData();
              }));
            } else if (value == 'delete') {
              _deleteExperience(experience.id);
            }
          },
        ),
      ),
    );
  }

  Future<void> _deleteExperience(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Experience?'),
        content: const Text('Are you sure you want to delete this work experience entry?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final user = _auth.currentUser;
      if (user == null) return;

      await _firestore.collection('jobSeekers').doc(user.uid).update({
        'workExperience': FieldValue.arrayRemove([
          {'id': id}
        ]),
      });

      setState(() {
        _jobSeekerFuture = _fetchJobSeekerData();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Experience deleted successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete experience: $e')),
      );
    }
  }

  Widget _buildDocumentsSection(JobSeeker jobSeeker) {
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Resume',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  tooltip: 'Edit Resume',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EditDocumentsScreen(jobSeeker: jobSeeker),
                      ),
                    ).then((_) => setState(() {
                      _jobSeekerFuture = _fetchJobSeekerData();
                    }));
                  },
                ),
              ],
            ),
            const Divider(height: 20),
            if (jobSeeker.resumeUrl == null)
              Text(
                'No resume uploaded',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey,
                ),
              )
            else
              _buildDocumentTile('Resume', jobSeeker.resumeUrl!),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentTile(String title, String url) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.insert_drive_file, size: 36),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      trailing: IconButton(
        icon: const Icon(Icons.download),
        tooltip: 'Download',
        onPressed: () => _launchURL(url),
      ),
    );
  }
  Widget _buildVerificationSection(JobSeeker jobSeeker) {
    if (jobSeeker.isVerified == true) return const SizedBox();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      color: Colors.blue[50],
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.verified_user, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  'Get Verified',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[800],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Verify your profile to increase your chances of getting hired',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                // Implement verification flow
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Getting a badge for Premium Job Seeker will start soon. Stay tuned!')),
                );
              },
              child: const Text('Start Verification'),
            ),
          ],
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