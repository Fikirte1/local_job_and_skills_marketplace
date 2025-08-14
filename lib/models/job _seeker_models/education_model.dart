class Education {
  final String id; // Unique identifier
  final String institution; // Institution name
  final String fieldOfStudy;
  final String degree;
  final String educationType; // 'High School', 'College', or 'University'
  final DateTime startDate;
  final DateTime? endDate; // Null means currently studying
  final bool isCurrent;

  Education({
    String? id,
    required this.institution,
    required this.fieldOfStudy,
    required this.degree,
    required this.educationType,
    required this.startDate,
    this.endDate,
    this.isCurrent = false,
  }) : id = id ?? DateTime.now().millisecondsSinceEpoch.toString() {
    if (!isCurrent && endDate == null) {
      throw ArgumentError('End date must be provided if not current education');
    }
    if (endDate != null && endDate!.isBefore(startDate)) {
      throw ArgumentError('End date cannot be before start date');
    }
    if (!['High School', 'College', 'University'].contains(educationType)) {
      throw ArgumentError('Invalid education type');
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'institution': institution,
      'fieldOfStudy': fieldOfStudy,
      'degree': degree,
      'educationType': educationType,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'isCurrent': isCurrent,
    };
  }

  factory Education.fromMap(Map<String, dynamic> map) {
    return Education(
      id: map['id'] ?? '',
      institution: map['institution'] ?? '',
      fieldOfStudy: map['fieldOfStudy'] ?? '',
      degree: map['degree'] ?? '',
      educationType: map['educationType'] ?? '',
      startDate: map['startDate'] != null ? DateTime.parse(map['startDate']) : DateTime(2000),
      endDate: map['endDate'] != null ? DateTime.parse(map['endDate']) : null,
      isCurrent: map['isCurrent'] ?? false,
    );
  }


  Education copyWith({
    String? institution,
    String? fieldOfStudy,
    String? degree,
    String? educationType,
    DateTime? startDate,
    DateTime? endDate,
    bool? isCurrent,
  }) {
    return Education(
      id: id,
      institution: institution ?? this.institution,
      fieldOfStudy: fieldOfStudy ?? this.fieldOfStudy,
      degree: degree ?? this.degree,
      educationType: educationType ?? this.educationType,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      isCurrent: isCurrent ?? this.isCurrent,
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

  // Helper method to get education level description
  String get educationLevel {
    switch (educationType) {
      case 'High School':
        return 'High School ($degree)';
      case 'College':
        return 'College: $degree in $fieldOfStudy';
      case 'University':
        return 'University: $degree in $fieldOfStudy';
      default:
        return degree;
    }
  }
}