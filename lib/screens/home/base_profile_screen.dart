/*
import 'package:flutter/material.dart';

class BaseProfileScreen extends StatelessWidget {
  final String name;
  final String email;
  final String? contactNumber;
  final String? location;
  final String? about;
  final String? imageUrl;
  final String defaultImage;
  final List<Widget>? additionalSections;

  const BaseProfileScreen({
    Key? key,
    required this.name,
    required this.email,
    required this.defaultImage,
    this.contactNumber,
    this.location,
    this.about,
    this.imageUrl,
    this.additionalSections,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "$name's Profile",
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.indigo.shade400, Colors.indigo.shade700],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Header
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundImage: imageUrl != null
                        ? NetworkImage(imageUrl!)
                        : AssetImage(defaultImage) as ImageProvider,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.indigo,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Contact Information
            _buildSectionTitle("Contact Information"),
            _buildListTile(Icons.email, "Email", email),
            if (contactNumber != null)
              _buildListTile(Icons.phone, "Contact Number", contactNumber!),
            const Divider(height: 30),

            // About Section
            if (about != null) ...[
              _buildSectionTitle("About"),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  about!,
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ],
            if (location != null)
              _buildListTile(Icons.location_on, "Location", location!),
            const Divider(height: 30),

            // Additional Sections
            if (additionalSections != null) ...additionalSections!,
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.indigo,
        ),
      ),
    );
  }

  Widget _buildListTile(IconData icon, String title, String subtitle) {
    return ListTile(
      leading: Icon(icon, color: Colors.indigo),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Text(subtitle),
    );
  }
}
*/
