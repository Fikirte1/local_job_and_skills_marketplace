import 'package:flutter/material.dart';

class JobSeekerGeneralScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Manage Job Seekers'),
        backgroundColor: Colors.indigo,
      ),
      body: Center(
        child: Text(
          'Job Seeker General Info',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
