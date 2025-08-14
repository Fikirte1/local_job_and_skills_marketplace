/*
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:local_job_and_skills_marketplace/services/auth_service.dart';
import 'package:local_job_and_skills_marketplace/screens/auth/signIn_screen.dart';

import '../../../models/job _seeker_models/education_model.dart';
import '../../../models/job _seeker_models/job_seeker_model.dart';
import '../../../models/job _seeker_models/work_experience_model.dart';

class EditProfileScreen extends StatefulWidget {
  @override
  _EditProfileScreenState createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  final _authService = AuthService();

  // Personal Info Controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _contactNumberController = TextEditingController();
  final TextEditingController _aboutMeController = TextEditingController();

  // Dropdown values
  String? _selectedSex;
  String? _selectedTitle;
  String? _selectedRegion;
  String? _selectedCity;

  // Skills
  final TextEditingController _skillsController = TextEditingController();
  List<String> _skillsList = [];

  // Education
  late List<Education> _educationHistory = [];
  final TextEditingController _institutionController = TextEditingController();
  final TextEditingController _fieldOfStudyController = TextEditingController();
  final TextEditingController _degreeController = TextEditingController();
  DateTime? _educationStartDate;
  DateTime? _educationEndDate;
  bool _isCurrentlyStudying = false;

  // Work Experience
  late List<WorkExperience> _workExperience = [];
  final TextEditingController _companyController = TextEditingController();
  final TextEditingController _positionController = TextEditingController();
  final TextEditingController _jobDescriptionController = TextEditingController();
  DateTime? _workStartDate;
  DateTime? _workEndDate;
  bool _isCurrentlyWorking = false;

  // Portfolio and Resume
  final TextEditingController _portfolioLinkController = TextEditingController();
  String? _resumeUrl;
  bool _isUploadingResume = false;

  // Profile State
  bool _isLoading = true;
  bool _isSaving = false;

  // Region/City data
  final List<String> _regions = [
    'Amhara', 'Oromia', 'Tigray', 'SNNP', 'Somali',
    'Afar', 'Benishangul-Gumuz', 'Gambela', 'Harari',
    'Addis Ababa', 'Dire Dawa'
  ];

  List<String> _cities = [];
  final Map<String, List<String>> _regionCitiesMap = {
    'Amhara': ['Bahir Dar', 'Gondar', 'Dessie', 'Debre Markos', 'Woldia'],
    'Oromia': ['Adama', 'Jimma', 'Bishoftu', 'Ambo', 'Nekemte'],
    'Tigray': ['Mekelle', 'Adigrat', 'Axum', 'Shire', 'Humera'],
    'SNNP': ['Hawassa', 'Arba Minch', 'Dilla', 'Wolaita Sodo', 'Jinka'],
    'Somali': ['Jijiga', 'Degehabur', 'Kebri Dahar', 'Gode', 'Shilavo'],
    'Afar': ['Semera', 'Asaita', 'Awash', 'Gewane', 'Logiya'],
    'Benishangul-Gumuz': ['Asosa', 'Bambasi', 'Menge', 'Kurmuk', 'Sherkole'],
    'Gambela': ['Gambela', 'Agnwa', 'Itang', 'Gog', 'Abobo'],
    'Harari': ['Harar', 'Dire Dawa', 'Hirna', 'Alemaya', 'Kombolcha'],
    'Addis Ababa': ['Addis Ababa'],
    'Dire Dawa': ['Dire Dawa'],
  };

  // Dropdown options
  final List<String> _sexOptions = ['Male', 'Female', 'Other'];
  final List<String> _titleOptions = [
    'Software Developer',
    'UX Designer',
    'Project Manager',
    'Data Scientist',
    'Marketing Specialist',
    'Other'
  ];

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _logout() async {
    try {
      await _authService.logout();
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => SignInScreen()),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error during logout: ${e.toString()}')),
      );
    }
  }

  void _updateCities(String? region) {
    setState(() {
      _selectedCity = null;
      _cities = region != null ? _regionCitiesMap[region] ?? [] : [];
    });
  }

  Future<void> _loadProfileData() async {
    if (!mounted) return;

    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    try {
      final snapshot = await _firestore.collection('jobSeekers').doc(currentUser.uid).get();

      if (!mounted) return;

      if (snapshot.exists) {
        final jobSeeker = JobSeeker.fromMap(snapshot.data()!);

        if (!mounted) return;

        setState(() {
          _nameController.text = jobSeeker.name;
          _contactNumberController.text = jobSeeker.contactNumber;
          _aboutMeController.text = jobSeeker.aboutMe ?? '';
          _selectedSex = jobSeeker.sex;
          _selectedTitle = jobSeeker.userTitle;
          _selectedRegion = jobSeeker.region;
          _selectedCity = jobSeeker.city;
          _skillsList = jobSeeker.skills ?? [];
          _educationHistory = jobSeeker.educationHistory ?? [];
          _workExperience = jobSeeker.workExperience ?? [];
          _resumeUrl = jobSeeker.resumeUrl;
          _portfolioLinkController.text = jobSeeker.portfolioLinks?.first ?? '';
          _isLoading = false;
        });

        if (jobSeeker.region != null && mounted) {
          _updateCities(jobSeeker.region!);
        }
      } else {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading profile: $e')),
        );
      }
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      final currentUser = _auth.currentUser;
      if (currentUser != null) {
        final updatedJobSeeker = JobSeeker(
          userId: currentUser.uid,
          name: _nameController.text.trim(),
          email: currentUser.email ?? '',
          contactNumber: _contactNumberController.text.trim(),
          sex: _selectedSex ?? '',
          userTitle: _selectedTitle,
          region: _selectedRegion,
          city: _selectedCity,
          aboutMe: _aboutMeController.text.trim(),
          skills: _skillsList,
          educationHistory: _educationHistory,
          workExperience: _workExperience,
          resumeUrl: _resumeUrl,
          portfolioLinks: _portfolioLinkController.text.trim().isNotEmpty
              ? [_portfolioLinkController.text.trim()]
              : null,
        );

        await _firestore.collection('jobSeekers').doc(currentUser.uid).set(
          updatedJobSeeker.toMap(),
          SetOptions(merge: true),
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully!')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving profile: $e')),
      );
    } finally {
      setState(() => _isSaving = false);
    }
  }

  void _addSkill() {
    if (_skillsController.text.trim().isNotEmpty) {
      setState(() {
        _skillsList.add(_skillsController.text.trim());
        _skillsController.clear();
      });
    }
  }

  void _removeSkill(int index) {
    setState(() => _skillsList.removeAt(index));
  }

  Future<void> _uploadResume() async {
    setState(() => _isUploadingResume = true);
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (result != null) {
        final file = result.files.single;
        final fileName = 'resumes/${_auth.currentUser!.uid}/${DateTime.now().millisecondsSinceEpoch}.pdf';
        final ref = FirebaseStorage.instance.ref().child(fileName);
        final uploadTask = ref.putData(file.bytes!);
        final snapshot = await uploadTask.whenComplete(() {});
        final downloadUrl = await snapshot.ref.getDownloadURL();

        setState(() {
          _resumeUrl = downloadUrl;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Resume uploaded successfully!')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error uploading resume: $e')),
      );
    } finally {
      setState(() => _isUploadingResume = false);
    }
  }

  void _addEducation() {
    if (_institutionController.text.trim().isEmpty ||
        _fieldOfStudyController.text.trim().isEmpty ||
        _degreeController.text.trim().isEmpty ||
        _educationStartDate == null ||
        (!_isCurrentlyStudying && _educationEndDate == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all education fields')),
      );
      return;
    }

    setState(() {
      _educationHistory.add(Education(
        institution: _institutionController.text.trim(),
        fieldOfStudy: _fieldOfStudyController.text.trim(),
        degree: _degreeController.text.trim(),
        startDate: _educationStartDate!,
        endDate: _isCurrentlyStudying ? null : _educationEndDate,
        isCurrent: _isCurrentlyStudying,
      ));

      // Clear fields
      _institutionController.clear();
      _fieldOfStudyController.clear();
      _degreeController.clear();
      _educationStartDate = null;
      _educationEndDate = null;
      _isCurrentlyStudying = false;
    });
  }

  void _addWorkExperience() {
    if (_companyController.text.trim().isEmpty ||
        _positionController.text.trim().isEmpty ||
        _workStartDate == null ||
        (!_isCurrentlyWorking && _workEndDate == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all work experience fields')),
      );
      return;
    }

    setState(() {
      _workExperience.add(WorkExperience(
        company: _companyController.text.trim(),
        positionTitle: _positionController.text.trim(),
        description: _jobDescriptionController.text.trim(),
        startDate: _workStartDate!,
        endDate: _isCurrentlyWorking ? null : _workEndDate,
        isCurrent: _isCurrentlyWorking,
      ));

      // Clear fields
      _companyController.clear();
      _positionController.clear();
      _jobDescriptionController.clear();
      _workStartDate = null;
      _workEndDate = null;
      _isCurrentlyWorking = false;
    });
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate, {bool isEducation = false}) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        if (isEducation) {
          if (isStartDate) {
            _educationStartDate = picked;
          } else {
            _educationEndDate = picked;
          }
        } else {
          if (isStartDate) {
            _workStartDate = picked;
          } else {
            _workEndDate = picked;
          }
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _isSaving ? null : _saveProfile,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Personal Information Section
              _buildSectionHeader('Personal Information'),
              _buildTextField(_nameController, 'Full Name', isRequired: true),
              _buildTextField(_contactNumberController, 'Contact Number',
                  keyboardType: TextInputType.phone, isRequired: true),
              _buildTextField(_aboutMeController, 'About Me', maxLines: 3),

              // Region Dropdown
              DropdownButtonFormField<String>(
                value: _selectedRegion != null && _regions.contains(_selectedRegion)
                    ? _selectedRegion
                    : null,
                decoration: const InputDecoration(
                  labelText: 'Region',
                  border: OutlineInputBorder(),
                ),
                items: _regions.map((region) => DropdownMenuItem(
                  value: region,
                  child: Text(region),
                )).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedRegion = value;
                    _updateCities(value);
                  });
                },
                validator: (value) => value == null ? 'Please select your region' : null,
              ),
              const SizedBox(height: 16),

              // City Dropdown
              DropdownButtonFormField<String>(
                value: _selectedCity != null && _cities.contains(_selectedCity)
                    ? _selectedCity
                    : null,
                decoration: const InputDecoration(
                  labelText: 'City',
                  border: OutlineInputBorder(),
                ),
                items: _cities.map((city) => DropdownMenuItem(
                  value: city,
                  child: Text(city),
                )).toList(),
                onChanged: _selectedRegion == null
                    ? null
                    : (value) => setState(() => _selectedCity = value),
                validator: _selectedRegion != null && _selectedCity == null
                    ? (value) => 'Please select your city'
                    : null,
              ),
              const SizedBox(height: 16),

              // Sex Dropdown
              DropdownButtonFormField<String>(
                value: _selectedSex != null && _sexOptions.contains(_selectedSex)
                    ? _selectedSex
                    : null,
                decoration: const InputDecoration(
                  labelText: 'Sex',
                  border: OutlineInputBorder(),
                ),
                items: _sexOptions.map((sex) => DropdownMenuItem(
                  value: sex,
                  child: Text(sex),
                )).toList(),
                onChanged: (value) => setState(() => _selectedSex = value),
                validator: (value) => value == null ? 'Please select your sex' : null,
              ),
              const SizedBox(height: 16),

              // Professional Title Dropdown
              DropdownButtonFormField<String>(
                value: _selectedTitle != null && _titleOptions.contains(_selectedTitle)
                    ? _selectedTitle
                    : null,
                decoration: const InputDecoration(
                  labelText: 'Professional Title',
                  border: OutlineInputBorder(),
                ),
                items: _titleOptions.map((title) => DropdownMenuItem(
                  value: title,
                  child: Text(title),
                )).toList(),
                onChanged: (value) => setState(() => _selectedTitle = value),
              ),

              // Skills Section
              _buildSectionHeader('Skills'),
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(_skillsController, 'Add Skill'),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: _addSkill,
                  ),
                ],
              ),
              if (_skillsList.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: List.generate(_skillsList.length, (index) => Chip(
                    label: Text(_skillsList[index]),
                    onDeleted: () => _removeSkill(index),
                  )),
                ),
              ],

              // Education Section
              _buildSectionHeader('Education'),
              _buildEducationForm(),
              if (_educationHistory.isNotEmpty) ...[
                const SizedBox(height: 16),
                ..._educationHistory.map((edu) => _buildEducationCard(edu)).toList(),
              ],

              // Work Experience Section
              _buildSectionHeader('Work Experience'),
              _buildWorkExperienceForm(),
              if (_workExperience.isNotEmpty) ...[
                const SizedBox(height: 16),
                ..._workExperience.map((exp) => _buildWorkExperienceCard(exp)).toList(),
              ],

              // Resume Upload Section
              _buildSectionHeader('Resume'),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_resumeUrl != null) ...[
                        ListTile(
                          leading: Icon(Icons.picture_as_pdf, color: Colors.red),
                          title: Text('Resume.pdf'),
                          subtitle: Text('Click to view'),
                          trailing: IconButton(
                            icon: Icon(Icons.delete, color: Colors.red),
                            onPressed: () => setState(() => _resumeUrl = null),
                          ),
                          onTap: () {
                            // Open the PDF URL
                            // launchUrl(Uri.parse(_resumeUrl!));
                          },
                        ),
                        const SizedBox(height: 8),
                      ],
                      ElevatedButton(
                        onPressed: _isUploadingResume ? null : _uploadResume,
                        child: _isUploadingResume
                            ? CircularProgressIndicator(color: Colors.white)
                            : Text(_resumeUrl == null ? 'Upload Resume' : 'Replace Resume'),
                        style: ElevatedButton.styleFrom(
                          minimumSize: Size(double.infinity, 48),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Upload your resume in PDF format (max 5MB)',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),

              // Portfolio Link Section
              _buildSectionHeader('Portfolio Link'),
              _buildTextField(_portfolioLinkController, 'Portfolio Link (e.g., GitHub, LinkedIn, Website)'),

              // Save Button
              const SizedBox(height: 24),
              Center(
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveProfile,
                  child: _isSaving
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Save Profile'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Logout Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _logout,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade50,
                    foregroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(color: Colors.red.shade200),
                    ),
                  ),
                  child: const Text('Logout'),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 12),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.bold,
          color: Theme.of(context).primaryColor,
        ),
      ),
    );
  }

  Widget _buildTextField(
      TextEditingController controller,
      String label, {
        TextInputType keyboardType = TextInputType.text,
        int maxLines = 1,
        bool isRequired = false,
      }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        keyboardType: keyboardType,
        maxLines: maxLines,
        validator: isRequired
            ? (value) => value == null || value.isEmpty ? 'Please enter $label' : null
            : null,
      ),
    );
  }

  Widget _buildEducationForm() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTextField(_institutionController, 'Institution', isRequired: true),
            _buildTextField(_fieldOfStudyController, 'Field of Study', isRequired: true),
            _buildTextField(_degreeController, 'Degree', isRequired: true),

            // Education Dates
            Row(
              children: [
                Expanded(
                  child: ListTile(
                    title: Text(_educationStartDate == null
                        ? 'Start Date'
                        : DateFormat.yMMMd().format(_educationStartDate!)),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () => _selectDate(context, true, isEducation: true),
                  ),
                ),
                Expanded(
                  child: ListTile(
                    title: Text(_isCurrentlyStudying
                        ? 'Currently Studying'
                        : _educationEndDate == null
                        ? 'End Date'
                        : DateFormat.yMMMd().format(_educationEndDate!)),
                    trailing: _isCurrentlyStudying
                        ? Checkbox(
                      value: true,
                      onChanged: (val) => setState(() => _isCurrentlyStudying = val!),
                    )
                        : IconButton(
                      icon: const Icon(Icons.calendar_today),
                      onPressed: () => _selectDate(context, false, isEducation: true),
                    ),
                  ),
                ),
              ],
            ),
            if (!_isCurrentlyStudying && _educationEndDate == null)
              const Text('Please select end date', style: TextStyle(color: Colors.red)),

            SwitchListTile(
              title: const Text('Currently Studying'),
              value: _isCurrentlyStudying,
              onChanged: (value) => setState(() => _isCurrentlyStudying = value),
            ),

            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _addEducation,
              child: const Text('Add Education'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkExperienceForm() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTextField(_companyController, 'Company', isRequired: true),
            _buildTextField(_positionController, 'Position', isRequired: true),
            _buildTextField(_jobDescriptionController, 'Description', maxLines: 3),

            // Work Dates
            Row(
              children: [
                Expanded(
                  child: ListTile(
                    title: Text(_workStartDate == null
                        ? 'Start Date'
                        : DateFormat.yMMMd().format(_workStartDate!)),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () => _selectDate(context, true),
                  ),
                ),
                Expanded(
                  child: ListTile(
                    title: Text(_isCurrentlyWorking
                        ? 'Currently Working'
                        : _workEndDate == null
                        ? 'End Date'
                        : DateFormat.yMMMd().format(_workEndDate!)),
                    trailing: _isCurrentlyWorking
                        ? Checkbox(
                      value: true,
                      onChanged: (val) => setState(() => _isCurrentlyWorking = val!),
                    )
                        : IconButton(
                      icon: const Icon(Icons.calendar_today),
                      onPressed: () => _selectDate(context, false),
                    ),
                  ),
                ),
              ],
            ),
            if (!_isCurrentlyWorking && _workEndDate == null)
              const Text('Please select end date', style: TextStyle(color: Colors.red)),

            SwitchListTile(
              title: const Text('Currently Working Here'),
              value: _isCurrentlyWorking,
              onChanged: (value) => setState(() => _isCurrentlyWorking = value),
            ),

            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _addWorkExperience,
              child: const Text('Add Work Experience'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEducationCard(Education education) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  education.institution,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => setState(() => _educationHistory.remove(education)),
                ),
              ],
            ),
            Text(education.degree),
            Text(education.fieldOfStudy),
            Text(
              '${DateFormat.yMMMd().format(education.startDate)} - ${education.isCurrent ? 'Present' : education.endDate != null ? DateFormat.yMMMd().format(education.endDate!) : 'N/A'}',
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkExperienceCard(WorkExperience experience) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  experience.company,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => setState(() => _workExperience.remove(experience)),
                ),
              ],
            ),
            Text(
              experience.positionTitle,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            if (experience.description?.isNotEmpty ?? false) ...[
              const SizedBox(height: 8),
              Text(experience.description!),
            ],
            Text(
              '${DateFormat.yMMMd().format(experience.startDate)} - ${experience.isCurrent ? 'Present' : experience.endDate != null ? DateFormat.yMMMd().format(experience.endDate!) : 'N/A'}',
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _contactNumberController.dispose();
    _aboutMeController.dispose();
    _skillsController.dispose();
    _institutionController.dispose();
    _fieldOfStudyController.dispose();
    _degreeController.dispose();
    _companyController.dispose();
    _positionController.dispose();
    _jobDescriptionController.dispose();
    _portfolioLinkController.dispose();
    super.dispose();
  }
}*/
