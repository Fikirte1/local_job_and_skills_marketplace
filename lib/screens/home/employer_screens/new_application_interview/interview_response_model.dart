import 'package:cloud_firestore/cloud_firestore.dart';

class InterviewResponse {
  final String applicationId;
  final String scheduleId;
  final String jobId;
  final String status; // 'pending', 'submitted', 'attended', 'no_show'
  final List<dynamic> questions;
  final Timestamp? deadline;
  final String? videoResponseUrl;
  final Timestamp? createdAt;
  final Timestamp? attendedAt;
  final String? meetingLink;
  final String? meetingPlatform;
  final String? feedback; // New field
  final Timestamp? updatedAt; // New field

  InterviewResponse({
    required this.applicationId,
    required this.scheduleId,
    required this.jobId,
    this.status = 'pending',
    required this.questions,
    this.deadline,
    this.videoResponseUrl,
    this.createdAt,
    this.attendedAt,
    this.meetingLink,
    this.meetingPlatform,
    this.feedback, // Add to constructor
    this.updatedAt, // Add to constructor
  });

  factory InterviewResponse.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return InterviewResponse(
      applicationId: data['applicationId'] ?? '',
      scheduleId: data['scheduleId'] ?? '',
      jobId: data['jobId'] ?? '',
      status: data['status'] ?? 'pending',
      questions: data['questions'] ?? [],
      deadline: data['deadline'],
      videoResponseUrl: data['videoResponseUrl'],
      createdAt: data['createdAt'],
      attendedAt: data['attendedAt'],
      meetingLink: data['meetingLink'],
      meetingPlatform: data['meetingPlatform'],
      feedback: data['feedback'], // Add from Firestore
      updatedAt: data['updatedAt'], // Add from Firestore
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'applicationId': applicationId,
      'scheduleId': scheduleId,
      'jobId': jobId,
      'status': status,
      'questions': questions,
      'deadline': deadline,
      'videoResponseUrl': videoResponseUrl,
      'createdAt': createdAt,
      'attendedAt': attendedAt,
      if (meetingLink != null) 'meetingLink': meetingLink,
      if (meetingPlatform != null) 'meetingPlatform': meetingPlatform,
      if (feedback != null) 'feedback': feedback, // Include in map
      if (updatedAt != null) 'updatedAt': updatedAt, // Include in map
    };
  }
}
