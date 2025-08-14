import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

@immutable
class JobFilter {
  final List<String>? regions;
  final List<String>? cities;
  final List<String>? jobTypes;
  final List<String>? experienceLevels;
  final List<String>? jobSites;
  final List<String>? requiredSkills;
  final List<String>? fieldsOfStudy;
  final List<String>? jobCategories;
  final List<String>? educationLevels;
  final List<String>? languages;
  final String? salaryRange;
  final DateTime? postedAfter;
  final String? searchQuery;

  const JobFilter({
    this.regions,
    this.cities,
    this.jobTypes,
    this.experienceLevels,
    this.jobSites,
    this.requiredSkills,
    this.fieldsOfStudy,
    this.jobCategories,
    this.educationLevels,
    this.languages,
    this.salaryRange,
    this.postedAfter,
    this.searchQuery,
  });

  Map<String, dynamic> toMap() {
    return {
      if (regions != null) 'regions': regions,
      if (cities != null) 'cities': cities,
      if (jobTypes != null) 'jobTypes': jobTypes,
      if (experienceLevels != null) 'experienceLevels': experienceLevels,
      if (jobSites != null) 'jobSites': jobSites,
      if (requiredSkills != null) 'requiredSkills': requiredSkills,
      if (fieldsOfStudy != null) 'fieldsOfStudy': fieldsOfStudy,
      if (jobCategories != null) 'jobCategories': jobCategories,
      if (educationLevels != null) 'educationLevels': educationLevels,
      if (languages != null) 'languages': languages,
      if (salaryRange != null) 'salaryRange': salaryRange,
      if (postedAfter != null) 'postedAfter': Timestamp.fromDate(postedAfter!),
      if (searchQuery != null) 'searchQuery': searchQuery,
    };
  }

  JobFilter copyWith({
    List<String>? regions,
    List<String>? cities,
    List<String>? jobTypes,
    List<String>? experienceLevels,
    List<String>? jobSites,
    List<String>? requiredSkills,
    List<String>? fieldsOfStudy,
    List<String>? jobCategories,
    List<String>? educationLevels,
    List<String>? languages,
    String? salaryRange,
    DateTime? postedAfter,
    String? searchQuery,
  }) {
    return JobFilter(
      regions: regions ?? this.regions,
      cities: cities ?? this.cities,
      jobTypes: jobTypes ?? this.jobTypes,
      experienceLevels: experienceLevels ?? this.experienceLevels,
      jobSites: jobSites ?? this.jobSites,
      requiredSkills: requiredSkills ?? this.requiredSkills,
      fieldsOfStudy: fieldsOfStudy ?? this.fieldsOfStudy,
      jobCategories: jobCategories ?? this.jobCategories,
      educationLevels: educationLevels ?? this.educationLevels,
      languages: languages ?? this.languages,
      salaryRange: salaryRange ?? this.salaryRange,
      postedAfter: postedAfter ?? this.postedAfter,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  bool get hasFilters {
    return regions?.isNotEmpty == true ||
        cities?.isNotEmpty == true ||
        jobTypes?.isNotEmpty == true ||
        experienceLevels?.isNotEmpty == true ||
        jobSites?.isNotEmpty == true ||
        requiredSkills?.isNotEmpty == true ||
        fieldsOfStudy?.isNotEmpty == true ||
        jobCategories?.isNotEmpty == true ||
        educationLevels?.isNotEmpty == true ||
        languages?.isNotEmpty == true ||
        salaryRange != null ||
        postedAfter != null ||
        (searchQuery?.isNotEmpty ?? false);
  }

  static JobFilter fromMap(Map<String, dynamic> map) {
    return JobFilter(
      regions: map['regions'] != null ? List<String>.from(map['regions']) : null,
      cities: map['cities'] != null ? List<String>.from(map['cities']) : null,
      jobTypes: map['jobTypes'] != null ? List<String>.from(map['jobTypes']) : null,
      experienceLevels: map['experienceLevels'] != null ? List<String>.from(map['experienceLevels']) : null,
      jobSites: map['jobSites'] != null ? List<String>.from(map['jobSites']) : null,
      requiredSkills: map['requiredSkills'] != null ? List<String>.from(map['requiredSkills']) : null,
      fieldsOfStudy: map['fieldsOfStudy'] != null ? List<String>.from(map['fieldsOfStudy']) : null,
      jobCategories: map['jobCategories'] != null ? List<String>.from(map['jobCategories']) : null,
      educationLevels: map['educationLevels'] != null ? List<String>.from(map['educationLevels']) : null,
      languages: map['languages'] != null ? List<String>.from(map['languages']) : null,
      salaryRange: map['salaryRange'],
      postedAfter: (map['postedAfter'] as Timestamp?)?.toDate(),
      searchQuery: map['searchQuery'],
    );
  }
}