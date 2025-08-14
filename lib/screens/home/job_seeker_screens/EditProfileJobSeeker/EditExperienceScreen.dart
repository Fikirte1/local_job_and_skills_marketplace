import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../../../models/job _seeker_models/work_experience_model.dart';

class EditExperienceScreen extends StatefulWidget {
  final WorkExperience? experience;
  final Function()? onSave;

  const EditExperienceScreen({
    super.key,
    this.experience,
    this.onSave,
  });

  @override
  State<EditExperienceScreen> createState() => _EditExperienceScreenState();
}

class _EditExperienceScreenState extends State<EditExperienceScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _positionController;
  late TextEditingController _companyController;
  late TextEditingController _descriptionController;
  late DateTime _startDate;
  late DateTime? _endDate;
  late bool _isCurrent;
  late bool _isSelfEmployed;
  late String? _selectedJobSite;
  late String? _selectedEmploymentType;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _initializeForm();
  }

  void _initializeForm() {
    _positionController = TextEditingController(
      text: widget.experience?.positionTitle ?? '',
    );
    _companyController = TextEditingController(
      text: widget.experience?.company ?? '',
    );
    _descriptionController = TextEditingController(
      text: widget.experience?.description ?? '',
    );
    _startDate = widget.experience?.startDate ?? DateTime.now();
    _endDate = widget.experience?.endDate;
    _isCurrent = widget.experience?.isCurrent ?? false;
    _isSelfEmployed = widget.experience?.isSelfEmployed ?? false;
    _selectedJobSite = widget.experience?.jobSite;
    _selectedEmploymentType = widget.experience?.employmentType;
  }

  @override
  void dispose() {
    _positionController.dispose();
    _companyController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStartDate ? _startDate : _endDate ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).primaryColor,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).primaryColor,
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
          if (_endDate != null && _endDate!.isBefore(picked)) {
            _endDate = null;
          }
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _saveExperience() async {
    if (!_formKey.currentState!.validate()) return;

    final missingFields = <String>[];
    if (_positionController.text.isEmpty) missingFields.add('Position Title');
    if (_companyController.text.isEmpty) missingFields.add('Company');
    if (!_isCurrent && _endDate == null) missingFields.add('End Date');
    if (!_isSelfEmployed) {
      if (_selectedJobSite == null) missingFields.add('Job Site');
      if (_selectedEmploymentType == null) missingFields.add('Employment Type');
    }

    if (missingFields.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please fill all required fields: ${missingFields.join(', ')}'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not logged in');

      final experience = WorkExperience(
        id: widget.experience?.id,
        positionTitle: _positionController.text.trim(),
        company: _companyController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        startDate: _startDate,
        endDate: _isCurrent ? null : _endDate,
        isCurrent: _isCurrent,
        isSelfEmployed: _isSelfEmployed,
        jobSite: _isSelfEmployed ? null : _selectedJobSite,
        employmentType: _isSelfEmployed ? null : _selectedEmploymentType,
      );

      final docRef = FirebaseFirestore.instance.collection('jobSeekers').doc(user.uid);
      final batch = FirebaseFirestore.instance.batch();

      if (widget.experience != null) {
        batch.update(docRef, {
          'workExperience': FieldValue.arrayRemove([widget.experience!.toMap()]),
        });
      }

      batch.update(docRef, {
        'workExperience': FieldValue.arrayUnion([experience.toMap()]),
      });

      await batch.commit();

      if (widget.onSave != null) widget.onSave!();
      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save: ${e.toString()}'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.experience == null ? 'Add Experience' : 'Edit Experience'),
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Work Experience Details',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Position Title
                    TextFormField(
                      controller: _positionController,
                      decoration: InputDecoration(
                        labelText: 'Position Title*',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.grey[50],
                      ),
                      validator: (value) =>
                      value?.trim().isEmpty ?? true ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),

                    // Company Name
                    TextFormField(
                      controller: _companyController,
                      decoration: InputDecoration(
                        labelText: 'Company/Organization*',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.grey[50],
                      ),
                      validator: (value) =>
                      value?.trim().isEmpty ?? true ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),

                    // Self-employed toggle
                    SwitchListTile(
                      title: const Text('Self-employed/Freelancer'),
                      value: _isSelfEmployed,
                      onChanged: (value) => setState(() => _isSelfEmployed = value),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.grey[300]!),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Job Site (conditionally shown)
                    if (!_isSelfEmployed) ...[
                      DropdownButtonFormField<String>(
                        value: _selectedJobSite,
                        decoration: InputDecoration(
                          labelText: 'Job Site*',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'On-site',
                            child: Text('On-site'),
                          ),
                          DropdownMenuItem(
                            value: 'Remote',
                            child: Text('Remote'),
                          ),
                          DropdownMenuItem(
                            value: 'Hybrid',
                            child: Text('Hybrid'),
                          ),
                        ],
                        onChanged: (value) =>
                            setState(() => _selectedJobSite = value),
                        validator: (value) =>
                        !_isSelfEmployed && value == null ? 'Required' : null,
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Employment Type (conditionally shown)
                    if (!_isSelfEmployed) ...[
                      DropdownButtonFormField<String>(
                        value: _selectedEmploymentType,
                        decoration: InputDecoration(
                          labelText: 'Employment Type*',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'Full-time',
                            child: Text('Full-time'),
                          ),
                          DropdownMenuItem(
                            value: 'Part-time',
                            child: Text('Part-time'),
                          ),
                          DropdownMenuItem(
                            value: 'Contract',
                            child: Text('Contract'),
                          ),
                          DropdownMenuItem(
                            value: 'Internship',
                            child: Text('Internship'),
                          ),
                          DropdownMenuItem(
                            value: 'Temporary',
                            child: Text('Temporary'),
                          ),
                        ],
                        onChanged: (value) =>
                            setState(() => _selectedEmploymentType = value),
                        validator: (value) =>
                        !_isSelfEmployed && value == null ? 'Required' : null,
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Description
                    TextFormField(
                      controller: _descriptionController,
                      maxLines: 4,
                      decoration: InputDecoration(
                        labelText: 'Description (Responsibilities & Achievements)',
                        alignLabelWithHint: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.grey[50],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Date Section
                    const Text(
                      'Duration',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.grey[300]!),
                      ),
                      child: Column(
                        children: [
                          // Start Date
                          ListTile(
                            title: const Text('Start Date*'),
                            subtitle: Text(
                              DateFormat.yMMMM().format(_startDate),
                              style: const TextStyle(fontSize: 16),
                            ),
                            trailing: const Icon(Icons.calendar_month),
                            onTap: () => _selectDate(context, true),
                          ),
                          const Divider(height: 1, indent: 16, endIndent: 16),

                          // Currently Working Here
                          SwitchListTile(
                            title: const Text('I currently work here'),
                            value: _isCurrent,
                            onChanged: (value) => setState(() {
                              _isCurrent = value;
                              if (!value && _endDate == null) {
                                _endDate = DateTime.now();
                              }
                            }),
                          ),

                          // End Date (conditionally shown)
                          if (!_isCurrent) ...[
                            const Divider(height: 1, indent: 16, endIndent: 16),
                            ListTile(
                              title: const Text('End Date*'),
                              subtitle: Text(
                                _endDate == null
                                    ? 'Select end date'
                                    : DateFormat.yMMMM().format(_endDate!),
                                style: const TextStyle(fontSize: 16),
                              ),
                              trailing: const Icon(Icons.calendar_month),
                              onTap: () => _selectDate(context, false),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Save Button
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveExperience,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                      : const Text(
                    'SAVE EXPERIENCE',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}