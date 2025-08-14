import 'package:flutter/material.dart';

// Import your actual Job Seeker screens
import 'jobseeker_general_screen.dart';
import 'jobseeker_subscription_screen.dart';

class ManageJobSeekersScreen extends StatefulWidget {
  @override
  _ManageJobSeekersScreenState createState() => _ManageJobSeekersScreenState();
}

class _ManageJobSeekersScreenState extends State<ManageJobSeekersScreen> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    AdminCoinApprovalScreen(),
    JobSeekerGeneralScreen(),
  ];

  final List<String> _titles = [
    'Manage Job Seekers',
    'Subscription',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.indigo,
        unselectedItemColor: Colors.grey,
        backgroundColor: Colors.white,
        elevation: 10,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.subscriptions),
            label: 'Subscription',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'General',
          ),
        ],
      ),
    );
  }
}
