class FieldsOfStudyData {
  // Main categories
  static final List<String> categories = [
    'Engineering & Technology',
    'Business & Economics',
    'Health Sciences',
    'Natural Sciences',
    'Agriculture',
    'Social Sciences & Humanities',
    'Emerging Fields',
    'Digital & Creative Arts'
  ];

  // All fields grouped by category
  static final Map<String, List<String>> fieldsByCategory = {
    'Engineering & Technology': [
      'Computer Science',
      'Software Engineering',
      'Information Technology',
      'Electrical Engineering',
      'Mechanical Engineering',
      'Civil Engineering',
      'Chemical Engineering',
      'Industrial Engineering',
      'Biomedical Engineering',
      'Architecture',
      'Telecommunications Engineering'
    ],
    'Business & Economics': [
      'Business Administration',
      'Accounting',
      'Finance',
      'Economics',
      'Management',
      'Marketing',
      'Hotel and Tourism Management',
      'Logistics and Supply Chain Management',
      'Entrepreneurship',
      'E-Commerce'
    ],
    'Health Sciences': [
      'Medicine',
      'Pharmacy',
      'Nursing',
      'Midwifery',
      'Public Health',
      'Medical Laboratory Science',
      'Dentistry',
      'Anesthesia',
      'Traditional Ethiopian Medicine'
    ],
    'Natural Sciences': [
      'Mathematics',
      'Physics',
      'Chemistry',
      'Biology',
      'Statistics',
      'Geology',
      'Environmental Science',
      'Meteorology'
    ],
    'Agriculture': [
      'Agriculture',
      'Animal Science',
      'Plant Science',
      'Horticulture',
      'Veterinary Medicine',
      'Food Science',
      'Agro-processing',
      'Agribusiness Management'
    ],
    'Social Sciences & Humanities': [
      'Law',
      'Political Science',
      'Sociology',
      'Psychology',
      'History',
      'Geography',
      'Journalism',
      'English Literature',
      'Amharic Literature',
      'Ethiopian Languages',
      'International Relations',
      'Social Work',
      'Cultural Studies',
      'Ethnic Studies'
    ],
    'Emerging Fields': [
      'Data Science',
      'Artificial Intelligence',
      'Cybersecurity',
      'Renewable Energy Engineering',
      'Biotechnology',
      'Blockchain & Fintech',
      'Space Science & Technology'
    ],
    'Digital & Creative Arts': [
      'Graphic Design',
      'UI/UX Design',
      'Video Editing',
      'Animation',
      'Digital Marketing',
      'Content Creation',
      'Photography',
      'Music Production',
      'Game Development'
    ],
  };

  // Get all fields as a single list
  static List<String> get allFields {
    return fieldsByCategory.values.expand((fields) => fields).toList();
  }
}
