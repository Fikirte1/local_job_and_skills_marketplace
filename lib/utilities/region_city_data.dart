class RegionCityData {
  static final List<String> regions = [
    'Addis Ababa',
    'Afar',
    'Amhara',
    'Benishangul-Gumuz',
    'Dire Dawa',
    'Gambela',
    'Harari',
    'Oromia',
    'Sidama',
    'Somali',
    'South West Ethiopia Peoples\' Region',
    'SNNPR',
    'Tigray'
  ];

  static final Map<String, List<String>> regionCitiesMap = {
    'Addis Ababa': [
      'Addis Ababa'
    ],
    'Afar': [
      'Semera',
      'Asaita',
      'Awash',
      'Gewane',
      'Logiya',
      'Dubti',
      'Chifra',
      'Mille',
      'Bati'
    ],
    'Amhara': [
      'Bahir Dar',
      'Gondar',
      'Dessie',
      'Debre Markos',
      'Woldia',
      'Debre Birhan',
      'Kombolcha',
      'Debre Tabor',
      'Kobo',
      'Finote Selam'
    ],
    'Benishangul-Gumuz': [
      'Asosa',
      'Bambasi',
      'Menge',
      'Kurmuk',
      'Sherkole',
      'Gilgil Beles'
    ],
    'Dire Dawa': [
      'Dire Dawa'
    ],
    'Gambela': [
      'Gambela',
      'Agnwa',
      'Itang',
      'Gog',
      'Abobo',
      'Tergol'
    ],
    'Harari': [
      'Harar',
      'Hirna',
      'Alemaya',
      'Kombolcha'
    ],
    'Oromia': [
      'Adama',
      'Jimma',
      'Bishoftu',
      'Ambo',
      'Nekemte',
      'Shashamane',
      'Robe',
      'Bale',
      'Asella',
      'Dembi Dolo',
      'Gimbi',
      'Adaba',
      'Mettu'
    ],
    'Sidama': [
      'Hawassa',
      'Yirgalem',
      'Dilla',
      'Aleta Wondo',
      'Wendo Genet',
      'Hula'
    ],
    'Somali': [
      'Jijiga',
      'Degehabur',
      'Kebri Dahar',
      'Gode',
      'Shilavo',
      'Dollo',
      'Kebri Beyah',
      'Werder'
    ],
    'South West Ethiopia Peoples\' Region': [
      'Bonga',
      'Mizan Teferi',
      'Tepi',
      'Tercha',
      'Maji'
    ],
    'SNNPR': [
      'Arba Minch',
      'Wolaita Sodo',
      'Jinka',
      'Sodo',
      'Butajira',
      'Hossana',
      'Wolkite',
      'Boditi'
    ],
    'Tigray': [
      'Mekelle',
      'Adigrat',
      'Axum',
      'Shire',
      'Humera',
      'Adwa',
      'Alamata',
      'Maychew',
      'Abi Adi'
    ]
  };

  static final List<String> professional_title = [
    // Technology & IT
    'Software Developer',
    'Web Developer',
    'Mobile App Developer',
    'IT Support Specialist',
    'Network Administrator',
    'Database Administrator',
    'Systems Analyst',
    'Cybersecurity Specialist',
    'Graphics Designer',
    'UI/UX Designer',

    // Healthcare
    'Doctor',
    'Nurse',
    'Pharmacist',
    'Dentist',
    'Medical Laboratory Technician',
    'Radiologist',
    'Physiotherapist',
    'Health Officer',
    'Midwife',

    // Engineering
    'Civil Engineer',
    'Mechanical Engineer',
    'Electrical Engineer',
    'Software Engineer',
    'Chemical Engineer',
    'Industrial Engineer',
    'Agricultural Engineer',
    'Water Resource Engineer',

    // Business & Finance
    'Accountant',
    'Auditor',
    'Banker',
    'Financial Analyst',
    'Economist',
    'Investment Advisor',
    'Tax Consultant',

    // Management
    'Project Manager',
    'Office Manager',
    'Operations Manager',
    'Human Resources Manager',
    'Supply Chain Manager',
    'Hospitality Manager',

    // Education
    'Teacher',
    'Professor',
    'Lecturer',
    'School Administrator',
    'Education Consultant',

    // Sales & Marketing
    'Marketing Specialist',
    'Digital Marketer',
    'Sales Representative',
    'Sales Manager',
    'Brand Manager',
    'Public Relations Officer',

    // Legal
    'Lawyer',
    'Judge',
    'Prosecutor',
    'Legal Advisor',

    // Agriculture
    'Agronomist',
    'Animal Scientist',
    'Agricultural Economist',
    'Extension Worker',

    // Construction
    'Architect',
    'Construction Manager',
    'Quantity Surveyor',
    'Urban Planner',

    // Hospitality & Tourism
    'Hotel Manager',
    'Tour Guide',
    'Travel Consultant',
    'Chef',

    // Media & Communication
    'Journalist',
    'Editor',
    'Content Writer',
    'Translator',

    // Social Services
    'Social Worker',
    'Community Development Officer',
    'Counselor',

    // Other Professions
    'Driver',
    'Security Officer',
    'Administrative Assistant',
    'Receptionist',
    'Customer Service Representative'
  ];

  static final List<String> languages = [
    // Major working languages (federal level)
    'Amharic',
    'English',

    // Regional state official languages
    'Afar',
    'Oromo',
    'Somali',
    'Tigrinya',
    'Sidama',

    // Widely spoken languages (1M+ speakers)
    'Wolaytta',
    'Gurage',
    'Hadiyya',
    'Kambaata',
    'Afaan Oromoo',
    'Silt\'e',
    'Kistane',

    // Other significant languages
    'Gedeo',
    'Kafa',
    'Bench',
    'Awi',
    'Gamo',
    'Goffa',
    'Dawro',
    'Berta',
    'Kunama',
    'Nuer',
    'Anuak',
    'Agaw',
    'Agew',
    'Tigre',
    'Saho',

    // Special categories
    'Sign Language',
    'Other Local Language',
    'Other Foreign Language'
  ];
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1).toLowerCase()}";
  }
}