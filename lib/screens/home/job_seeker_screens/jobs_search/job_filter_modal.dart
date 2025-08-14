import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:collection/collection.dart';
import 'JobSearchFilter.dart';
import '../../../../utilities/region_city_data.dart';
import '../../../../utilities/skills_data.dart';

class JobFilterModal extends StatefulWidget {
  final JobFilter initialFilter;
  final ValueChanged<JobFilter> onFiltersChanged;

  const JobFilterModal({
    Key? key,
    required this.initialFilter,
    required this.onFiltersChanged,
  }) : super(key: key);

  @override
  _JobFilterModalState createState() => _JobFilterModalState();
}

class _JobFilterModalState extends State<JobFilterModal> with SingleTickerProviderStateMixin {
  late JobFilter _currentFilter;
  late TabController _tabController;
  final _searchController = TextEditingController();
  List<String> _filteredSkills = [];
  bool _isSearchingSkills = false;

  final List<String> _salaryRanges = [
    'Any',
    'Under \$500',
    '\$500 - \$1,000',
    '\$1,000 - \$2,000',
    '\$2,000 - \$5,000',
    'Over \$5,000'
  ];

  final List<String> _postedTimes = [
    'Any time',
    'Last 24 hours',
    'Last 3 days',
    'Last week',
    'Last month'
  ];

  String _selectedPostedTime = 'Any time';

  @override
  void initState() {
    super.initState();
    _currentFilter = widget.initialFilter;
    _tabController = TabController(length: 3, vsync: this);
    _filteredSkills = SkillsData.allSkills;

    // Set initial posted time selection
    if (_currentFilter.postedAfter != null) {
      final now = DateTime.now();
      final difference = now.difference(_currentFilter.postedAfter!);

      if (difference.inHours <= 24) {
        _selectedPostedTime = 'Last 24 hours';
      } else if (difference.inDays <= 3) {
        _selectedPostedTime = 'Last 3 days';
      } else if (difference.inDays <= 7) {
        _selectedPostedTime = 'Last week';
      } else if (difference.inDays <= 30) {
        _selectedPostedTime = 'Last month';
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _applyFilters() {
    widget.onFiltersChanged(_currentFilter);
    Navigator.pop(context);
  }

  void _resetFilters() {
    setState(() {
      _currentFilter = JobFilter();
      _selectedPostedTime = 'Any time';
    });
    widget.onFiltersChanged(_currentFilter);
  }

  void _onSkillSearchChanged(String query) {
    setState(() {
      _isSearchingSkills = query.isNotEmpty;
      _filteredSkills = SkillsData.allSkills
          .where((skill) => skill.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AnimatedPadding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      duration: const Duration(milliseconds: 100),
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header with title and close button
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Filter Jobs',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: _resetFilters,
                      child: const Text('Reset'),
                    ),
                  ],
                ),
              ),

              // Tab bar for different filter categories
              TabBar(
                controller: _tabController,
                labelColor: colorScheme.primary,
                unselectedLabelColor: colorScheme.onSurface.withOpacity(0.6),
                indicatorColor: colorScheme.primary,
                tabs: const [
                  Tab(text: 'Location'),
                  Tab(text: 'Job Details'),
                  Tab(text: 'Skills'),
                ],
              ),

              // Tab content
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // Location Tab
                    _buildLocationTab(theme),

                    // Job Details Tab
                    _buildJobDetailsTab(theme),

                    // Skills Tab
                    _buildSkillsTab(theme),
                  ],
                ),
              ),

              // Apply button
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: ElevatedButton(
                  onPressed: _applyFilters,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Apply Filters'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLocationTab(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Region Filter
          _buildFilterSection(
            title: 'Region',
            options: RegionCityData.regions,
            selectedOptions: _currentFilter.regions ?? [],
            onSelectionChanged: (selected) {
              setState(() {
                _currentFilter = _currentFilter.copyWith(regions: selected);
                // Clear cities when regions change
                if (selected.isEmpty || _currentFilter.cities == null) {
                  _currentFilter = _currentFilter.copyWith(cities: null);
                } else {
                  // Filter cities to only those in selected regions
                  final validCities = _currentFilter.cities!
                      .where((city) => selected.any((region) =>
                  RegionCityData.regionCitiesMap[region]?.contains(city) ?? false))
                      .toList();
                  if (validCities.isEmpty) {
                    _currentFilter = _currentFilter.copyWith(cities: null);
                  }
                }
              });
            },
          ),

          // City Filter
          if (_currentFilter.regions != null && _currentFilter.regions!.isNotEmpty)
            _buildFilterSection(
              title: 'City',
              options: _currentFilter.regions!
                  .expand((region) => RegionCityData.regionCitiesMap[region] ?? [])
                  .cast<String>()
                  .toSet()
                  .toList(),
              selectedOptions: _currentFilter.cities ?? [],
              onSelectionChanged: (selected) {
                setState(() {
                  _currentFilter = _currentFilter.copyWith(cities: selected);
                });
              },
            ),
        ],
      ),
    );
  }

  Widget _buildJobDetailsTab(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Job Type Filter
          _buildFilterSection(
            title: 'Job Type',
            options: const [
              'Full-time',
              'Part-time',
              'Contract',
              'Internship',
              'Temporary',
              'Freelance'
            ],
            selectedOptions: _currentFilter.jobTypes ?? [],
            onSelectionChanged: (selected) {
              setState(() {
                _currentFilter = _currentFilter.copyWith(jobTypes: selected);
              });
            },
          ),

          // Experience Level Filter
          _buildFilterSection(
            title: 'Experience Level',
            options: const ['Entry', 'Mid', 'Senior'],
            selectedOptions: _currentFilter.experienceLevels ?? [],
            onSelectionChanged: (selected) {
              setState(() {
                _currentFilter = _currentFilter.copyWith(experienceLevels: selected);
              });
            },
          ),

          // Job Site Filter
          _buildFilterSection(
            title: 'Job Site',
            options: const ['On-site', 'Remote', 'Hybrid'],
            selectedOptions: _currentFilter.jobSites ?? [],
            onSelectionChanged: (selected) {
              setState(() {
                _currentFilter = _currentFilter.copyWith(jobSites: selected);
              });
            },
          ),

          // Salary Range
          _buildSingleSelectSection(
            title: 'Salary Range',
            options: _salaryRanges,
            selectedOption: _currentFilter.salaryRange ?? 'Any',
            onSelectionChanged: (selected) {
              setState(() {
                _currentFilter = _currentFilter.copyWith(
                  salaryRange: selected == 'Any' ? null : selected,
                );
              });
            },
          ),

          // Posted Time
          _buildSingleSelectSection(
            title: 'Posted Time',
            options: _postedTimes,
            selectedOption: _selectedPostedTime,
            onSelectionChanged: (selected) {
              setState(() {
                _selectedPostedTime = selected;
                DateTime? postedAfter;

                final now = DateTime.now();
                switch (selected) {
                  case 'Last 24 hours':
                    postedAfter = now.subtract(const Duration(hours: 24));
                    break;
                  case 'Last 3 days':
                    postedAfter = now.subtract(const Duration(days: 3));
                    break;
                  case 'Last week':
                    postedAfter = now.subtract(const Duration(days: 7));
                    break;
                  case 'Last month':
                    postedAfter = now.subtract(const Duration(days: 30));
                    break;
                  default:
                    postedAfter = null;
                }

                _currentFilter = _currentFilter.copyWith(postedAfter: postedAfter);
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSkillsTab(ThemeData theme) {
    return Column(
      children: [
        // Search bar for skills
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search skills...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _isSearchingSkills
                  ? IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  _searchController.clear();
                  _onSkillSearchChanged('');
                },
              )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onChanged: _onSkillSearchChanged,
          ),
        ),

        // Selected skills chips
        if (_currentFilter.requiredSkills?.isNotEmpty ?? false)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _currentFilter.requiredSkills!.map((skill) {
                return InputChip(
                  label: Text(skill),
                  onDeleted: () {
                    setState(() {
                      _currentFilter = _currentFilter.copyWith(
                        requiredSkills: _currentFilter.requiredSkills!
                            .where((s) => s != skill)
                            .toList(),
                      );
                    });
                  },
                );
              }).toList(),
            ),
          ),

        // Skills list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _filteredSkills.length,
            itemBuilder: (context, index) {
              final skill = _filteredSkills[index];
              final isSelected = _currentFilter.requiredSkills?.contains(skill) ?? false;

              return ListTile(
                title: Text(skill),
                trailing: isSelected
                    ? const Icon(Icons.check_circle, color: Colors.green)
                    : null,
                onTap: () {
                  setState(() {
                    final currentSkills = _currentFilter.requiredSkills ?? [];
                    if (isSelected) {
                      _currentFilter = _currentFilter.copyWith(
                        requiredSkills: currentSkills.where((s) => s != skill).toList(),
                      );
                    } else {
                      _currentFilter = _currentFilter.copyWith(
                        requiredSkills: [...currentSkills, skill],
                      );
                    }
                  });
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFilterSection({
    required String title,
    required List<String> options,
    required List<String> selectedOptions,
    required Function(List<String>) onSelectionChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options.map((option) {
            final isSelected = selectedOptions.contains(option);
            return FilterChip(
              label: Text(option),
              selected: isSelected,
              onSelected: (selected) {
                final newSelection = List<String>.from(selectedOptions);
                if (selected) {
                  newSelection.add(option);
                } else {
                  newSelection.remove(option);
                }
                onSelectionChanged(newSelection);
              },
              selectedColor: Theme.of(context).primaryColor.withOpacity(0.2),
              checkmarkColor: Theme.of(context).primaryColor,
              labelStyle: TextStyle(
                color: isSelected ? Theme.of(context).primaryColor : Colors.black,
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildSingleSelectSection({
    required String title,
    required List<String> options,
    required String selectedOption,
    required Function(String) onSelectionChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options.map((option) {
            final isSelected = selectedOption == option;
            return ChoiceChip(
              label: Text(option),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  onSelectionChanged(option);
                }
              },
              selectedColor: Theme.of(context).primaryColor.withOpacity(0.2),
              labelStyle: TextStyle(
                color: isSelected ? Theme.of(context).primaryColor : Colors.black,
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}