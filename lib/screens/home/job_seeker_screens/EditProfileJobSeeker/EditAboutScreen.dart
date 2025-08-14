import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../models/job _seeker_models/job_seeker_model.dart';

class EditAboutScreen extends StatefulWidget {
  final JobSeeker jobSeeker;

  const EditAboutScreen({super.key, required this.jobSeeker});

  @override
  State<EditAboutScreen> createState() => _EditAboutScreenState();
}

class _EditAboutScreenState extends State<EditAboutScreen> {
  late TextEditingController _aboutController;
  int _characterCount = 0;
  final int _maxCharacters = 1000;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _aboutController = TextEditingController(text: widget.jobSeeker.aboutMe ?? '');
    _characterCount = _aboutController.text.length;
    _aboutController.addListener(_updateCharacterCount);
  }

  void _updateCharacterCount() {
    setState(() {
      _characterCount = _aboutController.text.length;
    });
  }

  @override
  void dispose() {
    _aboutController.removeListener(_updateCharacterCount);
    _aboutController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      await FirebaseFirestore.instance.collection('jobSeekers').doc(user.uid).update({
        'aboutMe': _aboutController.text.isEmpty ? null : _aboutController.text,
      });

      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update: $e'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Craft Your Professional Story'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 100), // Extra bottom padding for FAB
        child: SingleChildScrollView(
          controller: _scrollController,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Describe Yourself',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[800],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'This is your chance to shine! Share your professional journey, skills, and what makes you unique.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 20),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 2,
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TextFormField(
                  controller: _aboutController,
                  maxLines: 10,
                  maxLength: _maxCharacters,
                  decoration: InputDecoration(
                    hintText: 'Example:\n\n"Experienced software developer with 5+ years specializing in mobile app development. Passionate about creating intuitive user experiences and solving complex problems. Strong background in Flutter, Dart, and Firebase. Committed to continuous learning and delivering high-quality solutions."',
                    hintStyle: TextStyle(color: Colors.grey[400]),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.all(16),
                    counterText: '$_characterCount/$_maxCharacters characters',
                    counterStyle: TextStyle(
                      color: _characterCount > _maxCharacters ? Colors.red : Colors.grey,
                    ),
                  ),
                  style: const TextStyle(height: 1.5),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.lightbulb_outline, color: Colors.amber[700]),
                        const SizedBox(width: 8),
                        Text(
                          'Writing Tips',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[800],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _buildTipItem('Start with your professional identity and years of experience'),
                    _buildTipItem('Highlight your key skills and specialties'),
                    _buildTipItem('Mention notable achievements or projects'),
                    _buildTipItem('Share your professional values or work philosophy'),
                    _buildTipItem('Keep it concise but impactful (300-500 characters ideal)'),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              if (_characterCount > _maxCharacters)
                Text(
                  'You\'ve exceeded the maximum character limit',
                  style: TextStyle(color: Colors.red[600]),
                ),
            ],
          ),
        ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 20), // Additional padding from bottom
        child: FloatingActionButton.extended(
          icon: const Icon(Icons.check_rounded),
          label: const Text('Save Profile'),
          backgroundColor: _characterCount <= _maxCharacters ? Colors.blue[600] : Colors.grey,
          foregroundColor: Colors.white,
          onPressed: _characterCount <= _maxCharacters ? _saveChanges : null,
          elevation: 2,
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildTipItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 4),
            child: Icon(Icons.circle, size: 8, color: Colors.blue),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}