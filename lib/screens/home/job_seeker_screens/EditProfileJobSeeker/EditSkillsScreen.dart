import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../models/job _seeker_models/job_seeker_model.dart';
import '../../../../utilities/skills_data.dart';

class EditSkillsScreen extends StatefulWidget {
  final JobSeeker jobSeeker;

  const EditSkillsScreen({super.key, required this.jobSeeker});

  @override
  State<EditSkillsScreen> createState() => _EditSkillsScreenState();
}

class _EditSkillsScreenState extends State<EditSkillsScreen> {
  late List<String> _selectedSkills;
  final List<String> _filteredSkills = [];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedSkills = List.from(widget.jobSeeker.skills ?? []);
    _filteredSkills.addAll(SkillsData.allSkills);
    _searchController.addListener(_filterSkills);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterSkills() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredSkills.clear();
      if (query.isEmpty) {
        _filteredSkills.addAll(SkillsData.allSkills);
      } else {
        _filteredSkills.addAll(
          SkillsData.allSkills.where(
                (skill) => skill.toLowerCase().contains(query),
          ),
        );
      }
    });
  }

  Future<void> _saveChanges() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _showErrorSnackbar('You must be logged in to save changes');
        return;
      }

      setState(() {}); // Show loading state

      await FirebaseFirestore.instance
          .collection('jobSeekers')
          .doc(user.uid)
          .update({
        'skills': _selectedSkills.isEmpty ? null : _selectedSkills,
      });

      if (mounted) {
        _showSuccessSnackbar('Skills updated successfully');
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackbar('Failed to update skills: ${e.toString()}');
      }
    }
  }

  void _toggleSkill(String skill) {
    setState(() {
      if (_selectedSkills.contains(skill)) {
        _selectedSkills.remove(skill);
      } else {
        _selectedSkills.add(skill);
      }
    });
  }

  void _showSuccessSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Skills'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.save_rounded),
            onPressed: _saveChanges,
            tooltip: 'Save Skills',
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search skills...',
                hintText: 'Type to filter skills',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: isDarkMode
                    ? Colors.grey[800]
                    : Colors.grey[100],
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
            ),
          ),
          if (_selectedSkills.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  Text(
                    'Selected Skills (${_selectedSkills.length})',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => setState(() => _selectedSkills.clear()),
                    child: Text(
                      'Clear All',
                      style: TextStyle(
                        color: theme.colorScheme.error,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _selectedSkills.map((skill) {
                  return Chip(
                    label: Text(skill),
                    backgroundColor: theme.colorScheme.primaryContainer,
                    deleteIcon: Icon(
                      Icons.close,
                      size: 18,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                    onDeleted: () => _toggleSkill(skill),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  );
                }).toList(),
              ),
            ),
            const Divider(height: 16),
          ],
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.only(top: 8),
              itemCount: _filteredSkills.length,
              itemBuilder: (context, index) {
                final skill = _filteredSkills[index];
                return ListTile(
                  leading: Checkbox(
                    value: _selectedSkills.contains(skill),
                    onChanged: (_) => _toggleSkill(skill),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  title: Text(
                    skill,
                    style: theme.textTheme.bodyLarge,
                  ),
                  onTap: () => _toggleSkill(skill),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}