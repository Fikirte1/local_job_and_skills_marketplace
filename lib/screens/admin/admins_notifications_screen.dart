import 'package:flutter/material.dart';

class AdminsNotificationsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Notifications"),
        backgroundColor: Colors.orange,
      ),
      body: const Center(
        child: Text(
          "All system notifications will be displayed here.",
          style: TextStyle(fontSize: 16),
        ),
      ),
    );
  }
}
