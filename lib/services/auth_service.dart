import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/job _seeker_models/education_model.dart';
import '../models/job _seeker_models/job_seeker_model.dart';
import '../models/job _seeker_models/work_experience_model.dart';
import '../models/employer_model/employer_model.dart';

class AuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Register Job Seeker with basic info
  Future<User?> registerJobSeeker({
    required String email,
    required String password,
    required String name,
    required String contactNumber,
    required String sex,
    String? userTitle,
    String? region,
    String? city,
  }) async {
    try {
      UserCredential userCredential = await _firebaseAuth
          .createUserWithEmailAndPassword(
          email: email, password: password);

      if (userCredential.user != null) {
        JobSeeker newJobSeeker = JobSeeker.initial(
          userId: userCredential.user!.uid,
          name: name,
          email: email,
          contactNumber: contactNumber,
          sex: sex,
        ).copyWith(
          userTitle: userTitle,
          region: region,
          city: city,
        );

        await _firestore
            .collection('jobSeekers')
            .doc(userCredential.user!.uid)
            .set(newJobSeeker.toMap());

        return userCredential.user;
      }
      return null;
    } catch (e) {
      throw Exception("Job seeker registration failed: $e");
    }
  }

  // Update job seeker profile with additional info
  Future<void> updateJobSeekerProfile({
    required String userId,
    String? userTitle,
    List<String>? skills,
    String? aboutMe,
    String? profilePictureUrl,
    String? resumeUrl,
    String? availability,
    List<String>? portfolioLinks,
    List<String>? languages,
    List<Education>? educationHistory,
    List<WorkExperience>? workExperience,
  }) async {
    try {
      await _firestore.collection('jobSeekers').doc(userId).update({
        if (userTitle != null) 'userTitle': userTitle,
        if (skills != null) 'skills': skills,
        if (aboutMe != null) 'aboutMe': aboutMe,
        if (profilePictureUrl != null) 'profilePictureUrl': profilePictureUrl,
        if (resumeUrl != null) 'resumeUrl': resumeUrl,
        if (availability != null) 'availability': availability,
        if (portfolioLinks != null) 'portfolioLinks': portfolioLinks,
        if (languages != null) 'languages': languages,
        if (educationHistory != null)
          'educationHistory': educationHistory.map((e) => e.toMap()).toList(),
        if (workExperience != null)
          'workExperience': workExperience.map((e) => e.toMap()).toList(),
      });
    } catch (e) {
      throw Exception("Profile update failed: $e");
    }
  }

// Register Employer
  Future<User?> registerEmployer({
    required String email,
    required String password,
    required String companyName,
    required String contactNumber,
    required String aboutCompany,
    String? region,
    String? city,
    String? industry,
    String? website,
    int? companySize,
  }) async {
    try {
      UserCredential userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user != null) {
        Employer newEmployer = Employer(
          userId: userCredential.user!.uid,
          companyName: companyName,
          email: email,
          contactNumber: contactNumber,
          aboutCompany: aboutCompany,
          region: region,
          city: city,
          industry: industry,
          website: website,
        );

        await _firestore.collection('employers').doc(userCredential.user!.uid).set(newEmployer.toMap());
        return userCredential.user;
      }
      return null;
    } catch (e) {
      throw Exception("Employer registration failed: $e");
    }
  }

  // Get Job Seeker Data
  Future<JobSeeker?> getJobSeeker(String userId) async {
    try {
      DocumentSnapshot snapshot = await _firestore.collection('jobSeekers').doc(userId).get();
      if (snapshot.exists) {
        return JobSeeker.fromMap(snapshot.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      throw Exception("Error getting job seeker data: $e");
    }
  }

  // Get Employer Data
  Future<Employer?> getEmployer(String userId) async {
    try {
      DocumentSnapshot snapshot = await _firestore.collection('employers').doc(userId).get();
      if (snapshot.exists) {
        return Employer.fromMap(snapshot.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      throw Exception("Error getting employer data: $e");
    }
  }

  // Common login method
  Future<User?> loginUser({required String email, required String password}) async {
    try {
      UserCredential userCredential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential.user;
    } catch (e) {
      throw Exception("Login failed: ${e.toString()}");
    }
  }

  Future<void> logout() async {
    await _firebaseAuth.signOut();
  }


}