import 'package:intl/intl.dart';

extension DateTimeExtensions on DateTime {
  String toFormattedDate() {
    return DateFormat('MMM dd, yyyy').format(this);
  }

  String toFormattedTime() {
    return DateFormat('hh:mm a').format(this);
  }

  String toFormattedDateTime() {
    return DateFormat('MMM dd, yyyy hh:mm a').format(this);
  }

  bool isSameDay(DateTime other) {
    return year == other.year && month == other.month && day == other.day;
  }

  bool isToday() {
    final now = DateTime.now();
    return isSameDay(now);
  }

  bool isPast() {
    return isBefore(DateTime.now());
  }

  bool isFuture() {
    return isAfter(DateTime.now());
  }
}

extension StringExtensions on String {
  String getInitials() {
    final parts = trim().split(' ');
    if (parts.isEmpty) return '';
    if (parts.length == 1) return parts[0].substring(0, 1).toUpperCase();
    return (parts[0].substring(0, 1) + parts[parts.length - 1].substring(0, 1))
        .toUpperCase();
  }

  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }
}
