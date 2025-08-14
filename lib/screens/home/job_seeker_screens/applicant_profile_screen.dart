/*
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../models/job _seeker_models/job_seeker_model.dart';
import '../../../models/employer_model/employer_model.dart';

class ApplicantProfileScreen extends StatelessWidget {
  final dynamic applicant; // Can be either JobSeeker or Employer
  final bool isJobSeeker;

  const ApplicantProfileScreen({
    Key? key,
    required this.applicant,
    required this.isJobSeeker,
  }) : super(key: key);

  void _launchURL(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = isJobSeeker ? (applicant as JobSeeker).name : (applicant as Employer).companyName;
    final email = isJobSeeker ? (applicant as JobSeeker).email : (applicant as Employer).email;
    final role = isJobSeeker ? 'Job Seeker' : 'Employer';

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "$name's Profile",
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
            color: Colors.white,
          ),
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.indigo.shade400, Colors.indigo.shade700],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        centerTitle: true,
        elevation: 4,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Header
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundImage: isJobSeeker
                        ? (applicant as JobSeeker).profilePictureUrl != null
                        ? NetworkImage((applicant as JobSeeker).profilePictureUrl!)
                        : const AssetImage('assets/user/img.png') as ImageProvider
                        : (applicant as Employer).logoUrl != null
                        ? NetworkImage((applicant as Employer).logoUrl!)
                        : const AssetImage('assets/company/default_company.png') as ImageProvider,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.indigo,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    role,
                    style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Contact Information
            _buildSectionTitle("Contact Information"),
            _buildListTile(Icons.email, "Email", email),
            if ((isJobSeeker && (applicant as JobSeeker).contactNumber != null) ||
                (!isJobSeeker && (applicant as Employer).contactNumber != null))
              _buildListTile(
                Icons.phone,
                "Contact Number",
                isJobSeeker
                    ? (applicant as JobSeeker).contactNumber!
                    : (applicant as Employer).contactNumber!,
              ),
            const Divider(height: 30),

            // About Section
            _buildSectionTitle(isJobSeeker ? "About Me" : "About Company"),
            if ((isJobSeeker && (applicant as JobSeeker).aboutMe != null) ||
                (!isJobSeeker && (applicant as Employer).aboutCompany != null))
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  isJobSeeker
                      ? (applicant as JobSeeker).aboutMe!
                      : (applicant as Employer).aboutCompany!,
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            if ((isJobSeeker && (applicant as JobSeeker).location != null) ||
                (!isJobSeeker && (applicant as Employer).location != null))
              _buildListTile(
                Icons.location_on,
                "Location",
                isJobSeeker
                    ? (applicant as JobSeeker).location!
                    : (applicant as Employer).location!,
              ),
            const Divider(height: 30),

            // Professional Details
            _buildSectionTitle("Professional Details"),
            if (!isJobSeeker) ...[
              if ((applicant as Employer).industry != null)
                _buildListTile(Icons.business, "Industry", (applicant as Employer).industry!),
              if ((applicant as Employer).companySize != null)
                _buildListTile(Icons.people, "Company Size",
                    (applicant as Employer).companySize!.toString()),
            ],
            if (isJobSeeker && (applicant as JobSeeker).skills != null && (applicant as JobSeeker).skills!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Wrap(
                  spacing: 8.0,
                  children: (applicant as JobSeeker).skills!
                      .map((skill) => Chip(
                    label: Text(skill),
                    backgroundColor: Colors.indigo.shade50,
                  ))
                      .toList(),
                ),
              ),
            if (isJobSeeker && (applicant as JobSeeker).availability != null)
              _buildListTile(
                Icons.access_time,
                "Availability",
                (applicant as JobSeeker).availability!,
              ),
            const Divider(height: 30),

            // Documents Section
            if (isJobSeeker && (applicant as JobSeeker).resumeUrl != null) ...[
              _buildSectionTitle("Documents"),
              ListTile(
                leading: const Icon(Icons.description, color: Colors.indigo),
                title: const Text("Resume"),
                trailing: IconButton(
                  icon: const Icon(Icons.open_in_new, color: Colors.indigo),
                  onPressed: () => _launchURL((applicant as JobSeeker).resumeUrl!),
                ),
              ),
            ],
            if (!isJobSeeker && (applicant as Employer).website != null) ...[
              _buildSectionTitle("Website"),
              ListTile(
                leading: const Icon(Icons.language, color: Colors.indigo),
                title: const Text("Company Website"),
                trailing: IconButton(
                  icon: const Icon(Icons.open_in_new, color: Colors.indigo),
                  onPressed: () => _launchURL((applicant as Employer).website!),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.indigo,
        ),
      ),
    );
  }

  Widget _buildListTile(IconData icon, String title, String subtitle) {
    return ListTile(
      leading: Icon(icon, color: Colors.indigo),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Text(subtitle),
    );
  }
}*/
