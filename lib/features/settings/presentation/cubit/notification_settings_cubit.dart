import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/notifications/notification_service.dart';
import '../../../../core/storage/local_storage_service.dart';
import '../../../../core/utils/time_of_day_converter.dart';
import 'notification_settings_state.dart';

class NotificationSettingsCubit extends Cubit<NotificationSettingsState> {
  NotificationSettingsCubit({
    required LocalStorageService localStorage,
    required NotificationService notificationService,
  }) : _localStorage = localStorage,
       _notificationService = notificationService,
       super(const NotificationSettingsState());

  final LocalStorageService _localStorage;
  final NotificationService _notificationService;

  Future<void> load() async {
    final enabled = _localStorage.getNotificationsEnabled();
    final morning = TimeOfDayConverter.fromStorage(
      _localStorage.getMorningReminderTime(),
    );
    final evening = TimeOfDayConverter.fromStorage(
      _localStorage.getEveningReminderTime(),
    );

    emit(state.copyWith(enabled: enabled, morning: morning, evening: evening));
  }

  void setEnabled(bool enabled) {
    emit(state.copyWith(enabled: enabled));
  }

  void setMorning(TimeOfDay morning) {
    emit(state.copyWith(morning: morning));
  }

  void setEvening(TimeOfDay evening) {
    emit(state.copyWith(evening: evening));
  }

  Future<void> save() async {
    emit(state.copyWith(saveStatus: NotificationSaveStatus.saving));

    try {
      await _localStorage.saveNotificationsEnabled(state.enabled);
      await _localStorage.saveMorningReminderTime(
        TimeOfDayConverter.toStorage(state.morning),
      );
      await _localStorage.saveEveningReminderTime(
        TimeOfDayConverter.toStorage(state.evening),
      );

      await _notificationService.scheduleDailyReminders(
        enabled: state.enabled,
        morning: state.morning,
        evening: state.evening,
      );

      emit(state.copyWith(saveStatus: NotificationSaveStatus.saved));
    } catch (error) {
      emit(
        state.copyWith(
          saveStatus: NotificationSaveStatus.failure,
          errorMessage: error.toString(),
        ),
      );
    }
  }
}
