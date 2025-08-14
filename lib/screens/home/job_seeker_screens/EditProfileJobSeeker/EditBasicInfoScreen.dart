import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../../models/job _seeker_models/job_seeker_model.dart';
import '../../../../utilities/region_city_data.dart';

class EditBasicInfoScreen extends StatefulWidget {
  final JobSeeker jobSeeker;

  const EditBasicInfoScreen({super.key, required this.jobSeeker});

  @override
  State<EditBasicInfoScreen> createState() => _EditBasicInfoScreenState();
}

class _EditBasicInfoScreenState extends State<EditBasicInfoScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _portfolioController;
  late String _selectedGender;
  late String? _selectedTitle;
  late String? _selectedRegion;
  late String? _selectedCity;
  late List<String> _selectedLanguages;
  late List<String> _portfolioLinks;
  final List<String> _availableCities = [];
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    _nameController = TextEditingController(text: widget.jobSeeker.name);
    _phoneController = TextEditingController(text: widget.jobSeeker.contactNumber);
    _portfolioController = TextEditingController();
    _selectedGender = widget.jobSeeker.sex;
    _selectedTitle = widget.jobSeeker.userTitle;
    _selectedRegion = widget.jobSeeker.region;
    _selectedCity = widget.jobSeeker.city;
    _selectedLanguages = List.from(widget.jobSeeker.languages ?? []);
    _portfolioLinks = List.from(widget.jobSeeker.portfolioLinks ?? []);

    // Initialize cities if region is already selected
    if (_selectedRegion != null) {
      _availableCities.addAll(RegionCityData.regionCitiesMap[_selectedRegion] ?? []);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _portfolioController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      await FirebaseFirestore.instance.collection('jobSeekers').doc(user.uid).update({
        'name': _nameController.text.trim(),
        'contactNumber': _phoneController.text.trim(),
        'sex': _selectedGender,
        'userTitle': _selectedTitle,
        'region': _selectedRegion,
        'city': _selectedCity,
        'languages': _selectedLanguages,
        'portfolioLinks': _portfolioLinks,
        'isProfileComplete': widget.jobSeeker.checkProfileComplete(),
      });

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update: ${e.toString()}'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _updateAvailableCities(String? region) {
    setState(() {
      _availableCities.clear();
      if (region != null) {
        _availableCities.addAll(RegionCityData.regionCitiesMap[region] ?? []);
      }
      if (_selectedCity != null && !_availableCities.contains(_selectedCity)) {
        _selectedCity = null;
      }
    });
  }

  void _addPortfolioLink() {
    final link = _portfolioController.text.trim();
    if (link.isEmpty || _portfolioLinks.contains(link)) return;

    if (!link.startsWith('http://') && !link.startsWith('https://')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid URL starting with http:// or https://'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      _portfolioLinks.add(link);
      _portfolioController.clear();
    });
  }

  bool _validateEthiopianPhoneNumber(String? value) {
    if (value == null || value.isEmpty) return false;

    final cleaned = value.replaceAll(RegExp(r'[^\d+]'), '');

    final ethiopianRegex = RegExp(
      r'^(\+251|251|0)?(9|7)[0-9]{8}$',
    );

    return ethiopianRegex.hasMatch(cleaned);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile Information'),
        elevation: 3,
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Basic Information',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'This information helps employers find and contact you',
                      style: TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                    const SizedBox(height: 16),

                    // Name Field
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Full Name*',
                        hintText: 'Your full name as it appears on official documents',
                        prefixIcon: Icon(Icons.person),
                        border: OutlineInputBorder(),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      validator: (value) => value?.trim().isEmpty ?? true ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),

                    // Email Field (read-only)
                    TextFormField(
                      initialValue: widget.jobSeeker.email,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        hintText: 'Your primary email address',
                        prefixIcon: Icon(Icons.email),
                        border: OutlineInputBorder(),
                        filled: true,
                      ),
                      readOnly: true,
                    ),
                    const SizedBox(height: 16),

                    // Phone Field
                    TextFormField(
                      controller: _phoneController,
                      decoration: const InputDecoration(
                        labelText: 'Phone Number*',
                        hintText: 'e.g. +251912345678 or 0912345678',
                        prefixIcon: Icon(Icons.phone),
                        border: OutlineInputBorder(),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      keyboardType: TextInputType.phone,
                      validator: (value) {
                        if (value?.trim().isEmpty ?? true) return 'Required';
                        if (!_validateEthiopianPhoneNumber(value)) {
                          return 'Please enter a valid Ethiopian phone number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Gender Dropdown
                    DropdownButtonFormField<String>(
                      value: _selectedGender,
                      items: const [
                        DropdownMenuItem(value: 'Male', child: Text('Male')),
                        DropdownMenuItem(value: 'Female', child: Text('Female')),
                        DropdownMenuItem(value: 'Other', child: Text('Other')),
                      ],
                      onChanged: (value) => setState(() => _selectedGender = value!),
                      decoration: const InputDecoration(
                        labelText: 'Gender*',
                        hintText: 'Select your gender',
                        prefixIcon: Icon(Icons.person_outline),
                        border: OutlineInputBorder(),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      validator: (value) => value == null ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),

                    // Professional Title Dropdown
                    DropdownButtonFormField<String>(
                      value: _selectedTitle,
                      hint: const Text('Select your professional title'),
                      items: RegionCityData.professional_title
                          .map((title) => DropdownMenuItem(
                        value: title,
                        child: Text(title.capitalize()),
                      ))
                          .toList(),
                      onChanged: (value) => setState(() => _selectedTitle = value),
                      decoration: const InputDecoration(
                        labelText: 'Professional Title',
                        hintText: 'E.g. Software Engineer, Accountant',
                        prefixIcon: Icon(Icons.work_outline),
                        border: OutlineInputBorder(),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Region Dropdown
                    DropdownButtonFormField<String>(
                      value: _selectedRegion,
                      hint: const Text('Select your region'),
                      items: RegionCityData.regions
                          .map((region) => DropdownMenuItem(
                        value: region,
                        child: Text(region),
                      ))
                          .toList(),
                      onChanged: (value) {
                        setState(() => _selectedRegion = value);
                        _updateAvailableCities(value);
                      },
                      decoration: const InputDecoration(
                        labelText: 'Region',
                        hintText: 'Select your administrative region',
                        prefixIcon: Icon(Icons.location_on),
                        border: OutlineInputBorder(),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // City Dropdown (depends on region)
                    DropdownButtonFormField<String>(
                      value: _selectedCity,
                      hint: const Text('Select your city'),
                      items: _availableCities
                          .map((city) => DropdownMenuItem(
                        value: city,
                        child: Text(city),
                      ))
                          .toList(),
                      onChanged: (value) => setState(() => _selectedCity = value),
                      decoration: const InputDecoration(
                        labelText: 'City',
                        hintText: 'Select your city or nearest town',
                        prefixIcon: Icon(Icons.location_city),
                        border: OutlineInputBorder(),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      disabledHint: const Text('Please select a region first'),
                    ),
                    const SizedBox(height: 16),

                    // Languages Multi-Select
                    InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Languages You Speak',
                        hintText: 'Add all languages you are proficient in',
                        prefixIcon: Icon(Icons.language),
                        border: OutlineInputBorder(),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_selectedLanguages.isNotEmpty)
                            Wrap(
                              spacing: 8,
                              children: _selectedLanguages
                                  .map((lang) => Chip(
                                label: Text(lang.capitalize()),
                                onDeleted: () => setState(
                                        () => _selectedLanguages.remove(lang)),
                              ))
                                  .toList(),
                            ),
                          if (_selectedLanguages.isNotEmpty) const SizedBox(height: 8),
                          DropdownButton<String>(
                            hint: const Text('Add language'),
                            value: null,
                            items: RegionCityData.languages
                                .where((lang) => !_selectedLanguages.contains(lang))
                                .map((lang) => DropdownMenuItem(
                              value: lang,
                              child: Text(lang.capitalize()),
                            ))
                                .toList(),
                            onChanged: (value) {
                              if (value != null) {
                                setState(() => _selectedLanguages.add(value));
                              }
                            },
                            isExpanded: true,
                            underline: const SizedBox(),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Portfolio Links Section
                    const Text(
                      'Portfolio Links',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Add links to your work samples, GitHub, LinkedIn, etc.',
                      style: TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                    const SizedBox(height: 16),

                    // Portfolio Links Input
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _portfolioController,
                            decoration: const InputDecoration(
                              labelText: 'Portfolio Link',
                              hintText: 'https://example.com',
                              prefixIcon: Icon(Icons.link),
                              border: OutlineInputBorder(),
                              filled: true,
                              fillColor: Colors.white,
                            ),
                            keyboardType: TextInputType.url,
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.add),
                          onPressed: _addPortfolioLink,
                          tooltip: 'Add link',
                          style: IconButton.styleFrom(
                            backgroundColor: Theme.of(context).primaryColor,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Portfolio Links List
                    if (_portfolioLinks.isNotEmpty)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Your Portfolio Links:',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          ..._portfolioLinks.map((link) => ListTile(
                            title: Text(link),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => setState(() => _portfolioLinks.remove(link)),
                            ),
                          )),
                        ],
                      ),
                  ],
                ),
              ),
            ),

            // Save Button at Bottom
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveChanges,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isSaving
                      ? const CircularProgressIndicator()
                      : const Text(
                    'SAVE CHANGES',
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

extension StringExtension on String {
  String capitalizeB() {
    if (isEmpty) return this;
    return "${this[0].toUpperCase()}${substring(1).toLowerCase()}";
  }
}