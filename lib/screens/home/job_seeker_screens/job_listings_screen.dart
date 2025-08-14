// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:intl/intl.dart';
// import '../../../models/employer_model/employer_model.dart';
// import '../../../models/job_model.dart';
// import '../../../utilities/region_city_data.dart';
// import '../../../utilities/skills_data.dart';
// import '../../../widgets/job_card.dart';
//
//
// class JobSearchScreen extends StatefulWidget {
//   const JobSearchScreen({Key? key}) : super(key: key);
//
//   @override
//   _JobSearchScreenState createState() => _JobSearchScreenState();
// }
//
// class _JobSearchScreenState extends State<JobSearchScreen> {
//   final TextEditingController _searchController = TextEditingController();
//   final ScrollController _scrollController = ScrollController();
//   List<JobModel> _jobs = [];
//   List<Employer> _employers = [];
//   bool _isLoading = false;
//   bool _hasMore = true;
//   DocumentSnapshot? _lastDocument;
//   final int _limit = 10;
//
//   // Filter state
//   bool _showFilters = false;
//   List<String> _selectedRegions = [];
//   List<String> _selectedCities = [];
//   List<String> _selectedJobTypes = [];
//   List<String> _selectedExperienceLevels = [];
//   List<String> _selectedJobSites = [];
//   List<String> _selectedSkills = [];
//   List<String> _selectedFieldsOfStudy = [];
//   List<String> _selectedEducationLevels = [];
//   RangeValues _salaryRange = const RangeValues(0, 100000);
//   double _maxSalary = 100000;
//
//   @override
//   void initState() {
//     super.initState();
//     _loadInitialJobs();
//     _scrollController.addListener(_scrollListener);
//     _fetchMaxSalary();
//   }
//
//   @override
//   void dispose() {
//     _searchController.dispose();
//     _scrollController.dispose();
//     super.dispose();
//   }
//
//   Future<void> _fetchMaxSalary() async {
//     try {
//       final snapshot = await FirebaseFirestore.instance
//           .collection('jobs')
//           .orderBy('salaryRange', descending: true)
//           .limit(1)
//           .get();
//
//       if (snapshot.docs.isNotEmpty) {
//         final maxSalary = double.tryParse(snapshot.docs.first['salaryRange'].replaceAll(RegExp(r'[^0-9]'), '')) ?? 100000;
//         setState(() {
//           _maxSalary = maxSalary;
//           _salaryRange = RangeValues(0, maxSalary);
//         });
//       }
//     } catch (e) {
//       debugPrint('Error fetching max salary: $e');
//     }
//   }
//
//   Future<void> _loadInitialJobs() async {
//     if (_isLoading) return;
//     setState(() => _isLoading = true);
//
//     try {
//       Query query = FirebaseFirestore.instance
//           .collection('jobs')
//           .where('status', isEqualTo: 'Open')
//           .where('approvalStatus', isEqualTo: 'Approved')
//           .orderBy('datePosted', descending: true)
//           .limit(_limit);
//
//       // Apply filters if any
//       query = _applyFilters(query);
//
//       final snapshot = await query.get();
//
//       if (snapshot.docs.isNotEmpty) {
//         _lastDocument = snapshot.docs.last;
//         final jobs = await _processJobDocuments(snapshot.docs);
//         setState(() {
//           _jobs = jobs;
//           _hasMore = jobs.length == _limit;
//         });
//       } else {
//         setState(() {
//           _hasMore = false;
//         });
//       }
//     } catch (e) {
//       debugPrint('Error loading jobs: $e');
//     } finally {
//       setState(() => _isLoading = false);
//     }
//   }
//
//   Future<void> _loadMoreJobs() async {
//     if (_isLoading || !_hasMore) return;
//     setState(() => _isLoading = true);
//
//     try {
//       Query query = FirebaseFirestore.instance
//           .collection('jobs')
//           .where('status', isEqualTo: 'Open')
//           .where('approvalStatus', isEqualTo: 'Approved')
//           .orderBy('datePosted', descending: true)
//           .startAfterDocument(_lastDocument!)
//           .limit(_limit);
//
//       // Apply filters if any
//       query = _applyFilters(query);
//
//       final snapshot = await query.get();
//
//       if (snapshot.docs.isNotEmpty) {
//         _lastDocument = snapshot.docs.last;
//         final newJobs = await _processJobDocuments(snapshot.docs);
//         setState(() {
//           _jobs.addAll(newJobs);
//           _hasMore = newJobs.length == _limit;
//         });
//       } else {
//         setState(() {
//           _hasMore = false;
//         });
//       }
//     } catch (e) {
//       debugPrint('Error loading more jobs: $e');
//     } finally {
//       setState(() => _isLoading = false);
//     }
//   }
//
//   Query _applyFilters(Query query) {
//     if (_selectedRegions.isNotEmpty) {
//       query = query.where('region', whereIn: _selectedRegions);
//     }
//
//     if (_selectedCities.isNotEmpty) {
//       query = query.where('city', whereIn: _selectedCities);
//     }
//
//     if (_selectedJobTypes.isNotEmpty) {
//       query = query.where('jobType', whereIn: _selectedJobTypes);
//     }
//
//     if (_selectedExperienceLevels.isNotEmpty) {
//       query = query.where('experienceLevel', whereIn: _selectedExperienceLevels);
//     }
//
//     if (_selectedJobSites.isNotEmpty) {
//       query = query.where('jobSite', whereIn: _selectedJobSites);
//     }
//
//     if (_selectedSkills.isNotEmpty) {
//       // For array-contains-any to match any of the selected skills
//       query = query.where('requiredSkills', arrayContainsAny: _selectedSkills);
//     }
//
//     if (_selectedFieldsOfStudy.isNotEmpty) {
//       query = query.where('fieldsOfStudy', arrayContainsAny: _selectedFieldsOfStudy);
//     }
//
//     if (_selectedEducationLevels.isNotEmpty) {
//       query = query.where('educationLevel', whereIn: _selectedEducationLevels);
//     }
//
//     // Note: Salary filtering would need a different approach since it's stored as a string
//     // This is a simplified approach - you might need to adjust based on your actual data structure
//
//     return query;
//   }
//
//   Future<List<JobModel>> _processJobDocuments(List<QueryDocumentSnapshot> docs) async {
//     final jobs = <JobModel>[];
//     final employerIds = <String>[];
//     final jobModels = docs.map((doc) => JobModel.fromMap(doc.data() as Map<String, dynamic>, doc.id)).toList();
//
//     // Collect unique employer IDs
//     for (var job in jobModels) {
//       if (!employerIds.contains(job.employerId)) {
//         employerIds.add(job.employerId);
//       }
//     }
//
//     // Fetch employers in batch
//     if (employerIds.isNotEmpty) {
//       final employerSnapshot = await FirebaseFirestore.instance
//           .collection('employers')
//           .where('userId', whereIn: employerIds)
//           .get();
//
//       _employers = employerSnapshot.docs
//           .map((doc) => Employer.fromMap(doc.data()))
//           .toList();
//     }
//
//     // Match jobs with employers
//     for (var job in jobModels) {
//       final employer = _employers.firstWhere(
//             (e) => e.userId == job.employerId,
//         orElse: () => Employer(
//           userId: '',
//           companyName: 'Unknown Company',
//           email: '',
//           contactNumber: '',
//           aboutCompany: '',
//         ),
//       );
//
//       jobs.add(job.copyWith());
//     }
//
//     return jobs;
//   }
//
//   void _scrollListener() {
//     if (_scrollController.offset >= _scrollController.position.maxScrollExtent &&
//         !_scrollController.position.outOfRange) {
//       _loadMoreJobs();
//     }
//   }
//
//   void _searchJobs(String query) {
//     // Implement search functionality
//     // This would typically involve filtering the existing list or making a new query
//     // For simplicity, we'll just trigger a refresh
//     _jobs.clear();
//     _loadInitialJobs();
//   }
//
//   void _resetFilters() {
//     setState(() {
//       _selectedRegions = [];
//       _selectedCities = [];
//       _selectedJobTypes = [];
//       _selectedExperienceLevels = [];
//       _selectedJobSites = [];
//       _selectedSkills = [];
//       _selectedFieldsOfStudy = [];
//       _selectedEducationLevels = [];
//       _salaryRange = RangeValues(0, _maxSalary);
//     });
//     _jobs.clear();
//     _loadInitialJobs();
//   }
//
//   void _applyFiltersAndClose() {
//     setState(() => _showFilters = false);
//     _jobs.clear();
//     _loadInitialJobs();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Job Search'),
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.filter_list),
//             onPressed: () => setState(() => _showFilters = !_showFilters),
//           ),
//         ],
//       ),
//       body: Column(
//         children: [
//           Padding(
//             padding: const EdgeInsets.all(12.0),
//             child: TextField(
//               controller: _searchController,
//               decoration: InputDecoration(
//                 hintText: 'Search for jobs...',
//                 prefixIcon: const Icon(Icons.search),
//                 border: OutlineInputBorder(
//                   borderRadius: BorderRadius.circular(12),
//                 ),
//                 suffixIcon: _searchController.text.isNotEmpty
//                     ? IconButton(
//                   icon: const Icon(Icons.clear),
//                   onPressed: () {
//                     _searchController.clear();
//                     _searchJobs('');
//                   },
//                 )
//                     : null,
//               ),
//               onChanged: _searchJobs,
//             ),
//           ),
//           if (_showFilters) _buildFilterPanel(),
//           Expanded(
//             child: _isLoading && _jobs.isEmpty
//                 ? const Center(child: CircularProgressIndicator())
//                 : _jobs.isEmpty
//                 ? const Center(child: Text('No jobs found'))
//                 : ListView.builder(
//               controller: _scrollController,
//               itemCount: _jobs.length + (_hasMore ? 1 : 0),
//               itemBuilder: (context, index) {
//                 if (index == _jobs.length) {
//                   return const Center(child: Padding(
//                     padding: EdgeInsets.all(16.0),
//                     child: CircularProgressIndicator(),
//                   ));
//                 }
//
//                 final job = _jobs[index];
//                 final employer = _employers.firstWhere(
//                       (e) => e.userId == job.employerId,
//                   orElse: () => Employer(
//                     userId: '',
//                     companyName: 'Unknown Company',
//                     email: '',
//                     contactNumber: '',
//                     aboutCompany: '',
//                   ),
//                 );
//
//                 return JobCard(
//                   job: job,
//                   employer: employer,
//                 );
//               },
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildFilterPanel() {
//     return Container(
//       padding: const EdgeInsets.all(12),
//       decoration: BoxDecoration(
//           color: Colors.white,
//           boxShadow: [
//       BoxShadow(
//       color: Colors.grey.withOpacity(0.3),
//       spreadRadius: 2,
//       blurRadius: 5,
//       offset: const Offset(0, 3),
//       )],
//     ),
//     child: SingleChildScrollView(
//     child: Column(
//     crossAxisAlignment: CrossAxisAlignment.start,
//     children: [
//     Row(
//     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//     children: [
//     const Text(
//     'Filters',
//     style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//     ),
//     TextButton(
//     onPressed: _resetFilters,
//     child: const Text('Reset All'),
//     ),
//     ],
//     ),
//     const Divider(),
//
//     // Region Filter
//     ExpansionTile(
//     title: const Text('Region'),
//     children: [
//     Wrap(
//     spacing: 8,
//     runSpacing: 8,
//     children: RegionCityData.regions.map((region) {
//     final isSelected = _selectedRegions.contains(region);
//     return FilterChip(
//     label: Text(region),
//     selected: isSelected,
//     onSelected: (selected) {
//     setState(() {
//     if (selected) {
//     _selectedRegions.add(region);
//     // Clear cities if region changes
//     _selectedCities = _selectedCities.where((city) {
//     return RegionCityData.regionCitiesMap[region]?.contains(city) ?? false;
//     }).toList();
//     } else {
//     _selectedRegions.remove(region);
//     // Remove cities from the deselected region
//     _selectedCities = _selectedCities.where((city) {
//     return !(RegionCityData.regionCitiesMap[region]?.contains(city) ?? false);
//     }).toList();
//     }
//     });
//     },
//     );
//     }).toList(),
//     ),
//     ],
//     ),
//
//     // City Filter
//     if (_selectedRegions.isNotEmpty)
//     ExpansionTile(
//     title: const Text('City'),
//     children: [
//     Wrap(
//     spacing: 8,
//     runSpacing: 8,
//     children: _selectedRegions
//         .expand((region) => RegionCityData.regionCitiesMap[region] ?? [])
//         .toSet()
//         .map((city) {
//     final isSelected = _selectedCities.contains(city);
//     return FilterChip(
//     label: Text(city),
//     selected: isSelected,
//     onSelected: (selected) {
//     setState(() {
//     if (selected) {
//     _selectedCities.add(city);
//     } else {
//     _selectedCities.remove(city);
//     }
//     });
//     },
//     );
//     }).toList(),
//     ),
//     ],
//     ),
//
//     // Job Type Filter
//     ExpansionTile(
//     title: const Text('Job Type'),
//     children: [
//     Wrap(
//     spacing: 8,
//     runSpacing: 8,
//     children: ['Full-time', 'Part-time', 'Contract', 'Internship', 'Temporary'].map((type) {
//     final isSelected = _selectedJobTypes.contains(type);
//     return FilterChip(
//     label: Text(type),
//     selected: isSelected,
//     onSelected: (selected) {
//     setState(() {
//     if (selected) {
//     _selectedJobTypes.add(type);
//     } else {
//     _selectedJobTypes.remove(type);
//     }
//     });
//     },
//     );
//     }).toList(),
//     ),
//     ],
//     ),
//
//     // Experience Level Filter
//     ExpansionTile(
//     title: const Text('Experience Level'),
//     children: [
//     Wrap(
//     spacing: 8,
//     runSpacing: 8,
//     children: ['Entry', 'Mid', 'Senior'].map((level) {
//     final isSelected = _selectedExperienceLevels.contains(level);
//     return FilterChip(
//     label: Text(level),
//     selected: isSelected,
//     onSelected: (selected) {
//     setState(() {
//     if (selected) {
//     _selectedExperienceLevels.add(level);
//     } else {
//     _selectedExperienceLevels.remove(level);
//     }
//     });
//     },
//     );
//     }).toList(),
//     ),
//     ],
//     ),
//
//     // Job Site Filter
//     ExpansionTile(
//     title: const Text('Job Site'),
//     children: [
//     Wrap(
//     spacing: 8,
//     runSpacing: 8,
//     children: ['On-site', 'Remote', 'Hybrid'].map((site) {
//     final isSelected = _selectedJobSites.contains(site);
//     return FilterChip(
//     label: Text(site),
//     selected: isSelected,
//     onSelected: (selected) {
//     setState(() {
//     if (selected) {
//     _selectedJobSites.add(site);
//     } else {
//     _selectedJobSites.remove(site);
//     }
//     });
//     },
//     );
//     }).toList(),
//     ),
//     ],
//     ),
//
//     // Skills Filter
//     ExpansionTile(
//     title: const Text('Skills'),
//     children: [
//     Wrap(
//     spacing: 8,
//     runSpacing: 8,
//     children: SkillsData.allSkills.take(20).map((skill) {
//     final isSelected = _selectedSkills.contains(skill);
//     return FilterChip(
//     label: Text(skill),
//     selected: isSelected,
//     onSelected: (selected) {
//     setState(() {
//     if (selected) {
//     _selectedSkills.add(skill);
//     } else {
//     _selectedSkills.remove(skill);
//     }
//     });
//     },
//     );
//     }).toList(),
//     ),
//     TextButton(
//     onPressed: () {
//     showDialog(
//     context: context,
//     builder: (context) => SkillsSelectionDialog(
//     selectedSkills: _selectedSkills,
//     onSkillsSelected: (skills) {
//     setState(() => _selectedSkills = skills);
//     },
//     ),
//     );
//     },
//     child: const Text('View all skills'),
//     ),
//     ],
//     ),
//
//     // Salary Range Filter
//     ExpansionTile(
//     title: const Text('Salary Range'),
//     children: [
//     RangeSlider(
//     values: _salaryRange,
//     min: 0,
//     max: _maxSalary,
//     divisions: 10,
//     labels: RangeLabels(
//     '\$${_salaryRange.start.round()}',
//     '\$${_salaryRange.end.round()}',
//     ),
//     onChanged: (values) {
//     setState(() => _salaryRange = values);
//     },
//     ),
//     Padding(
//     padding: const EdgeInsets.symmetric(horizontal: 16),
//     child: Row(
//     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//     children: [
//     Text('\$${_salaryRange.start.round()}'),
//     Text('\$${_salaryRange.end.round()}'),
//     ],
//     ),
//     ),
//     ],
//     ),
//
//     // Fields of Study Filter
//     ExpansionTile(
//     title: const Text('Fields of Study'),
//     children: [
//     Wrap(
//     spacing: 8,
//     runSpacing: 8,
//     children: ['Software', 'Computer Science', 'Engineering', 'Business', 'Healthcare'].map((field) {
//     final isSelected = _selectedFieldsOfStudy.contains(field);
//     return FilterChip(
//     label: Text(field),
//     selected: isSelected,
//     onSelected: (selected) {
//     setState(() {
//     if (selected) {
//     _selectedFieldsOfStudy.add(field);
//     } else {
//     _selectedFieldsOfStudy.remove(field);
//     }
//     });
//     },
//     );
//     }).toList(),
//     ),
//     ],
//     ),
//
//     // Education Level Filter
//     ExpansionTile(
//     title: const Text('Education Level'),
//     children: [
//     Wrap(
//     spacing: 8,
//     runSpacing: 8,
//     children: ['High School', 'Bachelor\'s', 'Master\'s', 'PhD'].map((level) {
//     final isSelected = _selectedEducationLevels.contains(level);
//     return FilterChip(
//     label: Text(level),
//     selected: isSelected,
//     onSelected: (selected) {
//     setState(() {
//     if (selected) {
//     _selectedEducationLevels.add(level);
//     } else {
//     _selectedEducationLevels.remove(level);
//     }
//     });
//     },
//     );
//     }).toList(),
//     ),
//     ],
//     ),
//
//     const SizedBox(height: 16),
//     SizedBox(
//     width: double.infinity,
//     child: ElevatedButton(
//     onPressed: _applyFiltersAndClose,
//     child: const Text('Apply Filters'),
//     ),
//     ),
//     ],
//     ),
//     ),
//     );
//   }
// }
//
// class SkillsSelectionDialog extends StatefulWidget {
//   final List<String> selectedSkills;
//   final Function(List<String>) onSkillsSelected;
//
//   const SkillsSelectionDialog({
//     Key? key,
//     required this.selectedSkills,
//     required this.onSkillsSelected,
//   }) : super(key: key);
//
//   @override
//   _SkillsSelectionDialogState createState() => _SkillsSelectionDialogState();
// }
//
// class _SkillsSelectionDialogState extends State<SkillsSelectionDialog> {
//   late List<String> _selectedSkills;
//   final TextEditingController _searchController = TextEditingController();
//   List<String> _filteredSkills = [];
//
//   @override
//   void initState() {
//     super.initState();
//     _selectedSkills = List.from(widget.selectedSkills);
//     _filteredSkills = SkillsData.allSkills;
//     _searchController.addListener(_filterSkills);
//   }
//
//   @override
//   void dispose() {
//     _searchController.dispose();
//     super.dispose();
//   }
//
//   void _filterSkills() {
//     final query = _searchController.text.toLowerCase();
//     setState(() {
//       _filteredSkills = SkillsData.allSkills
//           .where((skill) => skill.toLowerCase().contains(query))
//           .toList();
//     });
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Dialog(
//       insetPadding: const EdgeInsets.all(16),
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           children: [
//             TextField(
//               controller: _searchController,
//               decoration: const InputDecoration(
//                 hintText: 'Search skills...',
//                 prefixIcon: Icon(Icons.search),
//               ),
//             ),
//             const SizedBox(height: 16),
//             Expanded(
//               child: ListView.builder(
//                 itemCount: _filteredSkills.length,
//                 itemBuilder: (context, index) {
//                   final skill = _filteredSkills[index];
//                   final isSelected = _selectedSkills.contains(skill);
//                   return CheckboxListTile(
//                     title: Text(skill),
//                     value: isSelected,
//                     onChanged: (selected) {
//                       setState(() {
//                         if (selected == true) {
//                           _selectedSkills.add(skill);
//                         } else {
//                           _selectedSkills.remove(skill);
//                         }
//                       });
//                     },
//                   );
//                 },
//               ),
//             ),
//             const SizedBox(height: 16),
//             Row(
//               mainAxisAlignment: MainAxisAlignment.end,
//               children: [
//                 TextButton(
//                   onPressed: () => Navigator.pop(context),
//                   child: const Text('Cancel'),
//                 ),
//                 const SizedBox(width: 8),
//                 ElevatedButton(
//                   onPressed: () {
//                     widget.onSkillsSelected(_selectedSkills);
//                     Navigator.pop(context);
//                   },
//                   child: const Text('Apply'),
//                 ),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }