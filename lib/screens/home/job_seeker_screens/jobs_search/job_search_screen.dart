import 'dart:async';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:debounce_throttle/debounce_throttle.dart';
import '../../../../models/employer_model/employer_model.dart';
import '../../../../models/job_model.dart';
import 'JobSearchFilter.dart';
import 'job_card.dart';
import 'job_filter_modal.dart';
import '../../../../utilities/skills_data.dart';

class JobSearchScreen extends StatefulWidget {
  const JobSearchScreen({Key? key}) : super(key: key);

  @override
  _JobSearchScreenState createState() => _JobSearchScreenState();
}

class _JobSearchScreenState extends State<JobSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final Debouncer<String> _searchDebouncer = Debouncer<String>(
    const Duration(milliseconds: 500),
    initialValue: '',
  );
  JobFilter _currentFilter = JobFilter();
  List<JobModel> _jobs = [];
  List<Employer> _employers = [];
  bool _isLoading = false;
  bool _showSearchSuggestions = false;
  List<String> _searchSuggestions = [];
  late final StreamSubscription<String> _debounceSubscription;


  @override
  void initState() {
    super.initState();
    _loadJobs();
    _searchController.addListener(_onSearchChanged);
    _loadSearchSuggestions();
    _debounceSubscription = _searchDebouncer.values.listen((query) {
      setState(() {
        _currentFilter = _currentFilter.copyWith(searchQuery: query);
        _showSearchSuggestions = false;
      });
      _loadJobs();
    });

  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _debounceSubscription.cancel();
    super.dispose();
  }

  Future<void> _loadSearchSuggestions() async {
    // In a real app, you might get these from Firestore or other database
    final jobTitles = _jobs.map((job) => job.title).toSet().toList();
    final skills = SkillsData.allSkills;
    setState(() {
      _searchSuggestions = [...jobTitles, ...skills];
    });
  }

  void _onSearchChanged() {
    if (_searchController.text.isEmpty) {
      setState(() {
        _showSearchSuggestions = false;
        _currentFilter = _currentFilter.copyWith(searchQuery: null);
      });
      _loadJobs();
      return;
    }

    setState(() {
      _showSearchSuggestions = true;
    });

    _searchDebouncer.value = _searchController.text;
  }

  Future<void> _loadJobs() async {
    setState(() => _isLoading = true);

    try {
      Query query = FirebaseFirestore.instance.collection('jobs')
          .where('approvalStatus', isEqualTo: 'Approved')
          .where('postStatus', isEqualTo: 'Posted')
          .orderBy('datePosted', descending: true);

      // Apply search query if exists
      if (_currentFilter.searchQuery?.isNotEmpty ?? false) {
        final searchQuery = _currentFilter.searchQuery!.toLowerCase();
        final jobsSnapshot = await FirebaseFirestore.instance.collection('jobs').get();
        final allJobs = jobsSnapshot.docs
            .map((doc) => JobModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
            .where((job) => job.approvalStatus == 'Approved' && job.postStatus == 'Posted')
            .toList();

        // Filter locally for better search experience
        final filteredJobs = allJobs.where((job) {
          return job.title.toLowerCase().contains(searchQuery) ||
              job.description.toLowerCase().contains(searchQuery) ||
              job.requiredSkills.any((skill) => skill.toLowerCase().contains(searchQuery));
        }).toList();

        // Load employers for these jobs
        final employerIds = filteredJobs.map((job) => job.employerId).toSet().toList();
        final employersSnapshot = await FirebaseFirestore.instance
            .collection('employers')
            .where('userId', whereIn: employerIds.isEmpty ? [''] : employerIds)
            .get();

        final employers = employersSnapshot.docs
            .map((doc) => Employer.fromMap(doc.data()))
            .toList();

        setState(() {
          _jobs = filteredJobs;
          _employers = employers;
          _isLoading = false;
        });
        return;
      }

      // Apply filters
      if (_currentFilter.regions != null && _currentFilter.regions!.isNotEmpty) {
        query = query.where('region', whereIn: _currentFilter.regions);
      }
      if (_currentFilter.cities != null && _currentFilter.cities!.isNotEmpty) {
        query = query.where('city', whereIn: _currentFilter.cities);
      }
      if (_currentFilter.jobTypes != null && _currentFilter.jobTypes!.isNotEmpty) {
        query = query.where('jobType', whereIn: _currentFilter.jobTypes);
      }
      if (_currentFilter.experienceLevels != null && _currentFilter.experienceLevels!.isNotEmpty) {
        query = query.where('experienceLevel', whereIn: _currentFilter.experienceLevels);
      }
      if (_currentFilter.jobSites != null && _currentFilter.jobSites!.isNotEmpty) {
        query = query.where('jobSite', whereIn: _currentFilter.jobSites);
      }
      if (_currentFilter.requiredSkills != null && _currentFilter.requiredSkills!.isNotEmpty) {
        query = query.where('requiredSkills', arrayContainsAny: _currentFilter.requiredSkills);
      }
      if (_currentFilter.postedAfter != null) {
        query = query.where('datePosted', isGreaterThanOrEqualTo: Timestamp.fromDate(_currentFilter.postedAfter!));
      }

      final jobsSnapshot = await query.get();
      final jobs = jobsSnapshot.docs
          .map((doc) => JobModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();

      // Load employers for these jobs
      final employerIds = jobs.map((job) => job.employerId).toSet().toList();
      final employersSnapshot = await FirebaseFirestore.instance
          .collection('employers')
          .where('userId', whereIn: employerIds.isEmpty ? [''] : employerIds)
          .get();

      final employers = employersSnapshot.docs
          .map((doc) => Employer.fromMap(doc.data()))
          .toList();

      setState(() {
        _jobs = jobs;
        _employers = employers;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading jobs: ${e.toString()}')),
      );
    }
  }

  Employer? _getEmployerForJob(String employerId) {
    try {
      return _employers.firstWhere((employer) => employer.userId == employerId);
    } catch (e) {
      return null;
    }
  }

  void _showFilterModal() async {
    final updatedFilter = await showModalBottomSheet<JobFilter>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => JobFilterModal(
        initialFilter: _currentFilter,
        onFiltersChanged: (filter) {
          setState(() => _currentFilter = filter);
          _loadJobs();
        },
      ),
    );

    if (updatedFilter != null) {
      setState(() => _currentFilter = updatedFilter);
      _loadJobs();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Find Jobs'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_alt),
            onPressed: _showFilterModal,
            tooltip: 'Filters',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Stack(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search jobs...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          _showSearchSuggestions = false;
                          _currentFilter = _currentFilter.copyWith(searchQuery: null);
                        });
                        _loadJobs();
                      },
                    )
                        : null,
                  ),
                  onTap: () {
                    if (_searchController.text.isNotEmpty) {
                      setState(() => _showSearchSuggestions = true);
                    }
                  },
                ),

                // Search suggestions
                if (_showSearchSuggestions && _searchSuggestions.isNotEmpty)
                  Positioned(
                    top: 60,
                    left: 0,
                    right: 0,
                    child: Material(
                      elevation: 4,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        constraints: const BoxConstraints(maxHeight: 200),
                        decoration: BoxDecoration(
                          color: colorScheme.surface,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListView.builder(
                          padding: EdgeInsets.zero,
                          shrinkWrap: true,
                          itemCount: _searchSuggestions.length,
                          itemBuilder: (context, index) {
                            final suggestion = _searchSuggestions[index];
                            return ListTile(
                              title: Text(suggestion),
                              onTap: () {
                                _searchController.text = suggestion;
                                setState(() {
                                  _showSearchSuggestions = false;
                                  _currentFilter = _currentFilter.copyWith(searchQuery: suggestion);
                                });
                                _loadJobs();
                              },
                            );
                          },
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Active filters chips
          _buildActiveFiltersChips(),

          // Loading indicator or job list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _jobs.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.work_outline,
                    size: 64,
                    color: colorScheme.onSurface.withOpacity(0.3),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No jobs found',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: colorScheme.onSurface.withOpacity(0.5),
                    ),
                  ),
                  if (_currentFilter.hasFilters)
                    TextButton(
                      onPressed: _clearAllFilters,
                      child: const Text('Clear all filters'),
                    ),
                ],
              ),
            )
                : ListView.builder(
              itemCount: _jobs.length,
              itemBuilder: (context, index) {
                final job = _jobs[index];
                final employer = _getEmployerForJob(job.employerId);
                return employer != null
                    ? JobCard(job: job, employer: employer)
                    : const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveFiltersChips() {
    final activeFilters = <Widget>[];

    void addFilterChip(String label, VoidCallback onDeleted) {
      activeFilters.add(
        Chip(
          label: Text(label),
          onDeleted: onDeleted,
          backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
          deleteIconColor: Theme.of(context).primaryColor,
        ),
      );
    }

    if (_currentFilter.regions != null && _currentFilter.regions!.isNotEmpty) {
      addFilterChip(
        'Regions: ${_currentFilter.regions!.join(', ')}',
            () {
          setState(() => _currentFilter = _currentFilter.copyWith(regions: null));
          _loadJobs();
        },
      );
    }

    if (_currentFilter.cities != null && _currentFilter.cities!.isNotEmpty) {
      addFilterChip(
        'Cities: ${_currentFilter.cities!.join(', ')}',
            () {
          setState(() => _currentFilter = _currentFilter.copyWith(cities: null));
          _loadJobs();
        },
      );
    }

    if (_currentFilter.jobTypes != null && _currentFilter.jobTypes!.isNotEmpty) {
      addFilterChip(
        'Types: ${_currentFilter.jobTypes!.join(', ')}',
            () {
          setState(() => _currentFilter = _currentFilter.copyWith(jobTypes: null));
          _loadJobs();
        },
      );
    }

    if (_currentFilter.experienceLevels != null && _currentFilter.experienceLevels!.isNotEmpty) {
      addFilterChip(
        'Experience: ${_currentFilter.experienceLevels!.join(', ')}',
            () {
          setState(() => _currentFilter = _currentFilter.copyWith(experienceLevels: null));
          _loadJobs();
        },
      );
    }

    if (_currentFilter.jobSites != null && _currentFilter.jobSites!.isNotEmpty) {
      addFilterChip(
        'Job Sites: ${_currentFilter.jobSites!.join(', ')}',
            () {
          setState(() => _currentFilter = _currentFilter.copyWith(jobSites: null));
          _loadJobs();
        },
      );
    }

    if (_currentFilter.requiredSkills != null && _currentFilter.requiredSkills!.isNotEmpty) {
      addFilterChip(
        'Skills: ${_currentFilter.requiredSkills!.join(', ')}',
            () {
          setState(() => _currentFilter = _currentFilter.copyWith(requiredSkills: null));
          _loadJobs();
        },
      );
    }

    if (_currentFilter.postedAfter != null) {
      addFilterChip(
        'Posted after: ${DateFormat('MMM d, y').format(_currentFilter.postedAfter!)}',
            () {
          setState(() => _currentFilter = _currentFilter.copyWith(postedAfter: null));
          _loadJobs();
        },
      );
    }

    if (_currentFilter.salaryRange != null) {
      addFilterChip(
        'Salary: ${_currentFilter.salaryRange}',
            () {
          setState(() => _currentFilter = _currentFilter.copyWith(salaryRange: null));
          _loadJobs();
        },
      );
    }

    if (_currentFilter.searchQuery != null) {
      addFilterChip(
        'Search: ${_currentFilter.searchQuery}',
            () {
          _searchController.clear();
          setState(() {
            _currentFilter = _currentFilter.copyWith(searchQuery: null);
            _showSearchSuggestions = false;
          });
          _loadJobs();
        },
      );
    }

    return activeFilters.isNotEmpty
        ? Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: activeFilters,
        ),
      ),
    )
        : const SizedBox.shrink();
  }

  void _clearAllFilters() {
    _searchController.clear();
    setState(() {
      _currentFilter = JobFilter();
      _showSearchSuggestions = false;
    });
    _loadJobs();
  }
}