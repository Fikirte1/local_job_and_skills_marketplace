class WorkExperience {
  final String id;
  final String positionTitle;
  final String company;
  final String? description;
  final DateTime startDate;
  final DateTime? endDate;
  final bool isCurrent;
  final bool isSelfEmployed;
  final String? jobSite; // 'On-site', 'Remote', 'Hybrid'
  final String? employmentType; // 'Full-time', 'Part-time', 'Contract', etc.

  WorkExperience({
    String? id,
    required this.positionTitle,
    required this.company,
    this.description,
    required this.startDate,
    this.endDate,
    this.isCurrent = false,
    this.isSelfEmployed = false,
    this.jobSite,
    this.employmentType,
  }) : id = id ?? DateTime.now().millisecondsSinceEpoch.toString() {
    if (!isCurrent && endDate == null) {
      throw ArgumentError('End date must be provided if not current position');
    }
    if (endDate != null && endDate!.isBefore(startDate)) {
      throw ArgumentError('End date cannot be before start date');
    }
    if (!isSelfEmployed) {
      if (jobSite == null || employmentType == null) {
        throw ArgumentError('Job site and employment type are required for non-self-employed positions');
      }
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'positionTitle': positionTitle,
      'company': company,
      'description': description,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'isCurrent': isCurrent,
      'isSelfEmployed': isSelfEmployed,
      'jobSite': jobSite,
      'employmentType': employmentType,
    };
  }

  factory WorkExperience.fromMap(Map<String, dynamic> map) {
    return WorkExperience(
      id: map['id'],
      positionTitle: map['positionTitle'],
      company: map['company'],
      description: map['description'],
      startDate: DateTime.parse(map['startDate']),
      endDate: map['endDate'] != null ? DateTime.parse(map['endDate']) : null,
      isCurrent: map['isCurrent'] ?? false,
      isSelfEmployed: map['isSelfEmployed'] ?? false,
      jobSite: map['jobSite'],
      employmentType: map['employmentType'],
    );
  }

  WorkExperience copyWith({
    String? positionTitle,
    String? company,
    String? description,
    DateTime? startDate,
    DateTime? endDate,
    bool? isCurrent,
    bool? isSelfEmployed,
    String? jobSite,
    String? employmentType,
  }) {
    return WorkExperience(
      id: id,
      positionTitle: positionTitle ?? this.positionTitle,
      company: company ?? this.company,
      description: description ?? this.description,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      isCurrent: isCurrent ?? this.isCurrent,
      isSelfEmployed: isSelfEmployed ?? this.isSelfEmployed,
      jobSite: jobSite ?? this.jobSite,
      employmentType: employmentType ?? this.employmentType,
    );
  }

  String get durationText {
    final start = '${_monthYearFormat(startDate)}';
    final end = isCurrent ? 'Present' : '${_monthYearFormat(endDate!)}';
    return '$start - $end';
  }

  String _monthYearFormat(DateTime date) {
    return '${_getMonthName(date.month)} ${date.year}';
  }

  String _getMonthName(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[month - 1];
  }

  String get employmentDetails {
    if (isSelfEmployed) return 'Self-employed';
    return '${employmentType ?? ''}${employmentType != null && jobSite != null ? ' • ' : ''}${jobSite ?? ''}';
  }
}