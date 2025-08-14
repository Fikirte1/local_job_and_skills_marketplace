import 'package:cloud_firestore/cloud_firestore.dart';

enum InterviewType {
  videoCall,
  questionnaire
}

class InterviewSchedule {
  final String scheduleId;
  final String jobId;
  final String employerId;
  final List<String> applicationIds;
  final DateTime scheduledDate;
  final InterviewType interviewType;
  final DateTime createdAt;
  final String? instructions;
  final String? interviewDetailsId;

  InterviewSchedule({
    required this.scheduleId,
    required this.jobId,
    required this.employerId,
    required this.applicationIds,
    required this.scheduledDate,
    required this.interviewType,
    required this.createdAt,
    this.instructions,
    this.interviewDetailsId,
  });

  factory InterviewSchedule.fromMap(Map<String, dynamic> data, String scheduleId) {
    return InterviewSchedule(
      scheduleId: scheduleId,
      jobId: data['jobId'] ?? '',
      employerId: data['employerId'] ?? '',
      applicationIds: List<String>.from(data['applicationIds'] ?? []),
      scheduledDate: (data['scheduledDate'] as Timestamp).toDate(),
      interviewType: data['interviewType'] == 'videoCall'
          ? InterviewType.videoCall
          : InterviewType.questionnaire,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      instructions: data['instructions'],
      interviewDetailsId: data['interviewDetailsId'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'jobId': jobId,
      'employerId': employerId,
      'applicationIds': applicationIds,
      'scheduledDate': Timestamp.fromDate(scheduledDate),
      'interviewType': interviewType.toString().split('.').last,
      'createdAt': Timestamp.fromDate(createdAt),
      if (instructions != null) 'instructions': instructions,
      if (interviewDetailsId != null)
        'interviewDetailsId': interviewDetailsId,
    };
  }
}