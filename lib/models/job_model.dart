import 'package:cloud_firestore/cloud_firestore.dart';

class JobModel {
  final String jobId;
  final String title;
  final String description;
  final String? region;
  final String? city;
  final String? jobSite;
  final List<String> requiredSkills;
  final String employerId;
  final String status;
  final DateTime datePosted;
  final String salaryRange;
  final String jobType;
  final DateTime applicationDeadline;
  final String experienceLevel;
  final String approvalStatus;
  final String postStatus;
  final String reviewStatus;
  final String? reviewMessage;
  final String? reviewedBy;
  final DateTime? reviewedAt; // <-- Added field
  final String? requiredGender;
  final List<String> fieldsOfStudy;
  final int numberOfPositions;
  final String jobCategory;
  final String educationLevel;
  final List<String> languages;

  JobModel({
    required this.jobId,
    required this.title,
    required this.description,
    this.region,
    this.city,
    this.jobSite,
    required this.requiredSkills,
    required this.employerId,
    required this.status,
    required this.datePosted,
    required this.salaryRange,
    required this.jobType,
    required this.applicationDeadline,
    required this.experienceLevel,
    required this.approvalStatus,
    required this.postStatus,
    required this.reviewStatus,
    this.reviewMessage,
    this.reviewedBy,
    this.reviewedAt, // <-- Added here
    this.requiredGender,
    required this.fieldsOfStudy,
    required this.numberOfPositions,
    required this.jobCategory,
    required this.educationLevel,
    required this.languages,
  });

  factory JobModel.fromMap(Map<String, dynamic> data, String jobId) {
    return JobModel(
      jobId: jobId,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      region: data['region'],
      city: data['city'],
      jobSite: data['jobSite'],
      requiredSkills: List<String>.from(data['requiredSkills'] ?? []),
      employerId: data['employerId'] ?? '',
      status: data['status'] ?? 'Open',
      datePosted: (data['datePosted'] as Timestamp?)?.toDate() ?? DateTime.now(),
      salaryRange: data['salaryRange'] ?? '',
      jobType: data['jobType'] ?? 'Full-time',
      applicationDeadline: (data['applicationDeadline'] as Timestamp?)?.toDate() ?? DateTime.now().add(Duration(days: 30)),
      experienceLevel: data['experienceLevel'] ?? 'Entry',
      approvalStatus: data['approvalStatus'] ?? 'Pending',
      postStatus: data['postStatus'] ?? 'Draft',
      reviewStatus: data['reviewStatus'] ?? 'Not submitted',
      reviewMessage: data['reviewMessage'],
      reviewedBy: data['reviewedBy'],
      reviewedAt: (data['reviewedAt'] as Timestamp?)?.toDate(), // <-- Added here
      requiredGender: data['requiredGender'],
      fieldsOfStudy: List<String>.from(data['fieldsOfStudy'] ?? []),
      numberOfPositions: data['numberOfPositions'] ?? 1,
      jobCategory: data['jobCategory'] ?? 'Tech',
      educationLevel: data['educationLevel'] ?? 'Bachelor\'s',
      languages: List<String>.from(data['languages'] ?? ['English']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'region': region,
      'city': city,
      'jobSite': jobSite,
      'requiredSkills': requiredSkills,
      'employerId': employerId,
      'status': status,
      'datePosted': Timestamp.fromDate(datePosted),
      'salaryRange': salaryRange,
      'jobType': jobType,
      'applicationDeadline': Timestamp.fromDate(applicationDeadline),
      'experienceLevel': experienceLevel,
      'approvalStatus': approvalStatus,
      'postStatus': postStatus,
      'reviewStatus': reviewStatus,
      'reviewMessage': reviewMessage,
      'reviewedBy': reviewedBy,
      'reviewedAt': reviewedAt != null ? Timestamp.fromDate(reviewedAt!) : null, // <-- Added here
      'requiredGender': requiredGender,
      'fieldsOfStudy': fieldsOfStudy,
      'numberOfPositions': numberOfPositions,
      'jobCategory': jobCategory,
      'educationLevel': educationLevel,
      'languages': languages,
    };
  }

  JobModel copyWith({
    String? title,
    String? description,
    String? region,
    String? city,
    String? jobSite,
    List<String>? requiredSkills,
    String? status,
    String? salaryRange,
    String? jobType,
    DateTime? applicationDeadline,
    String? experienceLevel,
    String? approvalStatus,
    String? postStatus,
    String? reviewStatus,
    String? reviewMessage,
    String? reviewedBy,
    DateTime? reviewedAt, // <-- Added here
    String? requiredGender,
    List<String>? fieldsOfStudy,
    int? numberOfPositions,
    String? jobCategory,
    String? educationLevel,
    List<String>? languages,
  }) {
    return JobModel(
      jobId: jobId,
      title: title ?? this.title,
      description: description ?? this.description,
      region: region ?? this.region,
      city: city ?? this.city,
      jobSite: jobSite ?? this.jobSite,
      requiredSkills: requiredSkills ?? this.requiredSkills,
      employerId: employerId,
      status: status ?? this.status,
      datePosted: datePosted,
      salaryRange: salaryRange ?? this.salaryRange,
      jobType: jobType ?? this.jobType,
      applicationDeadline: applicationDeadline ?? this.applicationDeadline,
      experienceLevel: experienceLevel ?? this.experienceLevel,
      approvalStatus: approvalStatus ?? this.approvalStatus,
      postStatus: postStatus ?? this.postStatus,
      reviewStatus: reviewStatus ?? this.reviewStatus,
      reviewMessage: reviewMessage ?? this.reviewMessage,
      reviewedBy: reviewedBy ?? this.reviewedBy,
      reviewedAt: reviewedAt ?? this.reviewedAt, // <-- Added here
      requiredGender: requiredGender ?? this.requiredGender,
      fieldsOfStudy: fieldsOfStudy ?? this.fieldsOfStudy,
      numberOfPositions: numberOfPositions ?? this.numberOfPositions,
      jobCategory: jobCategory ?? this.jobCategory,
      educationLevel: educationLevel ?? this.educationLevel,
      languages: languages ?? this.languages,
    );
  }
}
