import '../../screens/home/job_seeker_screens/coin_system/CoinTransaction_model.dart';
import '../../screens/home/job_seeker_screens/coin_system/coin_service.dart';
import 'education_model.dart';
import 'work_experience_model.dart';

class JobSeeker {
  final String userId;
  final String name;
  final String email;
  final String contactNumber;
  final String sex;
  final String? userTitle;
  final String? region;
  final String? city;

  // Profile completion fields
  final List<String>? skills;
  final String? aboutMe;
  final String? profilePictureUrl;
  final String? resumeUrl;
  // final String? resumeLastUpdated
  final List<String>? portfolioLinks;
  final List<String>? languages;
  final bool? isVerified;
  final String? identityDocumentUrl;
  final String? verificationStatus;
  final String? verificationMessage;
  final List<Education>? educationHistory;
  final List<WorkExperience>? workExperience;
  final bool isProfileComplete;

  // Constructor for initial registration
  JobSeeker.initial({
    required this.userId,
    required this.name,
    required this.email,
    required this.contactNumber,
    required this.sex,
  }) : userTitle = null,
        region = null,
        city = null,
        skills = null,
        aboutMe = null,
        profilePictureUrl = null,
        resumeUrl = null,
        portfolioLinks = null,
        languages = null,
        isVerified = null,
        identityDocumentUrl = null,
        verificationStatus = null,
        verificationMessage = null,
        educationHistory = null,
        workExperience = null,
        isProfileComplete = false {
    // Initialize coins for new user
    _initializeUserCoins();
  }

  // Private method to initialize coins
  Future<void> _initializeUserCoins() async {
    try {
      await CoinService.initializeUserCoins(userId);
    } catch (e) {
      print('Error initializing coins: $e');
    }
  }

  // Constructor for full profile
  JobSeeker({
    required this.userId,
    required this.name,
    required this.email,
    required this.contactNumber,
    required this.sex,
    this.userTitle,
    this.region,
    this.city,
    this.skills,
    this.aboutMe,
    this.profilePictureUrl,
    this.resumeUrl,
    this.portfolioLinks,
    this.languages,
    this.isVerified,
    this.identityDocumentUrl,
    this.verificationStatus,
    this.verificationMessage,
    this.educationHistory,
    this.workExperience,
    this.isProfileComplete = false,
  });

  // Convert to map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'name': name,
      'email': email,
      'contactNumber': contactNumber,
      'sex': sex,
      'userTitle': userTitle,
      'region': region,
      'city': city,
      'skills': skills,
      'aboutMe': aboutMe,
      'profilePictureUrl': profilePictureUrl,
      'resumeUrl': resumeUrl,
      'portfolioLinks': portfolioLinks,
      'languages': languages,
      'isVerified': isVerified,
      'identityDocumentUrl': identityDocumentUrl,
      'verificationStatus': verificationStatus,
      'verificationMessage': verificationMessage,
      'educationHistory': educationHistory?.map((e) => e.toMap()).toList(),
      'workExperience': workExperience?.map((e) => e.toMap()).toList(),
      'isProfileComplete': isProfileComplete,
    };
  }

  // Create from Firestore data
  factory JobSeeker.fromMap(Map<String, dynamic> map) {
    return JobSeeker(
      userId: map['userId'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      contactNumber: map['contactNumber'] ?? '',
      sex: map['sex'] ?? '',
      userTitle: map['userTitle'],
      region: map['region'],
      city: map['city'],
      skills: map['skills'] != null ? List<String>.from(map['skills']) : null,
      aboutMe: map['aboutMe'],
      profilePictureUrl: map['profilePictureUrl'],
      resumeUrl: map['resumeUrl'],
      portfolioLinks: map['portfolioLinks'] != null ? List<String>.from(map['portfolioLinks']) : null,
      languages: map['languages'] != null ? List<String>.from(map['languages']) : null,
      isVerified: map['isVerified'],
      identityDocumentUrl: map['identityDocumentUrl'],
      verificationStatus: map['verificationStatus'],
      verificationMessage: map['verificationMessage'],
      educationHistory: map['educationHistory'] != null
          ? (map['educationHistory'] as List).map((x) => Education.fromMap(x)).toList()
          : null,
      workExperience: map['workExperience'] != null
          ? (map['workExperience'] as List).map((x) => WorkExperience.fromMap(x)).toList()
          : null,
      isProfileComplete: map['isProfileComplete'] ?? false,
    );
  }

  // Helper method to update profile
  JobSeeker copyWith({
    String? name,
    String? email,
    String? contactNumber,
    String? sex,
    String? userTitle,
    String? region,
    String? city,
    List<String>? skills,
    String? aboutMe,
    String? profilePictureUrl,
    String? resumeUrl,
    List<String>? portfolioLinks,
    List<String>? languages,
    bool? isVerified,
    String? identityDocumentUrl,
    String? verificationStatus,
    String? verificationMessage,
    List<Education>? educationHistory,
    List<WorkExperience>? workExperience,
    bool? isProfileComplete,
  }) {
    return JobSeeker(
      userId: userId,
      name: name ?? this.name,
      email: email ?? this.email,
      contactNumber: contactNumber ?? this.contactNumber,
      sex: sex ?? this.sex,
      userTitle: userTitle ?? this.userTitle,
      region: region ?? this.region,
      city: city ?? this.city,
      skills: skills ?? this.skills,
      aboutMe: aboutMe ?? this.aboutMe,
      profilePictureUrl: profilePictureUrl ?? this.profilePictureUrl,
      resumeUrl: resumeUrl ?? this.resumeUrl,
      portfolioLinks: portfolioLinks ?? this.portfolioLinks,
      languages: languages ?? this.languages,
      isVerified: isVerified ?? this.isVerified,
      identityDocumentUrl: identityDocumentUrl ?? this.identityDocumentUrl,
      verificationStatus: verificationStatus ?? this.verificationStatus,
      verificationMessage: verificationMessage ?? this.verificationMessage,
      educationHistory: educationHistory ?? this.educationHistory,
      workExperience: workExperience ?? this.workExperience,
      isProfileComplete: isProfileComplete ?? this.isProfileComplete,
    );
  }

  // Calculate profile completion percentage (0.0 to 1.0)
  double calculateProfileCompletion() {
    const requiredFields = [
      'userTitle', 'region', 'city', 'skills', 'aboutMe', 'resumeUrl', 'educationHistory'
    ];

    int completedFields = 0;

    for (final field in requiredFields) {
      switch (field) {
        case 'userTitle':
          if (userTitle != null && userTitle!.isNotEmpty) completedFields++;
          break;
        case 'region':
          if (region != null && region!.isNotEmpty) completedFields++;
          break;
        case 'city':
          if (city != null && city!.isNotEmpty) completedFields++;
          break;
        case 'skills':
          if (skills != null && skills!.isNotEmpty) completedFields++;
          break;
        case 'aboutMe':
          if (aboutMe != null && aboutMe!.isNotEmpty) completedFields++;
          break;
        case 'profilePictureUrl':
          if (profilePictureUrl != null && profilePictureUrl!.isNotEmpty) completedFields++;
          break;
        case 'resumeUrl':
          if (resumeUrl != null && resumeUrl!.isNotEmpty) completedFields++;
          break;
        case 'educationHistory':
          if (educationHistory != null && educationHistory!.isNotEmpty) completedFields++;
          break;
        case 'workExperience':
          if (workExperience != null && workExperience!.isNotEmpty) completedFields++;
          break;
      }
    }

    return completedFields / requiredFields.length;
  }

  // Check if all required fields are completed
  bool checkProfileComplete() {
    return calculateProfileCompletion() >= 1.0;
  }

  // Coin system methods
  Future<int> getCoinBalance() async {
    return await CoinService.getCoinBalance(userId);
  }

  Future<bool> canApplyToJob() async {
    return await CoinService.canApplyForJob(userId);
  }

  Future<bool> deductApplicationCoin(String jobId) async {
    return await CoinService.deductCoin(
      userId: userId,
      amount: 1,
      type: 'application',
      jobId: jobId,
    );
  }

  Stream<List<CoinTransaction>> getCoinTransactions() {
    return CoinService.getTransactionHistory(userId);
  }
}