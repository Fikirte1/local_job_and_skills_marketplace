import 'package:flutter/material.dart';

class MessagesScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Messages"),
        backgroundColor: Colors.pink,
      ),
      body: const Center(
        child: Text(
          "All admin messages and conversations will appear here.",
          style: TextStyle(fontSize: 16),
        ),
      ),
    );
  }
}
