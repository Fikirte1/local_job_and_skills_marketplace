import 'package:flutter/material.dart';

// Import your actual screens
import 'employer_verification_screen.dart';
import 'subscription_screen.dart';
import 'general_employer_screen.dart';

class ManageEmployersScreen extends StatefulWidget {
  @override
  _ManageEmployersScreenState createState() => _ManageEmployersScreenState();
}

class _ManageEmployersScreenState extends State<ManageEmployersScreen> {
  int _selectedIndex = 0; // Default to "General"

  final List<Widget> _pages = [
    EmployerVerificationScreen(),
    GeneralEmployerScreen(),
    SubscriptionScreen(),
  ];

  final List<String> _titles = [
    'Verification',
    'Manage Employers',
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
            icon: Icon(Icons.verified_user),
            label: 'Verification',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'General',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.subscriptions),
            label: 'Subscription',
          ),
        ],
      ),
    );
  }
}
