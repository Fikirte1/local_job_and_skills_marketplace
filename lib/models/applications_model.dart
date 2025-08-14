import 'package:cloud_firestore/cloud_firestore.dart';

enum ApplicationStatus {
  applied,               // Initial application submitted
  acceptedForInterview,  // Employer accepted for interview
  rejected,              // Rejected without interview
  interviewScheduled,    // Interview scheduled but not started
  interviewStarted,      // Employer sent questions/meeting link (new)
  responseSubmitted,     // Job seeker submitted responses (new)
  interviewCompleted,    // Employer reviewed responses
  hired,                 // Hired after interview
  winnerAnnounced,       // Not selected after interview
  needsResubmission      // Needs to resubmit response
}

class ApplicationModel {
  final String applicationId;
  final String jobId;
  final String jobSeekerId;
  final String employerId;
  final ApplicationStatus status;
  final DateTime appliedDate;
  final DateTime? statusUpdatedDate;
  final String? statusNote;
  final String? interviewScheduleId;
  final String? interviewDetailsId;
  final String? rejectionReason;
  final String? resubmissionFeedback;
  final bool? isWinner;
  final double? compatibilityScore;

  ApplicationModel({
    required this.applicationId,
    required this.jobId,
    required this.jobSeekerId,
    required this.employerId,
    required this.status,
    required this.appliedDate,
    this.statusUpdatedDate,
    this.statusNote,
    this.interviewScheduleId,
    this.interviewDetailsId,
    this.rejectionReason,
    this.resubmissionFeedback,
    this.isWinner,
    this.compatibilityScore,
  });

  factory ApplicationModel.fromMap(Map<String, dynamic> data, String applicationId) {
    return ApplicationModel(
      applicationId: applicationId,
      jobId: data['jobId'] ?? '',
      jobSeekerId: data['jobSeekerId'] ?? '',
      employerId: data['employerId'] ?? '',
      status: _parseStatus(data['status']),
      appliedDate: (data['appliedDate'] as Timestamp).toDate(),
      statusUpdatedDate: data['statusUpdatedDate'] != null
          ? (data['statusUpdatedDate'] as Timestamp).toDate()
          : null,
      statusNote: data['statusNote'],
      interviewScheduleId: data['interviewScheduleId'],
      interviewDetailsId: data['interviewDetailsId'],
      rejectionReason: data['rejectionReason'],
      resubmissionFeedback: data['resubmissionFeedback'],
      isWinner: data['isWinner'],
      compatibilityScore: (data['compatibilityScore'] as num?)?.toDouble(),
    );
  }

  static ApplicationStatus _parseStatus(String status) {
    return ApplicationStatus.values.firstWhere(
          (e) => e.toString().split('.').last == status,
      orElse: () => ApplicationStatus.applied,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'jobId': jobId,
      'jobSeekerId': jobSeekerId,
      'employerId': employerId,
      'status': status.toString().split('.').last,
      'appliedDate': Timestamp.fromDate(appliedDate),
      if (statusUpdatedDate != null)
        'statusUpdatedDate': Timestamp.fromDate(statusUpdatedDate!),
      if (statusNote != null) 'statusNote': statusNote,
      if (interviewScheduleId != null)
        'interviewScheduleId': interviewScheduleId,
      if (interviewDetailsId != null)
        'interviewDetailsId': interviewDetailsId,
      if (rejectionReason != null) 'rejectionReason': rejectionReason,
      if (resubmissionFeedback != null) 'resubmissionFeedback': resubmissionFeedback,
      if (isWinner != null) 'isWinner': isWinner,
      if (compatibilityScore != null) 'compatibilityScore': compatibilityScore,
    };
  }

  static ApplicationStatus parseStatus(String status) {
    return ApplicationStatus.values.firstWhere(
          (e) => e.toString().split('.').last == status,
      orElse: () => ApplicationStatus.applied,
    );
  }
}
