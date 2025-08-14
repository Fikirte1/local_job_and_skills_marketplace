import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../../utilities/FieldsOfStudyData.dart';
import '../../../utilities/job_category_data.dart';
import '../../../utilities/region_city_data.dart';
import '../../../utilities/skills_data.dart';

class AddJobScreen extends StatefulWidget {
  final String? jobId;

  AddJobScreen({this.jobId});

  @override
  _AddJobScreenState createState() => _AddJobScreenState();
}

class _AddJobScreenState extends State<AddJobScreen> {
  final _formKey = GlobalKey<FormState>();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Controllers
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _salaryController = TextEditingController();
  final TextEditingController _positionsController = TextEditingController(text: '1');
  final TextEditingController _skillsSearchController = TextEditingController();
  final TextEditingController _fieldsSearchController = TextEditingController();
  final TextEditingController _languagesSearchController = TextEditingController();

  // Dropdown values
  String? _selectedRegion;
  String? _selectedCity;
  String _jobSite = 'On-site';
  String _jobType = 'Full-time';
  String _experienceLevel = 'Entry';
  String _requiredGender = 'Any';
  String _jobCategory = 'Technology';
  String _educationLevel = "Bachelor's";
  DateTime? _applicationDeadline;

  // Multi-select values
  List<String> _selectedSkills = [];
  List<String> _filteredSkills = [];
  List<String> _selectedFieldsOfStudy = [];
  List<String> _filteredFields = [];
  List<String> _selectedLanguages = ['English'];
  List<String> _filteredLanguages = [];

  @override
  void initState() {
    super.initState();
    _filteredSkills.addAll(SkillsData.allSkills);
    _filteredFields.addAll(FieldsOfStudyData.allFields); // Updated this line

    _filteredLanguages.addAll(RegionCityData.languages);

    _skillsSearchController.addListener(_filterSkills);
    _fieldsSearchController.addListener(_filterFields);
    _languagesSearchController.addListener(_filterLanguages);

    if (widget.jobId != null) {
      _loadJobData();
    }
  }

  @override
  void dispose() {
    _skillsSearchController.dispose();
    _fieldsSearchController.dispose();
    _languagesSearchController.dispose();
    super.dispose();
  }

  void _filterSkills() {
    final query = _skillsSearchController.text.toLowerCase();
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

  void _filterFields() {
    final query = _fieldsSearchController.text.toLowerCase();
    setState(() {
      _filteredFields.clear();
      if (query.isEmpty) {
        _filteredFields.addAll(FieldsOfStudyData.allFields);
      } else {
        _filteredFields.addAll(
          FieldsOfStudyData.allFields.where(
                (field) => field.toLowerCase().contains(query),
          ),
        );
      }
    });
  }

  void _filterLanguages() {
    final query = _languagesSearchController.text.toLowerCase();
    setState(() {
      _filteredLanguages.clear();
      if (query.isEmpty) {
        _filteredLanguages.addAll(RegionCityData.languages);
      } else {
        _filteredLanguages.addAll(
          RegionCityData.languages.where(
                (lang) => lang.toLowerCase().contains(query),
          ),
        );
      }
    });
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

  void _toggleField(String field) {
    setState(() {
      if (_selectedFieldsOfStudy.contains(field)) {
        _selectedFieldsOfStudy.remove(field);
      } else {
        _selectedFieldsOfStudy.add(field);
      }
    });
  }

  void _toggleLanguage(String language) {
    setState(() {
      if (_selectedLanguages.contains(language)) {
        _selectedLanguages.remove(language);
      } else {
        _selectedLanguages.add(language);
      }
    });
  }

  Future<void> _loadJobData() async {
    try {
      final doc = await _firestore.collection('jobs').doc(widget.jobId).get();
      if (doc.exists) {
        final data = doc.data()!;

        _titleController.text = data['title'] ?? '';
        _descriptionController.text = data['description'] ?? '';
        _salaryController.text = data['salaryRange'] ?? '';
        _positionsController.text = data['numberOfPositions']?.toString() ?? '1';

        setState(() {
          _selectedRegion = data['region'];
          _selectedCity = data['city'];
          _jobSite = data['jobSite'] ?? 'On-site';
          _jobType = data['jobType'] ?? 'Full-time';
          _experienceLevel = data['experienceLevel'] ?? 'Entry';
          _requiredGender = data['requiredGender'] ?? 'Any';
          _jobCategory = data['jobCategory'] ?? 'Tech';
          _educationLevel = data['educationLevel'] ?? "Bachelor's";
          _selectedSkills = List<String>.from(data['requiredSkills'] ?? []);
          _selectedFieldsOfStudy = List<String>.from(data['fieldsOfStudy'] ?? []);
          _selectedLanguages = List<String>.from(data['languages'] ?? ['English']);
          _applicationDeadline = (data['applicationDeadline'] as Timestamp?)?.toDate();
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to load job data: $e")),
      );
    }
  }

  Future<void> _pickDate() async {
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (selectedDate != null) {
      setState(() {
        _applicationDeadline = selectedDate;
      });
    }
  }

  Future<void> _saveJob() async {
    if (!_formKey.currentState!.validate()) return;

    if (_applicationDeadline == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select an application deadline")),
      );
      return;
    }

    if (_selectedRegion == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a region")),
      );
      return;
    }

    if (_selectedCity == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a city")),
      );
      return;
    }

    if (_selectedSkills.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select at least one skill")),
      );
      return;
    }

    if (_selectedFieldsOfStudy.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select at least one field of study")),
      );
      return;
    }


    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("User not authenticated! Please log in again.")),
      );
      return;
    }

    try {
      final jobData = {
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'region': _selectedRegion,
        'city': _selectedCity,
        'jobSite': _jobSite,
        'requiredSkills': _selectedSkills,
        'salaryRange': _salaryController.text.trim(),
        'jobType': _jobType,
        'applicationDeadline': _applicationDeadline,
        'experienceLevel': _experienceLevel,
        'requiredGender': _requiredGender,
        'fieldsOfStudy': _selectedFieldsOfStudy,
        'numberOfPositions': int.tryParse(_positionsController.text.trim()) ?? 1,
        'jobCategory': _jobCategory,
        'educationLevel': _educationLevel,
        'languages': _selectedLanguages,
        'employerId': currentUser.uid,
        'status': 'Open',
        'approvalStatus': 'Not Approved',
        'postStatus': 'Draft',
        'reviewStatus': 'Not submitted',
        'datePosted': FieldValue.serverTimestamp(),
      };

      if (widget.jobId == null) {
        await _firestore.collection('jobs').add(jobData);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Job added successfully!")),
        );
      } else {
        await _firestore.collection('jobs').doc(widget.jobId).update(jobData);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Job updated successfully!")),
        );
      }

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to save job: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.jobId == null ? "Add Job" : "Edit Job"),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader("Job Title", icon: Icons.work_outline),
              _buildTitleField(),


              _buildSectionHeader("Job Description", icon: Icons.description_outlined),
              _buildDescriptionField(),

              _buildSectionHeader("Location", icon: Icons.location_on_outlined),
              _buildRegionCityFields(),

              _buildSectionHeader("Work Site Type", icon: Icons.apartment),
              _buildJobSiteDropdown(),

              _buildSectionHeader("Required Skills", icon: Icons.build_outlined),
              const Text("Search and select the technical or soft skills needed for this role."),
              _buildSkillsSearchField(),
              _buildSelectedChips(_selectedSkills, _toggleSkill),
              _buildSearchableList(_filteredSkills, _selectedSkills, _toggleSkill),

              _buildSectionHeader("Salary Range", icon: Icons.monetization_on_outlined),
              _buildSalaryField(),

              _buildSectionHeader("Job Preferences", icon: Icons.tune_outlined),
              _buildJobTypeDropdown(),
              _buildExperienceLevelDropdown(),
              _buildGenderDropdown(),

              _buildSectionHeader("Fields of Study", icon: Icons.school_outlined),
              const Text("Specify the academic fields that are relevant to this position."),
              _buildFieldsSearchField(),
              _buildSelectedChips(_selectedFieldsOfStudy, _toggleField),
              _buildSearchableList(_filteredFields, _selectedFieldsOfStudy, _toggleField),

              _buildSectionHeader("Number of Positions", icon: Icons.group_outlined),
              _buildPositionsField(),

              _buildSectionHeader("Job Category", icon: Icons.category_outlined),
              _buildJobCategoryDropdown(),

              _buildSectionHeader("Minimum Education Level", icon: Icons.cast_for_education),
              _buildEducationLevelDropdown(),

              _buildSectionHeader("Required Languages", icon: Icons.language_outlined),
              const Text("Search and select languages the candidate must know."),
              _buildLanguagesSearchField(),
              _buildSelectedChips(_selectedLanguages, _toggleLanguage),
              _buildSearchableList(_filteredLanguages, _selectedLanguages, _toggleLanguage, capitalize: true),

              _buildSectionHeader("Application Deadline", icon: Icons.calendar_today_outlined),
              _buildDatePicker(),

              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _saveJob,
                  icon: const Icon(Icons.save),
                  label: const Text("Save Job Posting"),
                  style: ElevatedButton.styleFrom(
                    elevation: 3,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      )
    );
  }

  Widget _buildSectionHeader(String title, {IconData icon = Icons.label}) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Theme.of(context).colorScheme.onBackground,
              ),
            ),
          ),
        ],
      ),
    );
  }



  Widget _buildTitleField() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        controller: _titleController,
        decoration: InputDecoration(
          labelText: "Job Title",
          hintText: "e.g., Mobile Developer",
          helperText: "Specify a clear and concise title for the position.",
          prefixIcon: const Icon(Icons.work_outline),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          filled: true,
          fillColor: Colors.grey.shade50,
        ),
        validator: (value) =>
        value == null || value.trim().isEmpty ? "Please enter a job title" : null,
      ),
    );
  }


  Widget _buildDescriptionField() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        controller: _descriptionController,
        decoration: InputDecoration(
          labelText: "Job Description",
          hintText: "Describe the role, responsibilities, and expectations.",
          helperText: "Provide a detailed overview of the job requirements.",
          prefixIcon: const Icon(Icons.description_outlined),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          filled: true,
          fillColor: Colors.grey.shade50,
        ),
        maxLines: 4,
        validator: (value) =>
        value == null || value.trim().isEmpty ? "Please enter a job description" : null,
      ),
    );
  }
  Widget _buildRegionCityFields() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: DropdownButtonFormField<String>(
            value: _selectedRegion,
            items: RegionCityData.regions.map((region) {
              return DropdownMenuItem(
                value: region,
                child: Text(region),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedRegion = value;
                _selectedCity = null;
              });
            },
            decoration: InputDecoration(
              labelText: "Region",
              prefixIcon: const Icon(Icons.map_outlined),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.grey.shade50,
            ),
            validator: (value) => value == null ? "Please select a region" : null,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: DropdownButtonFormField<String>(
            value: _selectedCity,
            items: (_selectedRegion != null
                ? RegionCityData.regionCitiesMap[_selectedRegion] ?? []
                : []).map((city) {
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
            decoration: InputDecoration(
              labelText: "City",
              prefixIcon: const Icon(Icons.location_city_outlined),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.grey.shade50,
            ),
            validator: (value) =>
            _selectedRegion != null && value == null ? "Please select a city" : null,
          ),
        ),
      ],
    );
  }


  Widget _buildJobSiteDropdown() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: DropdownButtonFormField<String>(
        value: _jobSite,
        items: ['On-site', 'Remote', 'Hybrid'].map((site) {
          return DropdownMenuItem(
            value: site,
            child: Text(site),
          );
        }).toList(),
        onChanged: (value) {
          setState(() {
            _jobSite = value!;
          });
        },
        decoration: InputDecoration(
          labelText: "Work Site Type",
          hintText: "Select how the job is performed",
          prefixIcon: const Icon(Icons.work_outline),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          filled: true,
          fillColor: Colors.grey.shade50,
        ),
        validator: (value) =>
        value == null || value.isEmpty ? "Please select a job site type" : null,
      ),
    );
  }


  Widget _buildSkillsSearchField() {
    return _buildSearchField(_skillsSearchController, "Search Skills");
  }

  Widget _buildFieldsSearchField() {
    return _buildSearchField(_fieldsSearchController, "Search Fields of Study");
  }

  Widget _buildLanguagesSearchField() {
    return _buildSearchField(_languagesSearchController, "Search Languages");
  }

  Widget _buildSearchField(TextEditingController controller, String hint) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: hint,
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          filled: true,
          fillColor: Colors.grey[50],
        ),
      ),
    );
  }

  Widget _buildSelectedChips(List<String> items, Function(String) onRemove) {
    return items.isNotEmpty
        ? Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: items.map(
              (item) => InputChip(
            label: Text(item.capitalize()),
            onDeleted: () => onRemove(item),
            deleteIcon: const Icon(Icons.close, size: 16),
          ),
        ).toList(),
      ),
    )
        : const SizedBox();
  }

  Widget _buildSearchableList(
      List<String> items,
      List<String> selectedItems,
      Function(String) onToggle, {
        bool capitalize = false,
      }) {
    return Container(
      height: 200,
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          return CheckboxListTile(
            title: Text(capitalize ? item.capitalize() : item),
            value: selectedItems.contains(item),
            onChanged: (_) => onToggle(item),
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
          );
        },
      ),
    );
  }

  Widget _buildSalaryField() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: _salaryController,
        keyboardType: TextInputType.number,
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'[0-9\-]')),
        ],
        decoration: InputDecoration(
          labelText: "Salary Range (optional)",
          hintText: "e.g. 2000 - 3000",
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          prefixIcon: const Icon(Icons.attach_money),
          filled: true,
          fillColor: Colors.grey[50],
        ),
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            // Optional field: no error if empty
            return null;
          }
          final pattern = RegExp(r'^\s*(\d+)\s*-\s*(\d+)\s*$');
          final match = pattern.firstMatch(value);
          if (match == null) {
            return "Enter range as: 2000 - 3000";
          }
          final start = int.parse(match.group(1)!);
          final end = int.parse(match.group(2)!);
          if (start >= end) {
            return "End salary must be greater than start";
          }
          return null;
        },
      ),
    );
  }


  Widget _buildJobTypeDropdown() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: DropdownButtonFormField<String>(
        value: _jobType,
        items: ['Full-time', 'Part-time', 'Contract', 'Internship'].map((type) {
          return DropdownMenuItem(
            value: type,
            child: Text(type),
          );
        }).toList(),
        onChanged: (value) {
          setState(() {
            _jobType = value!;
          });
        },
        decoration: InputDecoration(
          labelText: "Job Type",
          hintText: "Select job type",
          prefixIcon: const Icon(Icons.work_outline),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }


  Widget _buildExperienceLevelDropdown() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: DropdownButtonFormField<String>(
        value: _experienceLevel,
        items: ['Entry', 'Mid', 'Senior'].map((level) {
          return DropdownMenuItem(
            value: level,
            child: Text(level),
          );
        }).toList(),
        onChanged: (value) {
          setState(() {
            _experienceLevel = value!;
          });
        },
        decoration: InputDecoration(
          labelText: "Experience Level",
          hintText: "Select experience level",
          prefixIcon: const Icon(Icons.timeline),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }


  Widget _buildGenderDropdown() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: DropdownButtonFormField<String>(
        value: _requiredGender,
        items: ['Any', 'Male', 'Female'].map((gender) {
          return DropdownMenuItem(
            value: gender,
            child: Text(gender),
          );
        }).toList(),
        onChanged: (value) {
          setState(() {
            _requiredGender = value!;
          });
        },
        decoration: InputDecoration(
          labelText: "Gender Requirement",
          hintText: "Select gender preference",
          prefixIcon: const Icon(Icons.person_outline),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }


  Widget _buildPositionsField() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextFormField(
        controller: _positionsController,
        keyboardType: TextInputType.number,
        textInputAction: TextInputAction.next,
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.grey[50],
          labelText: "Number of Positions",
          hintText: "e.g. 3",
          prefixIcon: Icon(Icons.numbers),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        ),
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return "Please enter number of positions";
          }
          if (int.tryParse(value.trim()) == null) {
            return "Please enter a valid number";
          }
          return null;
        },
      ),
    );
  }


  Widget _buildJobCategoryDropdown() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: DropdownButtonFormField<String>(
        value: _jobCategory,
        isExpanded: true,
        icon: const Icon(Icons.arrow_drop_down),
        decoration: InputDecoration(
          labelText: "Job Category",
          hintText: "Select the most relevant category",
          prefixIcon: const Icon(Icons.category_outlined),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        ),
        items: JobCategoryData.categories.map((category) {
          return DropdownMenuItem<String>(
            value: category,
            child: Text(category),
          );
        }).toList(),
        onChanged: (value) {
          setState(() {
            _jobCategory = value!;
          });
        },
        validator: (value) =>
        value == null || value.isEmpty ? "Please select a category" : null,
      ),
    );
  }

  Widget _buildEducationLevelDropdown() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: DropdownButtonFormField<String>(
        value: _educationLevel,
        isExpanded: true,
        icon: const Icon(Icons.arrow_drop_down),
        decoration: InputDecoration(
          labelText: "Education Level",
          hintText: "Select the minimum required education",
          prefixIcon: const Icon(Icons.school_outlined),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        ),
        items: [
          'High School',
          "Bachelor's",
          "Master's",
          'PhD'
        ].map((level) {
          return DropdownMenuItem<String>(
            value: level,
            child: Text(level),
          );
        }).toList(),
        onChanged: (value) {
          setState(() {
            _educationLevel = value!;
          });
        },
        validator: (value) =>
        value == null || value.isEmpty ? "Please select an education level" : null,
      ),
    );
  }


  Widget _buildDatePicker() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: _pickDate,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade400),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Icon(Icons.calendar_today_outlined, color: Colors.grey),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _applicationDeadline != null
                      ? "Application Deadline: ${DateFormat('MMM dd, yyyy').format(_applicationDeadline!)}"
                      : "Select Application Deadline",
                  style: TextStyle(
                    fontSize: 16,
                    color: _applicationDeadline != null
                        ? Colors.black
                        : Colors.grey.shade600,
                  ),
                ),
              ),
              const Icon(Icons.edit_calendar_outlined, color: Colors.blue),
            ],
          ),
        ),
      ),
    );
  }

}

extension StringExtension on String {
  String capitalizejobtext() {
    if (isEmpty) return this;
    return "${this[0].toUpperCase()}${substring(1).toLowerCase()}";
  }
}