import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:local_job_and_skills_marketplace/screens/admin/admin_dashboard.dart';
import 'package:local_job_and_skills_marketplace/screens/admin/reviewer/reviewer_dashboard.dart';
import 'package:local_job_and_skills_marketplace/screens/auth/signIn_screen.dart';
import '../auth/signup_screen.dart';
import '../home/employer_screens/employer_dashboard.dart';
import '../home/job_seeker_screens/Job_seeker_dashboard.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({Key? key}) : super(key: key);

  Future<Widget> _getRedirectPage() async {
    final FirebaseAuth auth = FirebaseAuth.instance;
    final User? currentUser = auth.currentUser;

    // Check if the user is signed in
    if (currentUser == null) {
      return  SignInScreen();
    }

    // Check each collection for the user's role
    try {
      // 1. Check if user is an admin
      final adminDoc = await FirebaseFirestore.instance
          .collection('admins')
          .doc(currentUser.uid)
          .get();
      if (adminDoc.exists) {
        return  AdminDashboard();
      }

      // 2. Check if user is a reviewer
      final reviewerDoc = await FirebaseFirestore.instance
          .collection('reviewers')
          .doc(currentUser.uid)
          .get();
      if (reviewerDoc.exists) {
        return  ReviewerDashboard();
      }

      // 3. Check if user is an employer
      final employerDoc = await FirebaseFirestore.instance
          .collection('employers')
          .doc(currentUser.uid)
          .get();
      if (employerDoc.exists) {
        return  EmployerDashboard();
      }

      // 4. Check if user is a job seeker
      final jobSeekerDoc = await FirebaseFirestore.instance
          .collection('jobSeekers')
          .doc(currentUser.uid)
          .get();
      if (jobSeekerDoc.exists) {
        return  JobSeekerDashboard();
      }

      // If user not found in any collection
      return  SignInScreen();
    } catch (e) {
      // Handle any errors
      return  SignInScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Widget>(
      future: _getRedirectPage(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          // Show a loading indicator while determining the redirect page
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        } else if (snapshot.hasError) {
          // Handle errors
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Error determining user role'),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () async {
                      await FirebaseAuth.instance.signOut();
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (context) =>  SignInScreen(),
                        ),
                      );
                    },
                    child: const Text('Return to Sign In'),
                  ),
                ],
              ),
            ),
          );
        } else {
          // Navigate to the determined page
          return snapshot.data!;
        }
      },
    );
  }
}