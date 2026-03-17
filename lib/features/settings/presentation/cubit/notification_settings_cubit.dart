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
    final sleep = TimeOfDayConverter.fromStorage(
      _localStorage.getSleepReminderTime(),
    );
    final waking = TimeOfDayConverter.fromStorage(
      _localStorage.getWakingReminderTime(),
    );
    final friday = TimeOfDayConverter.fromStorage(
      _localStorage.getFridayReminderTime(),
    );

    emit(
      state.copyWith(
        enabled: enabled,
        morning: morning,
        evening: evening,
        sleep: sleep,
        waking: waking,
        friday: friday,
      ),
    );
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

  void setSleep(TimeOfDay sleep) {
    emit(state.copyWith(sleep: sleep));
  }

  void setWaking(TimeOfDay waking) {
    emit(state.copyWith(waking: waking));
  }

  void setFriday(TimeOfDay friday) {
    emit(state.copyWith(friday: friday));
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
      await _localStorage.saveSleepReminderTime(
        TimeOfDayConverter.toStorage(state.sleep),
      );
      await _localStorage.saveWakingReminderTime(
        TimeOfDayConverter.toStorage(state.waking),
      );
      await _localStorage.saveFridayReminderTime(
        TimeOfDayConverter.toStorage(state.friday),
      );

      await _notificationService.scheduleReminders(
        enabled: state.enabled,
        morning: state.morning,
        evening: state.evening,
        sleep: state.sleep,
        waking: state.waking,
        friday: state.friday,
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
