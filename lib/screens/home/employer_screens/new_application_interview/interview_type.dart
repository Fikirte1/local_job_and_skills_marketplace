enum InterviewType {
  videoCall,
  questionnaire
}

extension InterviewTypeExtension on InterviewType {
  String get displayName {
    switch (this) {
      case InterviewType.videoCall:
        return 'Video Call';
      case InterviewType.questionnaire:
        return 'Questionnaire';
    }
  }
}