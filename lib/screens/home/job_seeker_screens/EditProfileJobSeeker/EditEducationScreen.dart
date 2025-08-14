import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../../../models/job _seeker_models/education_model.dart';
import '../../../../utilities/education_data.dart';

class EditEducationScreen extends StatefulWidget {
  final Education? education;
  final Function()? onSave;

  const EditEducationScreen({
    super.key,
    this.education,
    this.onSave,
  });

  @override
  State<EditEducationScreen> createState() => _EditEducationScreenState();
}

class _EditEducationScreenState extends State<EditEducationScreen> {
  final _formKey = GlobalKey<FormState>();
  late String _educationType;
  String? _selectedInstitution;
  String? _selectedField;
  String? _selectedDegree;
  late DateTime _startDate;
  late DateTime? _endDate;
  late bool _isCurrent;
  bool _isSaving = false;
  final List<String> _availableInstitutions = [];
  final List<String> _availableFields = [];
  final List<String> _availableDegrees = [];

  @override
  void initState() {
    super.initState();
    _initializeForm();
  }

  void _initializeForm() {
    _educationType = widget.education?.educationType ?? 'University';
    _startDate = widget.education?.startDate ?? DateTime.now();
    _endDate = widget.education?.endDate;
    _isCurrent = widget.education?.isCurrent ?? false;
    _selectedInstitution = widget.education?.institution;
    _selectedField = widget.education?.fieldOfStudy;
    _selectedDegree = widget.education?.degree;
    _updateAvailableOptions();
  }

  void _updateAvailableOptions() {
    setState(() {
      _availableInstitutions.clear();
      _availableFields.clear();
      _availableDegrees.clear();

      switch (_educationType) {
        case 'High School':
          _availableInstitutions.addAll(EducationData.highSchools);
          _availableFields.addAll(['Natural', 'Social']);
          _availableDegrees.addAll(['Grade 8', 'Grade 9', 'Grade 10', 'Grade 11', 'Grade 12']);
          break;
        case 'College':
          _availableInstitutions.addAll(EducationData.colleges);
          _availableFields.addAll(EducationData.departments);
          _availableDegrees.addAll(['Certificate', 'Diploma', 'Advanced Diploma']);
          break;
        case 'University':
          _availableInstitutions.addAll(EducationData.universities);
          _availableFields.addAll(EducationData.departments);
          _availableDegrees.addAll(['Bachelor', 'Master', 'PhD', 'Postdoc']);
          break;
      }

      // Reset invalid selections
      if (_selectedInstitution != null && !_availableInstitutions.contains(_selectedInstitution)) {
        _selectedInstitution = null;
      }
      if (_selectedField != null && !_availableFields.contains(_selectedField)) {
        _selectedField = null;
      }
      if (_selectedDegree != null && !_availableDegrees.contains(_selectedDegree)) {
        _selectedDegree = null;
      }
    });
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

  Future<void> _saveEducation() async {
    if (!_formKey.currentState!.validate()) return;

    final missingFields = <String>[];
    if (_selectedInstitution == null) missingFields.add('Institution');
    if (_selectedField == null) missingFields.add('Field of Study');
    if (_selectedDegree == null) missingFields.add('Degree');
    if (!_isCurrent && _endDate == null) missingFields.add('End Date');

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

      final education = Education(
        id: widget.education?.id,
        institution: _selectedInstitution!,
        fieldOfStudy: _selectedField!,
        degree: _selectedDegree!,
        educationType: _educationType,
        startDate: _startDate,
        endDate: _isCurrent ? null : _endDate,
        isCurrent: _isCurrent,
      );

      final docRef = FirebaseFirestore.instance.collection('jobSeekers').doc(user.uid);
      final batch = FirebaseFirestore.instance.batch();

      if (widget.education != null) {
        batch.update(docRef, {
          'educationHistory': FieldValue.arrayRemove([widget.education!.toMap()]),
        });
      }

      batch.update(docRef, {
        'educationHistory': FieldValue.arrayUnion([education.toMap()]),
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
        title: Text(widget.education == null ? 'Add Education' : 'Edit Education'),
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
                      'Education Details',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Education Type
                    DropdownButtonFormField<String>(
                      value: _educationType,
                      decoration: InputDecoration(
                        labelText: 'Education Level*',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.grey[50],
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'High School',
                          child: Text('High School'),
                        ),
                        DropdownMenuItem(
                          value: 'College',
                          child: Text('College'),
                        ),
                        DropdownMenuItem(
                          value: 'University',
                          child: Text('University'),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() => _educationType = value!);
                        _updateAvailableOptions();
                      },
                      validator: (value) => value == null ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),

                    // Institution
                    DropdownButtonFormField<String>(
                      value: _selectedInstitution,
                      decoration: InputDecoration(
                        labelText: 'Institution*',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.grey[50],
                      ),
                      hint: const Text('Select your institution'),
                      items: _availableInstitutions
                          .map((inst) => DropdownMenuItem(
                        value: inst,
                        child: Text(inst),
                      ))
                          .toList(),
                      onChanged: (value) => setState(() => _selectedInstitution = value),
                      validator: (value) => value == null ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),

                    // Field of Study
                    DropdownButtonFormField<String>(
                      value: _selectedField,
                      decoration: InputDecoration(
                        labelText: 'Field of Study*',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.grey[50],
                      ),
                      hint: const Text('Select your field'),
                      items: _availableFields
                          .map((field) => DropdownMenuItem(
                        value: field,
                        child: Text(field),
                      ))
                          .toList(),
                      onChanged: (value) => setState(() => _selectedField = value),
                      validator: (value) => value == null ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),

                    // Degree
                    DropdownButtonFormField<String>(
                      value: _selectedDegree,
                      decoration: InputDecoration(
                        labelText: 'Degree/Level*',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.grey[50],
                      ),
                      hint: const Text('Select your degree'),
                      items: _availableDegrees
                          .map((degree) => DropdownMenuItem(
                        value: degree,
                        child: Text(degree),
                      ))
                          .toList(),
                      onChanged: (value) => setState(() => _selectedDegree = value),
                      validator: (value) => value == null ? 'Required' : null,
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

                    // Start Date
                    ListTile(
                      title: const Text('Start Date*'),
                      subtitle: Text(
                        DateFormat.yMMMM().format(_startDate),
                        style: const TextStyle(fontSize: 16),
                      ),
                      trailing: const Icon(Icons.calendar_month),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.grey[300]!),
                      ),
                      onTap: () => _selectDate(context, true),
                    ),
                    const SizedBox(height: 16),

                    // Currently Enrolled
                    SwitchListTile(
                      title: const Text('Currently enrolled'),
                      value: _isCurrent,
                      onChanged: (value) => setState(() {
                        _isCurrent = value;
                        if (!value && _endDate == null) {
                          _endDate = DateTime.now();
                        }
                      }),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.grey[300]!),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // End Date (conditional)
                    if (!_isCurrent)
                      ListTile(
                        title: const Text('End Date*'),
                        subtitle: Text(
                          _endDate == null
                              ? 'Select end date'
                              : DateFormat.yMMMM().format(_endDate!),
                          style: const TextStyle(fontSize: 16),
                        ),
                        trailing: const Icon(Icons.calendar_month),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: Colors.grey[300]!),
                        ),
                        onTap: () => _selectDate(context, false),
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
                  onPressed: _isSaving ? null : _saveEducation,
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
                    'SAVE EDUCATION',
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