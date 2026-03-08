import 'package:flutter/material.dart';

class TimeOfDayConverter {
  TimeOfDayConverter._();

  static String toStorage(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  static TimeOfDay fromStorage(String value) {
    final parts = value.split(':');
    if (parts.length != 2) {
      return const TimeOfDay(hour: 6, minute: 0);
    }

    final hour = int.tryParse(parts[0]) ?? 6;
    final minute = int.tryParse(parts[1]) ?? 0;
    return TimeOfDay(hour: hour, minute: minute);
  }
}
