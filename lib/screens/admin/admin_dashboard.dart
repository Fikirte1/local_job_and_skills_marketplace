import 'package:flutter/material.dart';
import 'package:local_job_and_skills_marketplace/screens/admin/manage_employers_screen.dart';
import 'package:local_job_and_skills_marketplace/screens/admin/manage_job_seekers_screen.dart';
import 'package:local_job_and_skills_marketplace/screens/admin/manage_jobs_screen.dart';
import 'package:local_job_and_skills_marketplace/screens/admin/messages_screen.dart';
import 'package:local_job_and_skills_marketplace/screens/auth/signIn_screen.dart';
import '../../services/auth_service.dart';
import 'admins_notifications_screen.dart';
import 'employer_verification_screen.dart';

class AdminDashboard extends StatefulWidget {
  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final AuthService _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          "Admin Dashboard",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.indigo,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              try {
                await _authService.logout();
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (context) => SignInScreen()),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error during logout: ${e.toString()}'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.count(
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          children: [
            _buildGridButton("Manage Employers", Icons.business_center, Colors.indigo, () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => ManageEmployersScreen()));
            }),
            _buildGridButton("Manage Job Seekers", Icons.people_alt, Colors.teal, () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => ManageJobSeekersScreen()));
            }),
            _buildGridButton("Manage Jobs", Icons.work_outline, Colors.deepPurple, () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => ManageJobsScreen()));
            }),
            _buildGridButton("Notifications", Icons.notifications, Colors.orange, () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => AdminsNotificationsScreen()));
            }),
            _buildGridButton("Messages", Icons.message, Colors.pink, () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => MessagesScreen()));
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildGridButton(
      String title,
      IconData icon,
      Color color,
      VoidCallback onTap, {
        int? badgeCount,
      }) {
    return Stack(
      children: [
        Material(
          color: Colors.white,
          elevation: 4,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: onTap,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 40, color: color),
                  SizedBox(height: 12),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (badgeCount != null && badgeCount > 0)
          Positioned(
            right: 8,
            top: 8,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(12),
              ),
              constraints: BoxConstraints(minWidth: 24, minHeight: 24),
              child: Text(
                badgeCount.toString(),
                style: TextStyle(color: Colors.white, fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }
}
