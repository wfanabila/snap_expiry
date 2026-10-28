import 'package:intl/intl.dart';

enum ExpiryStatus {
  expired,
  expiringSoon,
  safe,
}

class ExpiryDateUtils {
  ExpiryDateUtils._();

  static DateTime dateOnly(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  static int daysDifference(
    DateTime expiryDate, {
    DateTime? today,
  }) {
    final currentDate = dateOnly(today ?? DateTime.now());
    final expiry = dateOnly(expiryDate);

    return expiry.difference(currentDate).inDays;
  }

  static ExpiryStatus statusFor(
    DateTime expiryDate, {
    int thresholdDays = 7,
    DateTime? today,
  }) {
    final daysLeft = daysDifference(
      expiryDate,
      today: today,
    );

    if (daysLeft < 0) {
      return ExpiryStatus.expired;
    }

    if (daysLeft <= thresholdDays) {
      return ExpiryStatus.expiringSoon;
    }

    return ExpiryStatus.safe;
  }

  static String formatDate(DateTime date) {
    return DateFormat('dd MMM yyyy').format(date);
  }

  static String daysRemainingLabel(
    DateTime expiryDate, {
    DateTime? today,
  }) {
    final days = daysDifference(
      expiryDate,
      today: today,
    );

    if (days < 0) {
      final overdueDays = days.abs();

      return overdueDays == 1
          ? '1 day overdue'
          : '$overdueDays days overdue';
    }

    if (days == 0) {
      return 'Expires today';
    }

    return days == 1 ? '1 day left' : '$days days left';
  }
}