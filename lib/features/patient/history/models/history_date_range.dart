import 'package:flutter/material.dart';

/// Inclusive date range used by the history and reports module.
class HistoryDateRange {
  const HistoryDateRange({
    required this.label,
    required this.startDate,
    required this.endDate,
    this.isCustom = false,
  });

  final String label;
  final DateTime startDate;
  final DateTime endDate;
  final bool isCustom;

  DateTime get normalizedStart =>
      DateTime(startDate.year, startDate.month, startDate.day);

  DateTime get normalizedEnd =>
      DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59, 999);

  bool contains(DateTime date) {
    return !date.isBefore(normalizedStart) && !date.isAfter(normalizedEnd);
  }

  DateTimeRange toDateTimeRange() {
    return DateTimeRange(start: normalizedStart, end: normalizedEnd);
  }

  factory HistoryDateRange.today() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return HistoryDateRange(label: 'Today', startDate: today, endDate: today);
  }

  factory HistoryDateRange.last7Days() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return HistoryDateRange(
      label: 'Last 7 Days',
      startDate: today.subtract(const Duration(days: 6)),
      endDate: today,
    );
  }

  factory HistoryDateRange.last30Days() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return HistoryDateRange(
      label: 'Last 30 Days',
      startDate: today.subtract(const Duration(days: 29)),
      endDate: today,
    );
  }

  factory HistoryDateRange.thisMonth() {
    final now = DateTime.now();
    return HistoryDateRange(
      label: 'This Month',
      startDate: DateTime(now.year, now.month, 1),
      endDate: DateTime(now.year, now.month, now.day),
    );
  }

  factory HistoryDateRange.custom(DateTimeRange range) {
    return HistoryDateRange(
      label: 'Custom Range',
      startDate: range.start,
      endDate: range.end,
      isCustom: true,
    );
  }

  static List<HistoryDateRange> quickOptions() {
    return [
      HistoryDateRange.today(),
      HistoryDateRange.last7Days(),
      HistoryDateRange.last30Days(),
      HistoryDateRange.thisMonth(),
    ];
  }
}
