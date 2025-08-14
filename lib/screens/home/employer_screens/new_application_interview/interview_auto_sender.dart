import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'interview_schedule_model.dart';

class InterviewAutoSender {
  static final _firestore = FirebaseFirestore.instance;

  static Future<void> scheduleAutoSend({
    required InterviewSchedule schedule,
    required String jobId,
    required String employerId,
  }) async {
    try {
      await _firestore.collection('interviewAutoSends').doc(schedule.scheduleId).set({
        'scheduleId': schedule.scheduleId,
        'jobId': jobId,
        'employerId': employerId,
        'scheduledDate': schedule.scheduledDate,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error scheduling auto-send: $e');
      rethrow;
    }
  }

  static Future<void> cancelAutoSend(String scheduleId) async {
    try {
      await _firestore.collection('interviewAutoSends').doc(scheduleId).delete();
    } catch (e) {
      debugPrint('Error cancelling auto-send: $e');
      rethrow;
    }
  }

  static Future<void> processPendingAutoSends() async {
    try {
      final now = DateTime.now();
      final pendingSends = await _firestore
          .collection('interviewAutoSends')
          .where('scheduledDate', isLessThanOrEqualTo: now)
          .where('status', isEqualTo: 'pending')
          .get();

      for (final doc in pendingSends.docs) {
        final scheduleId = doc.id;
        final scheduleDoc = await _firestore
            .collection('interviewSchedules')
            .doc(scheduleId)
            .get();

        if (scheduleDoc.exists) {
          final detailsDoc = await _firestore
              .collection('interviewDetails')
              .where('scheduleId', isEqualTo: scheduleId)
              .where('status', isEqualTo: 'draft')
              .get();

          if (detailsDoc.docs.isNotEmpty) {
            final details = detailsDoc.docs.first;
            await _firestore.runTransaction((transaction) async {
              // Update details status to 'sent'
              transaction.update(details.reference, {'status': 'sent'});

              // Update auto-send status to 'completed'
              transaction.update(doc.reference, {
                'status': 'completed',
                'processedAt': FieldValue.serverTimestamp(),
              });

              // Notify applicants (similar to _notifyApplicants in the editor)
              final schedule = InterviewSchedule.fromMap(
                  scheduleDoc.data()!, scheduleDoc.id);
              final applicationIds = schedule.applicationIds;

              for (final appId in applicationIds) {
                final responseDoc = _firestore
                    .collection('interviewResponses')
                    .doc(appId);

                transaction.set(
                  responseDoc,
                  {
                    'applicationId': appId,
                    'scheduleId': scheduleId,
                    'jobId': doc.data()['jobId'], // Get jobId from the auto-send document
                    'status': 'pending',
                    'questions': details.data()['questions'],
                    'deadline': details.data()['responseDeadline'],
                    'videoResponseUrl': null,
                    'createdAt': FieldValue.serverTimestamp(),
                  },
                  SetOptions(merge: true),
                );

                transaction.update(
                  _firestore.collection('applications').doc(appId),
                  {
                    'status': 'interviewStarted',
                    'interviewDetailsId': details.id,
                    'statusNote': 'Questionnaire sent. Deadline: ${details.data()['responseDeadline']}',
                  },
                );
              }
            });
          }
        }
      }
    } catch (e) {
      debugPrint('Error processing auto-sends: $e');
      rethrow;
    }
  }
}