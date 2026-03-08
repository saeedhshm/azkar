import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

enum NotificationSaveStatus { initial, saving, saved, failure }

class NotificationSettingsState extends Equatable {
  const NotificationSettingsState({
    this.enabled = true,
    this.morning = const TimeOfDay(hour: 6, minute: 0),
    this.evening = const TimeOfDay(hour: 18, minute: 0),
    this.saveStatus = NotificationSaveStatus.initial,
    this.errorMessage,
  });

  final bool enabled;
  final TimeOfDay morning;
  final TimeOfDay evening;
  final NotificationSaveStatus saveStatus;
  final String? errorMessage;

  NotificationSettingsState copyWith({
    bool? enabled,
    TimeOfDay? morning,
    TimeOfDay? evening,
    NotificationSaveStatus? saveStatus,
    String? errorMessage,
  }) {
    return NotificationSettingsState(
      enabled: enabled ?? this.enabled,
      morning: morning ?? this.morning,
      evening: evening ?? this.evening,
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
    saveStatus,
    errorMessage,
  ];
}
