import 'package:flutter/material.dart';

class ManageJobsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Manage Jobs"),
        backgroundColor: Colors.deepPurple,
      ),
      body: const Center(
        child: Text(
          "Job posting management features coming soon.",
          style: TextStyle(fontSize: 16),
        ),
      ),
    );
  }
}
