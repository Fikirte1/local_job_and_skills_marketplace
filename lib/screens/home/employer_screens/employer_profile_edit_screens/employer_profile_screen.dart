import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';

import '../../../../models/employer_model/employer_model.dart';
import '../../../../services/auth_service.dart';

import '../../../auth/signIn_screen.dart';
import 'EditEmployerDocumentsScreen.dart';
import 'edit_employer_profile_screen.dart';
import 'edit_employer_about_screen.dart';

class EmployerProfileScreen extends StatefulWidget {
  const EmployerProfileScreen({super.key});

  @override
  State<EmployerProfileScreen> createState() => _EmployerProfileScreenState();
}

class _EmployerProfileScreenState extends State<EmployerProfileScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _imagePicker = ImagePicker();
  late Future<Employer> _employerFuture;
  final _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _employerFuture = _fetchEmployerData();
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

  Future<Employer> _fetchEmployerData() async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not logged in');

      final doc = await _firestore.collection('employers').doc(user.uid).get();
      if (!doc.exists) throw Exception('Profile not found');

      return Employer.fromMap(doc.data()!);
    } catch (e) {
      debugPrint('Error fetching employer data: $e');
      rethrow;
    }
  }

  Future<void> _updateLogo() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final pickedFile = await _imagePicker.pickImage(source: ImageSource.gallery);
      if (pickedFile == null) return;

      // Show loading indicator
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Uploading company logo...')),
      );

      // Upload to Firebase Storage
      final file = File(pickedFile.path);
      final ref = _storage.ref().child('employer_logos/${user.uid}');
      final uploadTask = ref.putFile(file);
      final snapshot = await uploadTask.whenComplete(() {});
      final downloadUrl = await snapshot.ref.getDownloadURL();

      // Update Firestore
      await _firestore.collection('employers').doc(user.uid).update({
        'logoUrl': downloadUrl,
      });

      // Refresh data
      setState(() {
        _employerFuture = _fetchEmployerData();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Company logo updated successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update logo: $e')),
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
        title: const Text('Company Profile'),
        centerTitle: true,
      ),
      body: FutureBuilder<Employer>(
        future: _employerFuture,
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
                        _employerFuture = _fetchEmployerData();
                      });
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final employer = snapshot.data!;
          return RefreshIndicator(
            onRefresh: () async {
              setState(() {
                _employerFuture = _fetchEmployerData();
              });
            },
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildProfileHeader(employer),
                  const SizedBox(height: 24),
                  _buildBasicInfoSection(employer),
                  const SizedBox(height: 24),
                  _buildAboutSection(employer),
                  const SizedBox(height: 24),
                  _buildContactSection(employer),
                  const SizedBox(height: 24),
                  _buildDocumentsSection(employer),
                  const SizedBox(height: 24),
                  _buildVerificationSection(employer),
                  const SizedBox(height: 24),

                  // Logout Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _logout,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade50,
                        foregroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: BorderSide(color: Colors.red.shade200),
                        ),
                      ),
                      child: const Text('Logout'),
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

  Widget _buildProfileHeader(Employer employer) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            GestureDetector(
              onTap: _updateLogo,
              child: CircleAvatar(
                radius: 60,
                backgroundColor: Colors.grey[200],
                backgroundImage: employer.logoUrl != null
                    ? NetworkImage(employer.logoUrl!)
                    : const AssetImage('assets/default_company.png') as ImageProvider,
                child: employer.logoUrl == null
                    ? const Icon(Icons.business, size: 60, color: Colors.grey)
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
              employer.companyName,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            if (employer.industry != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  employer.industry!,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.blue[700],
                  ),
                ),
              ),
            if (employer.region != null || employer.city != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.location_on, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      [employer.city, employer.region].where((e) => e != null).join(', '),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 8),
            if (employer.isVerified == true)
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
                      'Verified Company',
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

  Widget _buildBasicInfoSection(Employer employer) {
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
                  'Company Information',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  tooltip: 'Edit Company Info',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EditEmployerProfileScreen(employer: employer),
                      ),
                    ).then((_) => setState(() {
                      _employerFuture = _fetchEmployerData();
                    }));
                  },
                ),
              ],
            ),
            const Divider(height: 20),
            _buildInfoTile('Company Name', employer.companyName, Icons.business),
            if (employer.industry != null)
              _buildInfoTile('Industry', employer.industry!, Icons.category),
            if (employer.website != null)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.link, color: Colors.grey),
                title: Text(
                  'Website',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey,
                  ),
                ),
                subtitle: InkWell(
                  onTap: () => _launchURL(employer.website!),
                  child: Text(
                    employer.website!,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.blue,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAboutSection(Employer employer) {
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
                  'About Company',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  tooltip: 'Edit About Company',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EditEmployerAboutScreen(employer: employer),
                      ),
                    ).then((_) => setState(() {
                      _employerFuture = _fetchEmployerData();
                    }));
                  },
                ),
              ],
            ),
            const Divider(height: 20),
            Text(
              employer.aboutCompany,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactSection(Employer employer) {
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
                  'Contact Information',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  tooltip: 'Edit Contact Info',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EditEmployerProfileScreen(employer: employer),
                      ),
                    ).then((_) => setState(() {
                      _employerFuture = _fetchEmployerData();
                    }));
                  },
                ),
              ],
            ),
            const Divider(height: 20),
            _buildInfoTile('Email', employer.email, Icons.email),
            _buildInfoTile('Contact Number', employer.contactNumber, Icons.phone),
            if (employer.region != null || employer.city != null)
              _buildInfoTile(
                'Location',
                [employer.city, employer.region].where((e) => e != null).join(', '),
                Icons.location_on,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentsSection(Employer employer) {
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
                  'Company Documents',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  tooltip: 'Edit Documents',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EditEmployerDocumentsScreen(employer: employer),
                      ),
                    ).then((_) => setState(() {
                      _employerFuture = _fetchEmployerData();
                    }));
                  },
                ),
              ],
            ),
            const Divider(height: 20),
            if (employer.identityDocumentUrl == null)
              Text(
                'No verification documents uploaded',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey,
                ),
              )
            else
              _buildDocumentTile(
                'Verification Document',
                employer.identityDocumentUrl!,
                employer.documentType ?? 'Document',
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildVerificationSection(Employer employer) {
    // If already verified, show a success card instead of nothing
    if (employer.isVerified) {
      return Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.green.shade200),
        ),
        color: Colors.green.shade50,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(Icons.verified, color: Colors.green.shade800),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Your company is verified!',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Job seekers will see your verified status, increasing trust in your company.',
                style: TextStyle(color: Colors.green.shade600),
              ),
              if (employer.verifiedAt != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Verified on: ${DateFormat('MMM d, yyyy').format(employer.verifiedAt!)}',
                  style: TextStyle(
                    color: Colors.green.shade600,
                    fontSize: 12,
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }

    // Determine status color and icon
    Color statusColor;
    IconData statusIcon;
    String statusTitle;
    String statusDescription;

    switch (employer.verificationStatus) {
      case 'Pending Review':
        statusColor = Colors.blue;
        statusIcon = Icons.hourglass_top;
        statusTitle = 'Verification in Progress';
        statusDescription = 'We\'re reviewing your documents. This usually takes 1-2 business days.';
        break;
      case 'Rejected':
        statusColor = Colors.orange;
        statusIcon = Icons.warning;
        statusTitle = 'Verification Needed';
        statusDescription = 'Your submission needs attention before we can verify your company.';
        break;
      default: // Unverified
        statusColor = Colors.blue;
        statusIcon = Icons.verified_user;
        statusTitle = 'Get Verified';
        statusDescription = 'Verify your company to increase trust with job seekers';
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: statusColor.withOpacity(0.3)),
      ),
      color: statusColor.withOpacity(0.05),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(statusIcon, color: statusColor),
                const SizedBox(width: 12),
                Text(
                  statusTitle,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Progress indicator for pending status
            if (employer.verificationStatus == 'Pending Review') ...[
              LinearProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                backgroundColor: statusColor.withOpacity(0.1),
                minHeight: 6,
                borderRadius: BorderRadius.circular(3),
              ),
              const SizedBox(height: 12),
            ],

            Text(
              statusDescription,
              style: TextStyle(color: Colors.grey.shade700),
            ),
            const SizedBox(height: 16),

            // Action button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.upload_file, size: 20),
                label: Text(
                  employer.verificationStatus == 'Rejected'
                      ? 'Resubmit Documents'
                      : 'Upload Verification Documents',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: statusColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EditEmployerDocumentsScreen(employer: employer),
                    ),
                  ).then((_) => setState(() {
                    _employerFuture = _fetchEmployerData();
                  }));
                },
              ),
            ),

            // Status details
            if (employer.verificationStatus != 'Unverified') ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline,
                            size: 18,
                            color: Colors.grey.shade600),
                        const SizedBox(width: 8),
                        Text(
                          'Verification Status',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      employer.verificationStatus,
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (employer.verificationSubmittedAt != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Submitted: ${DateFormat('MMM d, yyyy').format(employer.verificationSubmittedAt!)}',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                    if (employer.verificationMessage != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Note: ${employer.verificationMessage}',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentTile(String title, String url, String type) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.insert_drive_file, size: 36),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Text(type),
      trailing: IconButton(
        icon: const Icon(Icons.download),
        tooltip: 'Download',
        onPressed: () => _launchURL(url),
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
                    color: const Color.fromARGB(255, 190, 114, 114),
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