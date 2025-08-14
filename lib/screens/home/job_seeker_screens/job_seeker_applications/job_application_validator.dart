import '../../../../models/job _seeker_models/education_model.dart';
import '../../../../models/job _seeker_models/job_seeker_model.dart';
import '../../../../models/job _seeker_models/work_experience_model.dart';

import '../../../../models/job_model.dart';

class JobApplicationValidator {
  // Thresholds for compatibility levels (now in percentages 0-100)
  static const double minimumCompatibility = 30; // Below 30% - cannot apply
  static const double warningThreshold = 50;    // 30-50% - warning
  static const double goodCompatibility = 70;   // Above 70% - good match

  static CompatibilityResult validateApplication(JobSeeker seeker, JobModel job) {
    // First check gender requirement (strict enforcement)
    if (job.requiredGender != null &&
        job.requiredGender!.isNotEmpty &&
        job.requiredGender!.toLowerCase() != seeker.sex.toLowerCase()) {
      return CompatibilityResult(
        canApply: false,
        message: "This position is only available for ${job.requiredGender} candidates",
        compatibilityScore: 0,
      );
    }

    if (!isProfileComplete(seeker)) {
      return CompatibilityResult(
        canApply: false,
        message: "Please complete your profile before applying",
        compatibilityScore: 0,
      );
    }

    final score = calculateCompatibility(seeker, job) * 100; // Convert to percentage

    if (score < minimumCompatibility) {
      return CompatibilityResult(
        canApply: false,
        message: "Your profile doesn't meet the minimum requirements for this position (${score.toStringAsFixed(0)}% match)",
        compatibilityScore: score,
      );
    } else if (score < warningThreshold) {
      return CompatibilityResult(
        canApply: true,
        requiresConfirmation: true,
        message: "Your profile matches ${score.toStringAsFixed(0)}% of requirements. "
            "We recommend improving your profile before applying.",
        compatibilityScore: score,
      );
    } else if (score < goodCompatibility) {
      return CompatibilityResult(
        canApply: true,
        requiresConfirmation: false,
        message: "Your profile matches ${score.toStringAsFixed(0)}% of requirements",
        compatibilityScore: score,
      );
    } else {
      return CompatibilityResult(
        canApply: true,
        requiresConfirmation: false,
        message: "Great match! Your profile matches ${score.toStringAsFixed(0)}% of requirements",
        compatibilityScore: score,
      );
    }
  }

  static bool isProfileComplete(JobSeeker jobSeeker) {
    return jobSeeker.isProfileComplete || jobSeeker.checkProfileComplete();
  }

  static double calculateCompatibility(JobSeeker seeker, JobModel job) {
    final scores = <double>[];
    final weights = <double>[];

    // 1. Skills Matching (25% weight)
    if (job.requiredSkills.isNotEmpty) {
      final skillScore = calculateSkillsMatch(seeker.skills, job.requiredSkills);
      scores.add(skillScore);
      weights.add(0.25);
    }

    // 2. Education Matching (20% weight)
    final educationScore = calculateEducationMatch(seeker.educationHistory, job);
    scores.add(educationScore);
    weights.add(0.20);

    // 3. Experience Matching (20% weight)
    final experienceScore = calculateExperienceMatch(seeker.workExperience, job);
    scores.add(experienceScore);
    weights.add(0.20);

    // 4. Location Matching (15% weight)
    final locationScore = calculateLocationMatch(seeker, job);
    scores.add(locationScore);
    weights.add(0.15);

    // 5. Language Matching (10% weight)
    final languageScore = calculateLanguageMatch(seeker.languages, job.languages);
    scores.add(languageScore);
    weights.add(0.10);

    // 6. Field of Study Matching (10% weight)
    final fieldScore = calculateFieldMatch(seeker.educationHistory, job.fieldsOfStudy);
    scores.add(fieldScore);
    weights.add(0.10);

    // Calculate weighted average
    double totalScore = 0;
    double totalWeight = 0;

    for (int i = 0; i < scores.length; i++) {
      totalScore += scores[i] * weights[i];
      totalWeight += weights[i];
    }

    return totalWeight > 0 ? totalScore / totalWeight : 0;
  }

  // Detailed matching functions (unchanged from original)
  static double calculateSkillsMatch(List<String>? seekerSkills, List<String> jobSkills) {
    if (seekerSkills == null || seekerSkills.isEmpty) return 0;
    final matchingSkills = jobSkills.where((skill) => seekerSkills.contains(skill)).length;
    return matchingSkills / jobSkills.length;
  }

  static double calculateEducationMatch(List<Education>? educationHistory, JobModel job) {
    if (educationHistory == null || educationHistory.isEmpty) return 0;
    if (job.educationLevel.isEmpty) return 0.5;

    final highestEducation = getHighestEducation(educationHistory);
    final jobLevel = job.educationLevel.toLowerCase();
    final seekerLevel = highestEducation.degree?.toLowerCase() ?? '';

    // Enhanced education level matching
    if (jobLevel.contains('phd') || jobLevel.contains('doctorate')) {
      if (seekerLevel.contains('phd') || seekerLevel.contains('doctorate')) return 1.0;
      if (seekerLevel.contains('master')) return 0.7;
      if (seekerLevel.contains('bachelor')) return 0.5;
      return 0.2;
    } else if (jobLevel.contains('master')) {
      if (seekerLevel.contains('master')) return 1.0;
      if (seekerLevel.contains('phd') || seekerLevel.contains('doctorate')) return 0.9;
      if (seekerLevel.contains('bachelor')) return 0.6;
      return 0.3;
    } else if (jobLevel.contains('bachelor')) {
      if (seekerLevel.contains('bachelor')) return 1.0;
      if (seekerLevel.contains('master') || seekerLevel.contains('phd') || seekerLevel.contains('doctorate')) return 0.8;
      if (seekerLevel.contains('diploma')) return 0.5;
      return 0.2;
    } else if (jobLevel.contains('diploma')) {
      if (seekerLevel.contains('diploma')) return 1.0;
      if (seekerLevel.contains('bachelor') || seekerLevel.contains('master') || seekerLevel.contains('phd') || seekerLevel.contains('doctorate')) return 0.7;
      return 0.3;
    }

    return 0.5; // Neutral for unspecified levels
  }

  static double calculateExperienceMatch(List<WorkExperience>? workExperience, JobModel job) {
    if (workExperience == null || workExperience.isEmpty) {
      return job.experienceLevel.toLowerCase().contains('entry') ? 0.8 : 0.2;
    }

    final totalYears = calculateTotalExperienceYears(workExperience);

    switch (job.experienceLevel.toLowerCase()) {
      case 'entry':
        return totalYears <= 2 ? 1.0 : 0.8;
      case 'mid':
        if (totalYears >= 2 && totalYears <= 5) return 1.0;
        if (totalYears > 5) return 0.7;
        return 0.4;
      case 'senior':
        if (totalYears > 5) return 1.0;
        if (totalYears > 3) return 0.6;
        return 0.2;
      default:
        return 0.5;
    }
  }

  static double calculateLocationMatch(JobSeeker seeker, JobModel job) {
    if (job.jobSite?.toLowerCase() == 'remote') return 1.0;
    if (job.city != null && job.city!.isNotEmpty) {
      return (seeker.city == job.city) ? 1.0 : 0.1;
    }
    if (job.region != null && job.region!.isNotEmpty) {
      return (seeker.region == job.region) ? 0.8 : 0.3;
    }
    return 0.5;
  }

  static double calculateLanguageMatch(List<String>? seekerLanguages, List<String> jobLanguages) {
    if (seekerLanguages == null || seekerLanguages.isEmpty) return 0;
    if (jobLanguages.isEmpty) return 0.5;
    final matchingLanguages = jobLanguages.where((lang) => seekerLanguages.contains(lang)).length;
    return matchingLanguages / jobLanguages.length;
  }

  static double calculateFieldMatch(List<Education>? educationHistory, List<String> jobFields) {
    if (educationHistory == null || educationHistory.isEmpty) return 0;
    if (jobFields.isEmpty) return 0.5;
    for (final education in educationHistory) {
      for (final field in jobFields) {
        if (education.fieldOfStudy.toLowerCase().contains(field.toLowerCase())) {
          return 1.0;
        }
      }
    }
    return 0;
  }

  // Helper methods (unchanged from original)
  static Education getHighestEducation(List<Education> educationHistory) {
    final sorted = List<Education>.from(educationHistory);
    sorted.sort((a, b) {
      const order = {'University': 3, 'College': 2, 'High School': 1};
      return (order[b.educationType] ?? 0).compareTo(order[a.educationType] ?? 0);
    });
    return sorted.first;
  }

  static int calculateTotalExperienceYears(List<WorkExperience> experiences) {
    int totalDays = 0;
    for (final exp in experiences) {
      final endDate = exp.isCurrent ? DateTime.now() : exp.endDate;
      if (endDate != null) {
        totalDays += endDate.difference(exp.startDate).inDays;
      }
    }
    return totalDays ~/ 365;
  }
}

class CompatibilityResult {
  final bool canApply;
  final bool requiresConfirmation;
  final String message;
  final double compatibilityScore;

  CompatibilityResult({
    required this.canApply,
    this.requiresConfirmation = false,
    required this.message,
    required this.compatibilityScore,
  });
}