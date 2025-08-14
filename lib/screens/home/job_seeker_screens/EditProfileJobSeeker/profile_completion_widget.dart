import 'package:flutter/material.dart';
import '../../../../models/job _seeker_models/job_seeker_model.dart';

class ProfileCompletionWidget extends StatelessWidget {
  final JobSeeker jobSeeker;
  final Function(String) onFieldPressed;

  const ProfileCompletionWidget({
    super.key,
    required this.jobSeeker,
    required this.onFieldPressed,
  });

  @override
  Widget build(BuildContext context) {
    final completion = jobSeeker.calculateProfileCompletion();
    final isComplete = completion >= 1.0;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      color: isComplete ? Colors.green[50] : Colors.orange[50],
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isComplete ? Icons.check_circle : Icons.warning,
                  color: isComplete ? Colors.green : Colors.orange,
                ),
                const SizedBox(width: 8),
                Text(
                  isComplete ? 'Profile Complete!' : 'Profile Completion',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isComplete ? Colors.green[800] : Colors.orange[800],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: completion,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(
                isComplete ? Colors.green : Colors.orange,
              ),
              minHeight: 8,
            ),
            const SizedBox(height: 8),
            Text(
              '${(completion * 100).toStringAsFixed(0)}% complete',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (!isComplete) ...[
              const SizedBox(height: 12),
              Text(
                'Complete these sections to apply for jobs:',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (jobSeeker.userTitle == null || jobSeeker.userTitle!.isEmpty)
                    _MissingFieldChip(
                      label: 'Title',
                      onPressed: () => onFieldPressed('userTitle'),
                    ),
                  if (jobSeeker.region == null || jobSeeker.region!.isEmpty)
                    _MissingFieldChip(
                      label: 'Region',
                      onPressed: () => onFieldPressed('region'),
                    ),
                  if (jobSeeker.city == null || jobSeeker.city!.isEmpty)
                    _MissingFieldChip(
                      label: 'City',
                      onPressed: () => onFieldPressed('city'),
                    ),
                  if (jobSeeker.skills == null || jobSeeker.skills!.isEmpty)
                    _MissingFieldChip(
                      label: 'Skills',
                      onPressed: () => onFieldPressed('skills'),
                    ),
                  if (jobSeeker.aboutMe == null || jobSeeker.aboutMe!.isEmpty)
                    _MissingFieldChip(
                      label: 'About Me',
                      onPressed: () => onFieldPressed('aboutMe'),
                    ),
                  if (jobSeeker.profilePictureUrl == null || jobSeeker.profilePictureUrl!.isEmpty)
                    _MissingFieldChip(
                      label: 'Profile Photo',
                      onPressed: () => onFieldPressed('profilePictureUrl'),
                    ),
                  if (jobSeeker.resumeUrl == null || jobSeeker.resumeUrl!.isEmpty)
                    _MissingFieldChip(
                      label: 'Resume',
                      onPressed: () => onFieldPressed('resumeUrl'),
                    ),
                  if (jobSeeker.educationHistory == null || jobSeeker.educationHistory!.isEmpty)
                    _MissingFieldChip(
                      label: 'Education',
                      onPressed: () => onFieldPressed('educationHistory'),
                    ),
                  if (jobSeeker.workExperience == null || jobSeeker.workExperience!.isEmpty)
                    _MissingFieldChip(
                      label: 'Work Experience',
                      onPressed: () => onFieldPressed('workExperience'),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _MissingFieldChip extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;

  const _MissingFieldChip({
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Chip(
        label: Text(label),
        backgroundColor: Colors.orange[100],
        labelStyle: TextStyle(color: Colors.orange[800]),
        avatar: Icon(Icons.edit, size: 16, color: Colors.orange[800]),
      ),
    );
  }
}