import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:rxdart/rxdart.dart';

import 'chat_model.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get or create a chat room between employer and job seeker
  Future<ChatRoom> getOrCreateChatRoom({
    required String employerId,
    required String employerName,
    required String jobSeekerId,
    required String jobSeekerName,
    String? employerLogoUrl,
    String? jobSeekerProfileUrl,
    String? jobId,
    String? jobTitle,
  }) async {
    // Check if chat room already exists in either direction
    final query1 = _firestore
        .collection('chatRooms')
        .where('employerId', isEqualTo: employerId)
        .where('jobSeekerId', isEqualTo: jobSeekerId)
        .limit(1);

    final query2 = _firestore
        .collection('chatRooms')
        .where('employerId', isEqualTo: jobSeekerId)
        .where('jobSeekerId', isEqualTo: employerId)
        .limit(1);

    final snapshot1 = await query1.get();
    if (snapshot1.docs.isNotEmpty) {
      return ChatRoom.fromMap(
        snapshot1.docs.first.data()..['id'] = snapshot1.docs.first.id,
      );
    }

    final snapshot2 = await query2.get();
    if (snapshot2.docs.isNotEmpty) {
      return ChatRoom.fromMap(
        snapshot2.docs.first.data()..['id'] = snapshot2.docs.first.id,
      );
    }

    // Create new chat room if none exists
    final newRoomRef = _firestore.collection('chatRooms').doc();
    final newRoom = ChatRoom(
      id: newRoomRef.id,
      employerId: employerId,
      jobSeekerId: jobSeekerId,
      employerName: employerName,
      jobSeekerName: jobSeekerName,
      employerLogoUrl: employerLogoUrl,
      jobSeekerProfileUrl: jobSeekerProfileUrl,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      lastMessage: 'Chat started',
      hasUnreadMessages: false,
      jobId: jobId,
      jobTitle: jobTitle,
    );

    await newRoomRef.set(newRoom.toMap());
    return newRoom;
  }

  // Send a message
  Future<void> sendMessage({
    required String chatRoomId,
    required String senderId,
    required String message,
  }) async {
    final messageRef = _firestore
        .collection('chatRooms')
        .doc(chatRoomId)
        .collection('messages')
        .doc();

    final newMessage = ChatMessage(
      id: messageRef.id,
      chatRoomId: chatRoomId,
      senderId: senderId,
      message: message,
      sentAt: DateTime.now(),
    );

    await messageRef.set(newMessage.toMap());

    // Update last message in chat room
    await _firestore.collection('chatRooms').doc(chatRoomId).update({
      'updatedAt': Timestamp.now(),
      'lastMessage': message,
      'hasUnreadMessages': senderId != _auth.currentUser?.uid,
    });
  }

  // Get stream of messages for a chat room
  Stream<List<ChatMessage>> getMessagesStream(String chatRoomId) {
    return _firestore
        .collection('chatRooms')
        .doc(chatRoomId)
        .collection('messages')
        .orderBy('sentAt', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => ChatMessage.fromMap(doc.data()..['id'] = doc.id))
        .toList());
  }

  // Get stream of chat rooms for a user
  Stream<List<ChatRoom>> getChatRoomsStream(String userId) {
    // Combine two queries - one where user is employer, one where user is job seeker
    final employerRooms = _firestore
        .collection('chatRooms')
        .where('employerId', isEqualTo: userId)
        .orderBy('updatedAt', descending: true)
        .snapshots();

    final jobSeekerRooms = _firestore
        .collection('chatRooms')
        .where('jobSeekerId', isEqualTo: userId)
        .orderBy('updatedAt', descending: true)
        .snapshots();

    // Combine both streams
    return Rx.combineLatest2(
      employerRooms,
      jobSeekerRooms,
          (QuerySnapshot employerSnapshot, QuerySnapshot jobSeekerSnapshot) {
        final allRooms = [
          ...employerSnapshot.docs,
          ...jobSeekerSnapshot.docs,
        ];

        // Sort combined list by updatedAt
        allRooms.sort((a, b) {
          final aTime = (a.data() as Map<String, dynamic>)['updatedAt'] as Timestamp;
          final bTime = (b.data() as Map<String, dynamic>)['updatedAt'] as Timestamp;
          return bTime.compareTo(aTime);
        });

        return allRooms
            .map((doc) => ChatRoom.fromMap(doc.data() as Map<String, dynamic>..['id'] = doc.id))
            .toList();
      },
    );
  }

  // Mark messages as read
  Future<void> markMessagesAsRead(String chatRoomId, String userId) async {
    final unreadMessages = await _firestore
        .collection('chatRooms')
        .doc(chatRoomId)
        .collection('messages')
        .where('senderId', isNotEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .get();

    final batch = _firestore.batch();
    for (final doc in unreadMessages.docs) {
      batch.update(doc.reference, {'isRead': true});
    }

    await batch.commit();

    // Update chat room status
    await _firestore.collection('chatRooms').doc(chatRoomId).update({
      'hasUnreadMessages': false,
    });
  }
}