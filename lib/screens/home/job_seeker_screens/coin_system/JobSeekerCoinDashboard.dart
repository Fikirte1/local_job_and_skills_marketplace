import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:local_job_and_skills_marketplace/screens/home/job_seeker_screens/coin_system/payment_details_screen.dart';

import 'CoinRequestListScreen.dart';
import 'CoinRequest_model.dart';
import 'coin_package_selection.dart';
import 'coin_service.dart';

class JobSeekerCoinDashboard extends StatefulWidget {
  const JobSeekerCoinDashboard({super.key});

  @override
  State<JobSeekerCoinDashboard> createState() => _JobSeekerCoinDashboardState();
}

class _JobSeekerCoinDashboardState extends State<JobSeekerCoinDashboard> {
  int _currentIndex = 0;
  final List<Widget> _screens = [
    const CoinPackageSelectionScreen(),
    const CoinRequestListScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Coin System'),
        actions: [
          IconButton(
            icon: const Icon(Icons.account_balance_wallet),
            onPressed: () {
              // Show current balance dialog
              _showBalanceDialog(context);
            },
          ),
        ],
      ),
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.add_circle_outline),
            label: 'Purchase Coins',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'My Requests',
          ),
        ],
      ),
    );
  }

  Future<void> _showBalanceDialog(BuildContext context) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    final balance = await CoinService.getCoinBalance(userId);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Current Balance'),
        content: Text(
          'You have $balance coins available',
          style: const TextStyle(fontSize: 18),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

