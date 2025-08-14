import 'package:cloud_firestore/cloud_firestore.dart';

class InterviewDetails {
  final String detailsId;
  final String scheduleId;
  final String jobId;
  final String employerId;
  final List<String>? questions;
  final DateTime? responseDeadline;
  final String? meetingLink;
  final String? meetingPlatform;
  final String status; // 'draft' or 'sent'

  InterviewDetails({
    required this.detailsId,
    required this.scheduleId,
    required this.jobId,
    required this.employerId,
    this.questions,
    this.responseDeadline,
    this.meetingLink,
    this.meetingPlatform,
    this.status = 'draft', // Default to draft
  });

  factory InterviewDetails.fromMap(Map<String, dynamic> data, String detailsId) {
    return InterviewDetails(
      detailsId: detailsId,
      scheduleId: data['scheduleId'] ?? '',
      jobId: data['jobId'] ?? '',
      employerId: data['employerId'] ?? '',
      questions: data['questions'] != null
          ? List<String>.from(data['questions'])
          : null,
      responseDeadline: data['responseDeadline'] != null
          ? (data['responseDeadline'] as Timestamp).toDate()
          : null,
      meetingLink: data['meetingLink'],
      meetingPlatform: data['meetingPlatform'],
      status: data['status'] ?? 'draft',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'scheduleId': scheduleId,
      'jobId': jobId,
      'employerId': employerId,
      if (questions != null) 'questions': questions,
      if (responseDeadline != null)
        'responseDeadline': Timestamp.fromDate(responseDeadline!),
      if (meetingLink != null) 'meetingLink': meetingLink,
      if (meetingPlatform != null) 'meetingPlatform': meetingPlatform,
      'status': status,
    };
  }
}