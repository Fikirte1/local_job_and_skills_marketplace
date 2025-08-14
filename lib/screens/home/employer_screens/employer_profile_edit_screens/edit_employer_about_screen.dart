import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../models/employer_model/employer_model.dart';

class EditEmployerAboutScreen extends StatefulWidget {
  final Employer employer;

  const EditEmployerAboutScreen({super.key, required this.employer});

  @override
  State<EditEmployerAboutScreen> createState() => _EditEmployerAboutScreenState();
}

class _EditEmployerAboutScreenState extends State<EditEmployerAboutScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _aboutCompanyController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _aboutCompanyController = TextEditingController(text: widget.employer.aboutCompany);
  }

  @override
  void dispose() {
    _aboutCompanyController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not authenticated');

      await FirebaseFirestore.instance.collection('employers').doc(user.uid).update({
        'aboutCompany': _aboutCompanyController.text.trim(),
      });

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit About Company'),
        elevation: 0,
      ),
      body: SafeArea(
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _aboutCompanyController,
                      maxLines: 10,
                      decoration: InputDecoration(
                        labelText: 'About Company',
                        filled: true,
                        fillColor: Colors.grey[100],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        alignLabelWithHint: true,
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter information about the company';
                        }
                        if (value.trim().length < 50) {
                          return 'Description should be at least 50 characters';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Describe your company, mission, values, and what makes you unique.',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
            // Save button fixed at bottom
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveChanges,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 4,
                ),
                child: _isSaving
                    ? const SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                )
                    : const Text(
                  'Save',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold,color: Colors.cyan),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
