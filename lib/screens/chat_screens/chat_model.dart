import 'package:cloud_firestore/cloud_firestore.dart';

class ChatRoom {
  final String id;
  final String employerId;
  final String jobSeekerId;
  final String employerName;
  final String jobSeekerName;
  final String? employerLogoUrl;
  final String? jobSeekerProfileUrl;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String lastMessage;
  final bool hasUnreadMessages;
  final String? jobId;
  final String? jobTitle;

  ChatRoom({
    required this.id,
    required this.employerId,
    required this.jobSeekerId,
    required this.employerName,
    required this.jobSeekerName,
    this.employerLogoUrl,
    this.jobSeekerProfileUrl,
    required this.createdAt,
    required this.updatedAt,
    required this.lastMessage,
    this.hasUnreadMessages = false,
    this.jobId,
    this.jobTitle,
  });

  factory ChatRoom.fromMap(Map<String, dynamic> map) {
    return ChatRoom(
      id: map['id'],
      employerId: map['employerId'],
      jobSeekerId: map['jobSeekerId'],
      employerName: map['employerName'],
      jobSeekerName: map['jobSeekerName'],
      employerLogoUrl: map['employerLogoUrl'],
      jobSeekerProfileUrl: map['jobSeekerProfileUrl'],
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
      lastMessage: map['lastMessage'],
      hasUnreadMessages: map['hasUnreadMessages'] ?? false,
      jobId: map['jobId'],
      jobTitle: map['jobTitle'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'employerId': employerId,
      'jobSeekerId': jobSeekerId,
      'employerName': employerName,
      'jobSeekerName': jobSeekerName,
      'employerLogoUrl': employerLogoUrl,
      'jobSeekerProfileUrl': jobSeekerProfileUrl,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'lastMessage': lastMessage,
      'hasUnreadMessages': hasUnreadMessages,
      'jobId': jobId,
      'jobTitle': jobTitle,
    };
  }
}

class ChatMessage {
  final String id;
  final String chatRoomId;
  final String senderId;
  final String message;
  final DateTime sentAt;
  final bool isRead;

  ChatMessage({
    required this.id,
    required this.chatRoomId,
    required this.senderId,
    required this.message,
    required this.sentAt,
    this.isRead = false,
  });

  factory ChatMessage.fromMap(Map<String, dynamic> map) {
    return ChatMessage(
      id: map['id'],
      chatRoomId: map['chatRoomId'],
      senderId: map['senderId'],
      message: map['message'],
      sentAt: (map['sentAt'] as Timestamp).toDate(),
      isRead: map['isRead'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'chatRoomId': chatRoomId,
      'senderId': senderId,
      'message': message,
      'sentAt': Timestamp.fromDate(sentAt),
      'isRead': isRead,
    };
  }
}