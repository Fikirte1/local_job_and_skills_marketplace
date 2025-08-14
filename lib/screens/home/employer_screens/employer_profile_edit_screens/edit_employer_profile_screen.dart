import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../models/employer_model/employer_model.dart';
import '../../../../utilities/industry_data.dart';
import '../../../../utilities/region_city_data.dart';

class EditEmployerProfileScreen extends StatefulWidget {
  final Employer employer;

  const EditEmployerProfileScreen({super.key, required this.employer});

  @override
  State<EditEmployerProfileScreen> createState() => _EditEmployerProfileScreenState();
}

class _EditEmployerProfileScreenState extends State<EditEmployerProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late TextEditingController _companyNameController;
  late TextEditingController _websiteController;
  late TextEditingController _contactNumberController;
  String? _selectedRegion;
  String? _selectedCity;
  String? _selectedIndustry;
  final _industries = IndustryData().industries;
  List<String> _availableCities = [];
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _companyNameController = TextEditingController(text: widget.employer.companyName);
    _websiteController = TextEditingController(text: widget.employer.website?.replaceAll('https://', '') ?? '');
    _contactNumberController = TextEditingController(text: widget.employer.contactNumber);
    _selectedRegion = widget.employer.region;
    _selectedCity = widget.employer.city;
    _selectedIndustry = widget.employer.industry;

    if (_selectedRegion != null) {
      _availableCities = RegionCityData.regionCitiesMap[_selectedRegion!] ?? [];
    }
  }

  @override
  void dispose() {
    _companyNameController.dispose();
    _websiteController.dispose();
    _contactNumberController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Company Profile'),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    _buildCompanyNameField(),
                    const SizedBox(height: 20),
                    _buildIndustryDropdown(),
                    const SizedBox(height: 20),
                    _buildWebsiteField(),
                    const SizedBox(height: 20),
                    _buildContactNumberField(),
                    const SizedBox(height: 20),
                    _buildRegionDropdown(),
                    const SizedBox(height: 20),
                    _buildCityDropdown(),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
            _buildSaveButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildCompanyNameField() {
    return TextFormField(
      controller: _companyNameController,
      decoration: InputDecoration(
        labelText: 'Company Name*',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.grey),
        ),
        filled: true,
        fillColor: Colors.grey[50],
        prefixIcon: const Icon(Icons.business),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Company name is required';
        }
        if (value.length < 3) {
          return 'Company name too short';
        }
        return null;
      },
      inputFormatters: [
        LengthLimitingTextInputFormatter(100),
      ],
    );
  }

  Widget _buildIndustryDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedIndustry,
      decoration: InputDecoration(
        labelText: 'Industry',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.grey),
        ),
        filled: true,
        fillColor: Colors.grey[50],
        prefixIcon: const Icon(Icons.category),
      ),
      items: _industries.map((industry) {
        return DropdownMenuItem<String>(
          value: industry,
          child: Text(industry),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          _selectedIndustry = value;
        });
      },
      hint: const Text('Select Industry'),
      isExpanded: true,
    );
  }

  Widget _buildWebsiteField() {
    return TextFormField(
      controller: _websiteController,
      decoration: InputDecoration(
        labelText: 'Website',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.grey),
        ),
        filled: true,
        fillColor: Colors.grey[50],
        prefixIcon: const Icon(Icons.link),
        prefixText: 'https://',
      ),
      keyboardType: TextInputType.url,
      validator: (value) {
        if (value != null && value.isNotEmpty) {
          if (!Uri.parse('https://$value').isAbsolute) {
            return 'Please enter a valid URL';
          }
        }
        return null;
      },
    );
  }

  Widget _buildContactNumberField() {
    return TextFormField(
      controller: _contactNumberController,
      decoration: InputDecoration(
        labelText: 'Contact Number*',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.grey),
        ),
        filled: true,
        fillColor: Colors.grey[50],
        prefixIcon: const Icon(Icons.phone),
        prefixText: '+251 ',
      ),
      keyboardType: TextInputType.phone,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Contact number is required';
        }
        final cleaned = value.replaceAll(RegExp(r'\s+'), '');
        if (!RegExp(r'^[79][0-9]{8}$').hasMatch(cleaned)) {
          return 'Enter a valid 9-digit Ethiopian number (e.g. 912345678)';
        }
        return null;
      },
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(9), // Ethiopian mobile numbers: 9 digits
      ],
    );
  }


  Widget _buildRegionDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedRegion,
      decoration: InputDecoration(
        labelText: 'Region/State',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.grey),
        ),
        filled: true,
        fillColor: Colors.grey[50],
        prefixIcon: const Icon(Icons.map),
      ),
      items: RegionCityData.regions.map((region) {
        return DropdownMenuItem<String>(
          value: region,
          child: Text(region),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          _selectedRegion = value;
          _selectedCity = null;
          _availableCities = value != null
              ? RegionCityData.regionCitiesMap[value] ?? []
              : [];
        });
      },
      hint: const Text('Select Region'),
      isExpanded: true,
    );
  }

  Widget _buildCityDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedCity,
      decoration: InputDecoration(
        labelText: 'City',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.grey),
        ),
        filled: true,
        fillColor: Colors.grey[50],
        prefixIcon: const Icon(Icons.location_city),
      ),
      items: _availableCities.map((city) {
        return DropdownMenuItem<String>(
          value: city,
          child: Text(city),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          _selectedCity = value;
        });
      },
      hint: const Text('Select City'),
      isExpanded: true,
      validator: (value) {
        if (_selectedRegion != null && value == null) {
          return 'Please select a city for the region';
        }
        return null;
      },
    );
  }

  Widget _buildSaveButton() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _isSaving ? null : _saveChanges,
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).primaryColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: _isSaving
              ? const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              color: Colors.white,
              strokeWidth: 2,
            ),
          )
              : const Text(
            'SAVE CHANGES',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final updatedData = {
        'companyName': _companyNameController.text.trim(),
        'industry': _selectedIndustry,
        'website': _websiteController.text.trim().isEmpty
            ? null
            : 'https://${_websiteController.text.trim()}',
        'contactNumber': _contactNumberController.text.trim(),
        'region': _selectedRegion,
        'city': _selectedCity,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Remove null values from the update map
      updatedData.removeWhere((key, value) => value == null);

      await _firestore
          .collection('employers')
          .doc(user.uid)
          .update(updatedData);

      final updatedEmployer = widget.employer.copyWith(
        companyName: _companyNameController.text.trim(),
        industry: _selectedIndustry,
        website: _websiteController.text.trim().isEmpty
            ? null
            : 'https://${_websiteController.text.trim()}',
        contactNumber: _contactNumberController.text.trim(),
        region: _selectedRegion,
        city: _selectedCity,
      );

      if (mounted) {
        Navigator.pop(context, updatedEmployer);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update profile: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }
}