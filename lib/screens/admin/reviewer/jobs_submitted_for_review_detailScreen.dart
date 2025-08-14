import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../models/employer_model/employer_model.dart';
import '../../../models/job_model.dart';
import '../employers_profile_for_admins_screen.dart';

class JobsSubmittedForReviewDetailScreen extends StatefulWidget {
  final JobModel job;

  const JobsSubmittedForReviewDetailScreen({super.key, required this.job});

  @override
  State<JobsSubmittedForReviewDetailScreen> createState() => _JobsSubmittedForReviewDetailScreenState();
}

class _JobsSubmittedForReviewDetailScreenState extends State<JobsSubmittedForReviewDetailScreen> {
  Employer? _employer;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchEmployerDetails();
  }

  Future<void> _fetchEmployerDetails() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('employers')
          .doc(widget.job.employerId)
          .get();

      if (doc.exists) {
        setState(() {
          _employer = Employer.fromMap(doc.data()!);
        });
      }
    } catch (e) {
      debugPrint("Error fetching employer: $e");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _buildInfoSection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.indigo,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          content,
          style: const TextStyle(fontSize: 16),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildChipList(String title, List<String> items) {
    if (items.isEmpty) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.indigo,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: items.map((item) => Chip(label: Text(item))).toList(),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildStatusChip(String status) {
    Color chipColor;
    switch (status) {
      case 'Approved':
        chipColor = Colors.green;
        break;
      case 'Rejected':
        chipColor = Colors.red;
        break;
      case 'Pending':
        chipColor = Colors.orange;
        break;
      case 'Under Review':
        chipColor = Colors.blue;
        break;
      default:
        chipColor = Colors.grey;
    }

    return Chip(
      label: Text(
        status,
        style: const TextStyle(color: Colors.white),
      ),
      backgroundColor: chipColor,
    );
  }

  Widget _buildEmployerInfo() {
    if (_employer == null) return const SizedBox();

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EmployersProfileForAdminsScreen(employer: _employer!),
          ),
        );
      },
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: Colors.indigo.shade100,
                backgroundImage: _employer!.logoUrl != null
                    ? NetworkImage(_employer!.logoUrl!)
                    : null,
                child: _employer!.logoUrl == null
                    ? const Icon(Icons.business, color: Colors.indigo)
                    : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _employer!.companyName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (_employer!.region != null || _employer!.city != null)
                      Text(
                        "${_employer!.region ?? ''}${_employer!.region != null && _employer!.city != null ? ', ' : ''}${_employer!.city ?? ''}",
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final job = widget.job;
    final dateFormat = DateFormat('MMMM d, y');

    return Scaffold(
      appBar: AppBar(
        title: const Text("Job Details"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchEmployerDetails,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Job Title and Status
            Row(
              children: [
                Expanded(
                  child: Text(
                    job.title,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                _buildStatusChip(job.approvalStatus),
              ],
            ),
            const SizedBox(height: 16),

            // Employer Info
            _buildEmployerInfo(),
            const SizedBox(height: 20),

            // Basic Info Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Basic Information",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.indigo,
                      ),
                    ),
                    const Divider(),
                    const SizedBox(height: 8),

                    // Job Type and Experience Level
                    Row(
                      children: [
                        Expanded(
                          child: _buildInfoSection("Job Type", job.jobType),
                        ),
                        Expanded(
                          child: _buildInfoSection(
                              "Experience Level", job.experienceLevel),
                        ),
                      ],
                    ),

                    // Job Site and Positions
                    Row(
                      children: [
                        Expanded(
                          child: _buildInfoSection(
                              "Work Location", job.jobSite ?? "Not specified"),
                        ),
                        Expanded(
                          child: _buildInfoSection(
                              "Positions Available", job.numberOfPositions.toString()),
                        ),
                      ],
                    ),

                    // Salary and Education
                    _buildInfoSection("Salary Range", job.salaryRange),
                    _buildInfoSection("Education Level", job.educationLevel),

                    // Gender Requirement if specified
                    if (job.requiredGender != null && job.requiredGender != 'Any')
                      _buildInfoSection("Gender Preference", job.requiredGender!),

                    // Dates
                    _buildInfoSection("Posted Date", dateFormat.format(job.datePosted)),
                    _buildInfoSection(
                        "Application Deadline", dateFormat.format(job.applicationDeadline)),

                    // Location if available
                    if (job.region != null || job.city != null)
                      _buildInfoSection(
                          "Job Location",
                          "${job.region ?? ''}${job.region != null && job.city != null ? ', ' : ''}${job.city ?? ''}"
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Job Description
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Job Description",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.indigo,
                      ),
                    ),
                    const Divider(),
                    const SizedBox(height: 8),
                    Text(job.description),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Skills and Requirements
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildChipList("Required Skills", job.requiredSkills),
                    _buildChipList("Fields of Study", job.fieldsOfStudy),
                    _buildChipList("Languages Required", job.languages),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Review Information (if reviewed)
            if (job.reviewStatus != 'Under Review' && job.reviewStatus != 'Not submitted')
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Review Information",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.indigo,
                        ),
                      ),
                      const Divider(),
                      const SizedBox(height: 8),
                      _buildInfoSection("Review Status", job.reviewStatus),
                      if (job.reviewedBy != null)
                        _buildInfoSection("Reviewed By", job.reviewedBy!),

                      if (job.reviewMessage != null)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Review Message:",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.indigo,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(job.reviewMessage!),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}