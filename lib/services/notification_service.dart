// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_messaging/firebase_messaging.dart';
//
// class NotificationService {
//   final FirebaseMessaging _fcm = FirebaseMessaging.instance;
//
//   void configureNotifications() {
//     _fcm.requestPermission();
//
//     FirebaseMessaging.onMessage.listen((RemoteMessage message) {
//       if (message.notification != null) {
//         print('Message: ${message.notification!.body}');
//       }
//     });
//   }
//
//   Future<void> sendNotification(String title, String body, String topic) async {
//     await FirebaseFirestore.instance.collection('notifications').add({
//       'title': title,
//       'body': body,
//       'topic': topic,
//       'timestamp': FieldValue.serverTimestamp(),
//     });
//   }
// }
