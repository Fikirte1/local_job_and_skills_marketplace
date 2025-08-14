import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../models/applications_model.dart';

class AppColors {
  static const Color primary = Color(0xFF2E7D32); // Green shade
  static const Color secondary = Color(0xFF6A1B9A); // Purple shade
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF5F5F5);
  static const Color background = Color(0xFFFAFAFA);
  static const Color error = Color(0xFFD32F2F);
  static const Color success = Color(0xFF388E3C);
  static const Color warning = Color(0xFFF57C00);
  static const Color info = Color(0xFF1976D2);

  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color onSecondary = Color(0xFFFFFFFF);
  static const Color onSurface = Color(0xFF000000);
  static const Color onBackground = Color(0xFF000000);
  static const Color onError = Color(0xFFFFFFFF);

  static const Color primaryText = Color(0xFF212121);
  static const Color secondaryText = Color(0xFF757575);
  static const Color disabled = Color(0xFFBDBDBD);
  static const Color borderColor = Color(0xFFE0E0E0);

  static Color getStatusColor(ApplicationStatus status) {
    switch (status) {
      case ApplicationStatus.applied:
        return info;
      case ApplicationStatus.acceptedForInterview:
        return secondary;
      case ApplicationStatus.rejected:
        return error;
      case ApplicationStatus.interviewScheduled:
        return const Color(0xFF7B1FA2);
      case ApplicationStatus.interviewCompleted:
        return const Color(0xFF0097A7);
      case ApplicationStatus.hired:
        return success;
      case ApplicationStatus.needsResubmission:
        return warning;
      case ApplicationStatus.interviewStarted:
        return const Color(0xFF0288D1);
      case ApplicationStatus.responseSubmitted:
        return const Color(0xFF00796B);
      case ApplicationStatus.winnerAnnounced:
        return const Color(0xFF689F38);
    }
  }
}


class AppTextStyles {
  static const TextStyle displayLarge = TextStyle(
    fontSize: 57,
    fontWeight: FontWeight.w400,
    letterSpacing: -0.25,
  );

  static const TextStyle displayMedium = TextStyle(
    fontSize: 45,
    fontWeight: FontWeight.w400,
  );

  static const TextStyle displaySmall = TextStyle(
    fontSize: 36,
    fontWeight: FontWeight.w400,
  );

  static const TextStyle headlineLarge = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w400,
  );

  static const TextStyle headlineMedium = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w400,
  );

  static const TextStyle headlineSmall = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w400,
  );

  static const TextStyle titleLarge = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w500,
  );

  static const TextStyle titleMedium = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w500,
  );

  static const TextStyle titleSmall = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
  );

  static const TextStyle labelLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
  );

  static const TextStyle labelMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
  );

  static const TextStyle labelSmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
  );
}


class ChipWidget extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;

  const ChipWidget({
    Key? key,
    required this.icon,
    required this.label,
    this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color ?? Colors.grey[200],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.grey[600]),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[800],
            ),
          ),
        ],
      ),
    );
  }
}


class CompanyLogo extends StatelessWidget {
  final String? logoUrl;
  final String companyName;
  final double size;

  const CompanyLogo({
    Key? key,
    this.logoUrl,
    required this.companyName,
    this.size = 40,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: logoUrl == null ? Colors.grey[300] : null,
        image: logoUrl != null
            ? DecorationImage(
          image: NetworkImage(logoUrl!),
          fit: BoxFit.cover,
        )
            : null,
      ),
      child: logoUrl == null
          ? Center(
        child: Text(
          companyName.isNotEmpty ? companyName[0].toUpperCase() : '?',
          style: TextStyle(
            fontSize: size * 0.4,
            fontWeight: FontWeight.bold,
            color: Colors.grey[600],
          ),
        ),
      )
          : null,
    );
  }
}


class DateUtils {
  static String formatRelativeDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 30) {
      return DateFormat('MMM d, y').format(date);
    } else if (difference.inDays >= 1) {
      return '${difference.inDays} ${difference.inDays == 1 ? 'day' : 'days'} ago';
    } else if (difference.inHours >= 1) {
      return '${difference.inHours} ${difference.inHours == 1 ? 'hour' : 'hours'} ago';
    } else if (difference.inMinutes >= 1) {
      return '${difference.inMinutes} ${difference.inMinutes == 1 ? 'minute' : 'minutes'} ago';
    } else {
      return 'Just now';
    }
  }
}