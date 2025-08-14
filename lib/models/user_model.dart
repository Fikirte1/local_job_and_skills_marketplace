/*
class UserModel {
  final String userId;
  final String name;
  final String email;
  final String role;
  final String? location;
  final List<String>? skills;
  final String? profilePictureUrl;
  final String? resumeUrl;
  final String? availability;
  final String? aboutMe;
  final String? contactNumber;
  final bool isVerified;
  final String? identityDocumentUrl;
  final String verificationStatus;
  final String? verificationMessage;
// sex
  UserModel({
    required this.userId,
    required this.name,
    required this.email,
    required this.role,
    this.location,
    this.skills,
    this.profilePictureUrl,
    this.resumeUrl,
    this.availability,
    this.aboutMe,
    this.contactNumber,
    required this.isVerified,
    this.identityDocumentUrl,
    required this.verificationStatus,
    this.verificationMessage,
  });

  // Factory constructor to create a UserModel instance from a map
  factory UserModel.fromMap(Map<String, dynamic> data, String userId) {
    return UserModel(
      userId: userId,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      role: data['role'] ?? '',
      location: data['location'],
      skills: data['skills'] != null ? List<String>.from(data['skills']) : null,
      profilePictureUrl: data['profilePictureUrl'],
      resumeUrl: data['resumeUrl'],
      availability: data['availability'],
      aboutMe: data['aboutMe'],
      contactNumber: data['contactNumber'],
      isVerified: data['isVerified'] ?? false,
      identityDocumentUrl: data['identityDocumentUrl'],
      verificationStatus: data['verificationStatus'] ?? 'Not Submitted', // Not Submitted, Pending, Verified, Rejected
      verificationMessage: data['verificationMessage'],
    );
  }

  // Method to convert a UserModel instance to a map
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'name': name,
      'email': email,
      'role': role,
      'location': location,
      'skills': skills,
      'profilePictureUrl': profilePictureUrl,
      'resumeUrl': resumeUrl,
      'availability': availability,
      'aboutMe': aboutMe,
      'contactNumber': contactNumber,
      'isVerified': isVerified,
      'identityDocumentUrl': identityDocumentUrl,
      'verificationStatus': verificationStatus,
      'verificationMessage': verificationMessage,
    };
  }

  // Method to create a copy of the current UserModel with some updated fields
  UserModel copyWith({
    String? name,
    String? email,
    String? role,
    String? location,
    List<String>? skills,
    String? profilePictureUrl,
    String? resumeUrl,
    String? availability,
    String? aboutMe,
    String? contactNumber,
    bool? isVerified,
    String? identityDocumentUrl,
    String? verificationStatus,
    String? verificationMessage,
  }) {
    return UserModel(
      userId: userId, // userId is final and cannot change
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      location: location ?? this.location,
      skills: skills ?? this.skills,
      profilePictureUrl: profilePictureUrl ?? this.profilePictureUrl,
      resumeUrl: resumeUrl ?? this.resumeUrl,
      availability: availability ?? this.availability,
      aboutMe: aboutMe ?? this.aboutMe,
      contactNumber: contactNumber ?? this.contactNumber,
      isVerified: isVerified ?? this.isVerified,
      identityDocumentUrl: identityDocumentUrl ?? this.identityDocumentUrl,
      verificationStatus: verificationStatus ?? this.verificationStatus,
      verificationMessage: verificationMessage ?? this.verificationMessage,
    );
  }
}
*/
