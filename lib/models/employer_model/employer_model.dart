import 'package:cloud_firestore/cloud_firestore.dart';

class Employer {
  final String userId;
  final String companyName;
  final String email;
  final String? region;
  final String? city;
  final String contactNumber;
  final String aboutCompany;
  final String? industry;
  final String? website;
  final String? logoUrl;
  final bool isVerified;
  final String? identityDocumentUrl;
  final String? documentType;
  final String verificationStatus;
  final String? verificationMessage;
  final String? verifiedBy;
  final String? verifiedByName;
  final DateTime? verificationSubmittedAt;
  final DateTime? verifiedAt;

  Employer({
    required this.userId,
    required this.companyName,
    required this.email,
    required this.contactNumber,
    required this.aboutCompany,
    this.region,
    this.city,
    this.industry,
    this.website,
    this.logoUrl,
    this.isVerified = false,
    this.identityDocumentUrl,
    this.documentType,
    this.verificationStatus = 'Unverified',
    this.verificationMessage,
    this.verifiedBy,
    this.verifiedByName,
    this.verificationSubmittedAt,
    this.verifiedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'companyName': companyName,
      'email': email,
      'region': region,
      'city': city,
      'contactNumber': contactNumber,
      'aboutCompany': aboutCompany,
      'industry': industry,
      'website': website,
      'logoUrl': logoUrl,
      'isVerified': isVerified,
      'identityDocumentUrl': identityDocumentUrl,
      'documentType': documentType,
      'verificationStatus': verificationStatus,
      'verificationMessage': verificationMessage,
      'verifiedBy': verifiedBy,
      'verifiedByName': verifiedByName,
      'verificationSubmittedAt': verificationSubmittedAt,
      'verifiedAt': verifiedAt,
    };
  }

  factory Employer.fromMap(Map<String, dynamic> map) {
    return Employer(
      userId: map['userId'],
      companyName: map['companyName'],
      email: map['email'],
      region: map['region'],
      city: map['city'],
      contactNumber: map['contactNumber'],
      aboutCompany: map['aboutCompany'],
      industry: map['industry'],
      website: map['website'],
      logoUrl: map['logoUrl'],
      isVerified: map['isVerified'] ?? false,
      identityDocumentUrl: map['identityDocumentUrl'],
      documentType: map['documentType'],
      verificationStatus: map['verificationStatus'] ?? 'Unverified',
      verificationMessage: map['verificationMessage'],
      verifiedBy: map['verifiedBy'],
      verifiedByName: map['verifiedByName'],
      verificationSubmittedAt: map['verificationSubmittedAt']?.toDate(),
      verifiedAt: map['verifiedAt']?.toDate(),
    );
  }

  Employer copyWith({
    String? userId,
    String? companyName,
    String? email,
    String? region,
    String? city,
    String? contactNumber,
    String? aboutCompany,
    String? industry,
    String? website,
    String? logoUrl,
    bool? isVerified,
    String? identityDocumentUrl,
    String? documentType,
    String? verificationStatus,
    String? verificationMessage,
    String? verifiedBy,
    String? verifiedByName,
    DateTime? verificationSubmittedAt,
    DateTime? verifiedAt,
  }) {
    return Employer(
      userId: userId ?? this.userId,
      companyName: companyName ?? this.companyName,
      email: email ?? this.email,
      region: region ?? this.region,
      city: city ?? this.city,
      contactNumber: contactNumber ?? this.contactNumber,
      aboutCompany: aboutCompany ?? this.aboutCompany,
      industry: industry ?? this.industry,
      website: website ?? this.website,
      logoUrl: logoUrl ?? this.logoUrl,
      isVerified: isVerified ?? this.isVerified,
      identityDocumentUrl: identityDocumentUrl ?? this.identityDocumentUrl,
      documentType: documentType ?? this.documentType,
      verificationStatus: verificationStatus ?? this.verificationStatus,
      verificationMessage: verificationMessage ?? this.verificationMessage,
      verifiedBy: verifiedBy ?? this.verifiedBy,
      verifiedByName: verifiedByName ?? this.verifiedByName,
      verificationSubmittedAt: verificationSubmittedAt ?? this.verificationSubmittedAt,
      verifiedAt: verifiedAt ?? this.verifiedAt,
    );
  }

  bool get canUploadDocuments {
    return verificationStatus == 'Unverified' || verificationStatus == 'Rejected';
  }
}