import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:local_job_and_skills_marketplace/screens/home/job_seeker_screens/jobs_search/utilsforstyle.dart' as custom_utils;
import 'package:local_job_and_skills_marketplace/screens/home/job_seeker_screens/jobs_search/utilsforstyle.dart';
import '../../../../models/applications_model.dart';
import '../../../../models/employer_model/employer_model.dart';
import '../../../../models/job _seeker_models/education_model.dart';
import '../../../../models/job _seeker_models/job_seeker_model.dart';
import '../../../../models/job _seeker_models/work_experience_model.dart';
import '../../../../models/job_model.dart';
import '../../employer_screens/EmployerProfileScreenForJobSeeker.dart';
import '../coin_system/coin_balance_widget.dart';
import '../coin_system/coin_purchase_flow.dart';
import '../coin_system/coin_service.dart';
import '../job_seeker_applications/job_application_validator.dart';

class JobCard extends StatefulWidget {
  final JobModel job;
  final Employer employer;
  final VoidCallback? onApply;
  final VoidCallback? onSave;
  final bool showSaveButton;

  const JobCard({
    Key? key,
    required this.job,
    required this.employer,
    this.onApply,
    this.onSave,
    this.showSaveButton = true,
  }) : super(key: key);

  @override
  JobCardState createState() => JobCardState();
}

class JobCardState extends State<JobCard> {
  bool _isApplying = false;
  ApplicationStatus _applicationStatus = ApplicationStatus.applied;
  bool _showFullDescription = false;
  bool _hasApplied = false;
  String? _applicationId;
  bool _isSaved = false;
  bool _isCheckingApplication = true; // Add this line


  @override
  void initState() {
    super.initState();
    _fetchApplicationStatus();
    _checkIfJobIsSaved();
  }

  bool get _isJobInactive {
    if (widget.job.status != 'Open') return true;
    if (widget.job.applicationDeadline.isBefore(DateTime.now())) return true;
    if (_hasApplied) return true;
    return false;
  }

  Future<void> _fetchApplicationStatus() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      if (mounted) {
        setState(() => _isCheckingApplication = false);
      }
      return;
    }

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('applications')
          .where('jobId', isEqualTo: widget.job.jobId)
          .where('jobSeekerId', isEqualTo: userId)
          .limit(1)
          .get();

      if (mounted) {
        setState(() {
          if (snapshot.docs.isNotEmpty) {
            _applicationStatus = ApplicationModel.parseStatus(snapshot.docs.first['status']);
            _hasApplied = true;
            _applicationId = snapshot.docs.first.id;
          }
          _isCheckingApplication = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching application status: $e");
      if (mounted) {
        setState(() => _isCheckingApplication = false);
      }
    }
  }

  Future<void> _checkIfJobIsSaved() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('savedJobs')
          .doc('${userId}_${widget.job.jobId}')
          .get();

      if (mounted) {
        setState(() {
          _isSaved = doc.exists;
        });
      }
    } catch (e) {
      debugPrint("Error checking saved job: $e");
    }
  }

  Future<void> _toggleSaveJob() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please sign in to save jobs")),
      );
      return;
    }

    setState(() => _isSaved = !_isSaved);

    try {
      if (_isSaved) {
        await FirebaseFirestore.instance
            .collection('savedJobs')
            .doc('${userId}_${widget.job.jobId}')
            .set({
          'jobId': widget.job.jobId,
          'userId': userId,
          'savedAt': Timestamp.now(),
          'jobData': widget.job.toMap(),
          'employerData': widget.employer.toMap(),
        });
      } else {
        await FirebaseFirestore.instance
            .collection('savedJobs')
            .doc('${userId}_${widget.job.jobId}')
            .delete();
      }

      if (widget.onSave != null) {
        widget.onSave!();
      }
    } catch (e) {
      setState(() => _isSaved = !_isSaved);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: ${e.toString()}")),
      );
    }
  }

  Future<void> _applyForJob() async {
    if (_hasApplied) return;

    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please sign in to apply")),
      );
      return;
    }

    // First check coin balance
    final hasEnoughCoins = await CoinService.canApplyForJob(userId);
    if (!hasEnoughCoins) {
      _showCoinPurchasePrompt(context);
      return;
    }

    // Fetch job seeker data
    final userDoc = await FirebaseFirestore.instance
        .collection('jobSeekers')
        .doc(userId)
        .get();

    if (!userDoc.exists) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please complete your profile first")),
      );
      return;
    }

    final jobSeeker = JobSeeker.fromMap(userDoc.data()!);
    final validation = JobApplicationValidator.validateApplication(jobSeeker, widget.job);

    if (!validation.canApply) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(validation.message)),
      );
      return;
    }

    if (validation.requiresConfirmation) {
      final shouldProceed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Low Compatibility"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(validation.message),
              const SizedBox(height: 16),
              Text(
                "Job Requirements vs Your Profile:",
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              _buildComparisonItem(
                  "Skills",
                  widget.job.requiredSkills.join(", "),
                  jobSeeker.skills?.join(", ") ?? "Not specified"
              ),
              _buildComparisonItem(
                  "Education",
                  widget.job.educationLevel,
                  _getHighestEducationLevel(jobSeeker.educationHistory)
              ),
              _buildComparisonItem(
                  "Experience",
                  widget.job.experienceLevel,
                  _getExperienceLevel(jobSeeker.workExperience)
              ),
              _buildComparisonItem(
                  "Location",
                  widget.job.city ?? widget.job.region ?? "Remote",
                  jobSeeker.city ?? jobSeeker.region ?? "Not specified"
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text("Apply Anyway"),
            ),
          ],
        ),
      );

      if (shouldProceed != true) return;
    } else if (validation.compatibilityScore < JobApplicationValidator.goodCompatibility) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(validation.message)),
      );
    }

    // Deduct coin before submitting application
    final coinDeducted = await CoinService.deductCoin(
      userId: userId,
      amount: 1,
      type: 'application',
      jobId: widget.job.jobId,
    );

    if (!coinDeducted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to deduct coin. Please try again.")),
      );
      return;
    }

    await _submitApplication(jobSeeker, validation.compatibilityScore);
  }

  void _showCoinPurchasePrompt(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Out of Coins'),
        content: const Text(
          'You have used all your free application coins. '
              'Please purchase more coins to continue applying for jobs.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Later'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CoinPurchaseFlow()),

              );
            },
            child: const Text('Buy Coins'),
          ),
        ],
      ),
    );
  }

  Widget _buildComparisonItem(String title, String jobValue, String seekerValue) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              "$title:",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Job: $jobValue",
                  style: TextStyle(color: Colors.grey[700]),
                ),
                Text(
                  "You: $seekerValue",
                  style: TextStyle(color: Colors.grey[700]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getHighestEducationLevel(List<Education>? educationHistory) {
    if (educationHistory == null || educationHistory.isEmpty) return "Not specified";
    final highest = JobApplicationValidator.getHighestEducation(educationHistory);
    return "${highest.educationType}: ${highest.degree} in ${highest.fieldOfStudy}";
  }

  String _getExperienceLevel(List<WorkExperience>? workExperience) {
    if (workExperience == null || workExperience.isEmpty) return "No experience";
    final years = JobApplicationValidator.calculateTotalExperienceYears(workExperience);

    if (years <= 2) return "Entry level ($years years)";
    if (years <= 5) return "Mid level ($years years)";
    return "Senior level ($years+ years)";
  }

  Future<void> _submitApplication(JobSeeker jobSeeker, double compatibilityScore) async {
    setState(() => _isApplying = true);

    try {
      final now = DateTime.now();

      final docRef = await FirebaseFirestore.instance.collection('applications').add({
        'jobId': widget.job.jobId,
        'jobSeekerId': jobSeeker.userId,
        'employerId': widget.job.employerId,
        'status': ApplicationStatus.applied.toString().split('.').last,
        'appliedDate': Timestamp.fromDate(now),
        'statusUpdatedDate': Timestamp.fromDate(now),
        'statusNote': 'Application submitted',
        'interviewScheduleId': null,
        'interviewDetailsId': null,
        'compatibilityScore': compatibilityScore,
      });

      if (mounted) {
        setState(() {
          _applicationId = docRef.id;
          _hasApplied = true;
          _applicationStatus = ApplicationStatus.applied;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Application submitted!")),
        );

        if (widget.onApply != null) widget.onApply!();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error applying: ${e.toString()}")),
        );
        setState(() {
          _hasApplied = false;
          _applicationStatus = ApplicationStatus.applied;
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isApplying = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.borderColor, width: 1),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: _showJobDetails,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeaderSection(),
              const SizedBox(height: 12),
              _buildJobDetailsSection(),
              const SizedBox(height: 12),
              _buildDescriptionSection(),
              const SizedBox(height: 12),
              _buildFooterSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CompanyLogo(
          logoUrl: widget.employer.logoUrl,
          companyName: widget.employer.companyName,
          size: 48,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.job.title,
                style: AppTextStyles.headlineSmall,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                widget.employer.companyName,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.secondaryText,
                ),
              ),
            ],
          ),
        ),
        if (widget.showSaveButton)
          IconButton(
            icon: Icon(
              _isSaved ? Icons.bookmark : Icons.bookmark_border,
              color: _isSaved ? AppColors.primary : AppColors.secondaryText,
            ),
            onPressed: _toggleSaveJob,
          ),
      ],
    );
  }

  Widget _buildJobDetailsSection() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        ChipWidget(
          icon: Icons.location_on,
          label: widget.job.city ?? widget.job.region ?? 'Remote',
        ),
        ChipWidget(
          icon: Icons.work_outline,
          label: widget.job.jobType,
        ),
        ChipWidget(
          icon: Icons.attach_money,
          label: widget.job.salaryRange,
        ),
        ChipWidget(
          icon: Icons.timelapse,
          label: '${widget.job.numberOfPositions} position(s)',
        ),
      ],
    );
  }

  Widget _buildDescriptionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.job.description,
          maxLines: _showFullDescription ? 10 : 3,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.bodyMedium,
        ),
        if (widget.job.description.length > 100)
          TextButton(
            onPressed: () => setState(() => _showFullDescription = !_showFullDescription),
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: const Size(50, 30),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              _showFullDescription ? "Show less" : "Show more",
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildFooterSection() {
    final daysRemaining = widget.job.applicationDeadline.difference(DateTime.now()).inDays;
    final deadlineText = daysRemaining > 0
        ? 'Closes in $daysRemaining ${daysRemaining == 1 ? 'day' : 'days'}'
        : 'Expired';

    return Row(
      children: [
        Expanded(
          child: Text(
            deadlineText,
            style: AppTextStyles.bodySmall.copyWith(
              color: daysRemaining > 0 ? AppColors.success : AppColors.error,
            ),
          ),
        ),
        if (_isCheckingApplication)
          const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
            ),
          )
        else
          ElevatedButton(
            onPressed: _isJobInactive ? null : _applyForJob,
            style: ElevatedButton.styleFrom(
              backgroundColor: _isJobInactive
                  ? AppColors.disabled
                  : _hasApplied ? AppColors.disabled : AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            child: _isApplying
                ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            )
                : Text(
              _hasApplied ? "Applied" : "Apply Now",
              style: AppTextStyles.labelLarge.copyWith(
                color: Colors.white,
              ),
            ),
          ),
      ],
    );
  }

  void _showJobDetails() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.7,
            maxChildSize: 0.9,
            minChildSize: 0.5,
            builder: (context, scrollController) {
              return Stack(
                children: [
                  SingleChildScrollView(
                    controller: scrollController,
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 24),
                          _buildJobDetailHeader(),
                          const SizedBox(height: 24),
                          _buildJobDetailInfoSection(),
                          const SizedBox(height: 24),
                          _buildJobDescriptionSection(),
                          const SizedBox(height: 24),
                          _buildSkillsSection(),
                          const SizedBox(height: 24),
                          _buildRequirementsSection(),
                          const SizedBox(height: 80), // Space for the apply button
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: _buildBottomActionBar(),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildJobDetailHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.job.title,
          style: AppTextStyles.headlineMedium,
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => EmployerProfileScreenForJobSeeker(
                  employer: widget.employer,
                ),
              ),
            );
          },
          child: Row(
            children: [
              CompanyLogo(
                logoUrl: widget.employer.logoUrl,
                companyName: widget.employer.companyName,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                widget.employer.companyName,
                style: AppTextStyles.titleMedium.copyWith(
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 4),
              if (widget.employer.isVerified)
                const Icon(Icons.verified, color: AppColors.primary, size: 16),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Icon(Icons.access_time, size: 16, color: AppColors.secondaryText),
            const SizedBox(width: 4),
            Text(
              custom_utils.DateUtils.formatRelativeDate(widget.job.datePosted),
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.secondaryText,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: widget.job.status == 'Open'
                    ? AppColors.success.withOpacity(0.1)
                    : AppColors.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                widget.job.status,
                style: AppTextStyles.labelSmall.copyWith(
                  color: widget.job.status == 'Open'
                      ? AppColors.success
                      : AppColors.error,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildJobDetailInfoSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          _buildDetailRow(
            icon: Icons.work_outline,
            label: 'Job Type',
            value: widget.job.jobType,
          ),
          const Divider(height: 24),
          _buildDetailRow(
            icon: Icons.attach_money,
            label: 'Salary',
            value: widget.job.salaryRange,
          ),
          const Divider(height: 24),
          _buildDetailRow(
            icon: Icons.location_on,
            label: 'Location',
            value: widget.job.city ?? widget.job.region ?? 'Remote',
          ),
          const Divider(height: 24),
          _buildDetailRow(
            icon: Icons.timelapse,
            label: 'Positions',
            value: widget.job.numberOfPositions.toString(),
          ),
          const Divider(height: 24),
          _buildDetailRow(
            icon: Icons.calendar_today,
            label: 'Deadline',
            value: DateFormat('MMM dd, yyyy').format(widget.job.applicationDeadline),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.secondaryText),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.secondaryText,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: AppTextStyles.bodyMedium,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildJobDescriptionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Job Description',
          style: AppTextStyles.titleLarge,
        ),
        const SizedBox(height: 8),
        Text(
          widget.job.description,
          style: AppTextStyles.bodyMedium,
        ),
      ],
    );
  }

  Widget _buildSkillsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Required Skills',
          style: AppTextStyles.titleLarge,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: widget.job.requiredSkills
              .map((skill) => Chip(
            label: Text(skill),
            backgroundColor: AppColors.surfaceVariant,
          ))
              .toList(),
        ),
      ],
    );
  }

  Widget _buildRequirementsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Requirements',
          style: AppTextStyles.titleLarge,
        ),
        const SizedBox(height: 8),
        _buildRequirementItem('Experience Level', widget.job.experienceLevel),
        _buildRequirementItem('Education Level', widget.job.educationLevel),
        _buildRequirementItem('Job Category', widget.job.jobCategory),
        if (widget.job.languages.isNotEmpty)
          _buildRequirementItem(
              'Languages', widget.job.languages.join(', ')),
      ],
    );
  }

  Widget _buildRequirementItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.circle, size: 8, color: AppColors.secondaryText),
          const SizedBox(width: 8),
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: '$label: ',
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextSpan(
                    text: value,
                    style: AppTextStyles.bodyMedium,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActionBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          if (widget.showSaveButton)
            IconButton(
              icon: Icon(
                _isSaved ? Icons.bookmark : Icons.bookmark_border,
                color: _isSaved ? AppColors.primary : AppColors.secondaryText,
              ),
              onPressed: _toggleSaveJob,
            ),
          const SizedBox(width: 8),
          Expanded(
            child: _isCheckingApplication
                ? const Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                ),
              ),
            )
                : !_isJobInactive
                ? _hasApplied
                ? Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.getStatusColor(_applicationStatus)
                    .withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  _getStatusText(_applicationStatus),
                  style: AppTextStyles.labelLarge.copyWith(
                    color: AppColors.getStatusColor(
                        _applicationStatus),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            )
                : ElevatedButton(
              onPressed: _isApplying ? null : _applyForJob,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isApplying
                  ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
                  : Text(
                'Apply Now',
                style: AppTextStyles.labelLarge.copyWith(
                  color: Colors.white,
                ),
              ),
            )
                : Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  _hasApplied
                      ? 'You have already applied'
                      : 'No longer accepting applications',
                  style: AppTextStyles.labelLarge.copyWith(
                    color: AppColors.error,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getStatusText(ApplicationStatus status) {
    switch (status) {
      case ApplicationStatus.applied:
        return "Applied";
      case ApplicationStatus.acceptedForInterview:
        return "Accepted for Interview";
      case ApplicationStatus.rejected:
        return "Rejected";
      case ApplicationStatus.interviewScheduled:
        return "Interview Scheduled";
      case ApplicationStatus.interviewCompleted:
        return "Interview Completed";
      case ApplicationStatus.hired:
        return "Hired";
      case ApplicationStatus.needsResubmission:
        return "Needs Resubmission";
      case ApplicationStatus.interviewStarted:
        return "Interview Started";
      case ApplicationStatus.responseSubmitted:
        return "Response Submitted";
      case ApplicationStatus.winnerAnnounced:
        return "Selected as Winner";
    }
  }
}

