import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TimeFormatter {
  TimeFormatter._();

  static String formatTimeOfDay(
    TimeOfDay time, {
    required bool use24h,
    String? locale,
  }) {
    final date = DateTime(2020, 1, 1, time.hour, time.minute);
    return DateFormat(use24h ? 'HH:mm' : 'h:mm a', locale).format(date);
  }

  static String formatDateTime(
    DateTime time, {
    required bool use24h,
    String? locale,
  }) {
    return DateFormat(use24h ? 'HH:mm' : 'h:mm a', locale).format(time);
  }
}
