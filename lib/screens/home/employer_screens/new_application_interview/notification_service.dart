import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../../models/applications_model.dart';

class NotificationService {
  static Future<void> sendStatusNotification({
    required String userId,
    required ApplicationStatus status,
    String? rejectionReason,
    String? resubmissionFeedback,
  }) async {
    String title = '';
    String message = '';
    String type = '';

    switch (status) {
      case ApplicationStatus.rejected:
        title = 'Interview Rejected';
        message = 'Your interview has been rejected. Reason: ${rejectionReason ?? "Not provided"}';
        type = 'interview_rejected';
        break;
      case ApplicationStatus.needsResubmission:
        title = 'Interview Needs Resubmission';
        message = 'Your interview needs resubmission. Feedback: ${resubmissionFeedback ?? "Not provided"}';
        type = 'interview_resubmit';
        break;
      case ApplicationStatus.interviewCompleted:
        title = 'Interview Accepted';
        message = 'Your interview has been accepted! The winner will be announced soon.';
        type = 'interview_accepted';
        break;
      default:
        return;
    }

    await _sendNotification(
      userId: userId,
      title: title,
      message: message,
      type: type,
    );
  }

  static Future<void> sendHireNotifications({
    required String jobId,
    required List<String> hiredApplicationIds,
  }) async {
    // Get all applications for the job
    final applications = await FirebaseFirestore.instance
        .collection('applications')
        .where('jobId', isEqualTo: jobId)
        .get();

    // Send notifications to hired applicants
    for (final doc in applications.docs) {
      if (hiredApplicationIds.contains(doc.id)) {
        await _sendNotification(
          userId: doc['jobSeekerId'],
          title: 'Congratulations!',
          message: 'You have been selected for the position!',
          type: 'hired',
        );
      } else if (doc['status'] == ApplicationStatus.interviewCompleted.toString().split('.').last) {
        // Send notifications to other applicants that weren't selected
        await _sendNotification(
          userId: doc['jobSeekerId'],
          title: 'Position Filled',
          message: 'Another candidate has been selected for this position.',
          type: 'not_selected',
        );
      }
    }
  }

  static Future<void> _sendNotification({
    required String userId,
    required String title,
    required String message,
    required String type,
  }) async {
    try {
      await FirebaseFirestore.instance.collection('notifications').add({
        'userId': userId,
        'title': title,
        'message': message,
        'type': type,
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error sending notification: $e');
    }
  }

  static Future<void> markAsRead(String notificationId) async {
    try {
      await FirebaseFirestore.instance
          .collection('notifications')
          .doc(notificationId)
          .update({'isRead': true});
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
    }
  }
}