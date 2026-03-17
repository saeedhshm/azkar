import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

enum NotificationSaveStatus { initial, saving, saved, failure }

class NotificationSettingsState extends Equatable {
  const NotificationSettingsState({
    this.enabled = true,
    this.morning = const TimeOfDay(hour: 6, minute: 0),
    this.evening = const TimeOfDay(hour: 18, minute: 0),
    this.sleep = const TimeOfDay(hour: 22, minute: 0),
    this.waking = const TimeOfDay(hour: 7, minute: 0),
    this.friday = const TimeOfDay(hour: 10, minute: 0),
    this.saveStatus = NotificationSaveStatus.initial,
    this.errorMessage,
  });

  final bool enabled;
  final TimeOfDay morning;
  final TimeOfDay evening;
  final TimeOfDay sleep;
  final TimeOfDay waking;
  final TimeOfDay friday;
  final NotificationSaveStatus saveStatus;
  final String? errorMessage;

  NotificationSettingsState copyWith({
    bool? enabled,
    TimeOfDay? morning,
    TimeOfDay? evening,
    TimeOfDay? sleep,
    TimeOfDay? waking,
    TimeOfDay? friday,
    NotificationSaveStatus? saveStatus,
    String? errorMessage,
  }) {
    return NotificationSettingsState(
      enabled: enabled ?? this.enabled,
      morning: morning ?? this.morning,
      evening: evening ?? this.evening,
      sleep: sleep ?? this.sleep,
      waking: waking ?? this.waking,
      friday: friday ?? this.friday,
      saveStatus: saveStatus ?? this.saveStatus,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    enabled,
    morning.hour,
    morning.minute,
    evening.hour,
    evening.minute,
    sleep.hour,
    sleep.minute,
    waking.hour,
    waking.minute,
    friday.hour,
    friday.minute,
    saveStatus,
    errorMessage,
  ];
}
