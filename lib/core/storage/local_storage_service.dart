import 'package:hive_flutter/hive_flutter.dart';

import '../constants/app_constants.dart';

class LocalStorageService {
  late final Box<dynamic> _box;

  Future<void> init() async {
    await Hive.initFlutter();
    _box = await Hive.openBox<dynamic>(AppConstants.appBox);
  }

  Set<int> getFavoriteIds() {
    final raw = _box.get(AppConstants.favoritesKey, defaultValue: <dynamic>[]);

    if (raw is! List) {
      return <int>{};
    }

    return raw.whereType<int>().toSet();
  }

  Future<void> saveFavoriteIds(Set<int> ids) async {
    await _box.put(AppConstants.favoritesKey, ids.toList(growable: false));
  }

  Map<int, int> getAdhkarProgressMap() {
    final raw = _box.get(
      AppConstants.adhkarProgressKey,
      defaultValue: <String, dynamic>{},
    );
    if (raw is! Map) {
      return <int, int>{};
    }

    final parsed = <int, int>{};
    for (final entry in raw.entries) {
      final id = int.tryParse(entry.key.toString());
      final remaining = entry.value is num
          ? (entry.value as num).toInt()
          : null;

      if (id != null && remaining != null) {
        parsed[id] = remaining;
      }
    }

    return parsed;
  }

  Future<void> saveAdhkarProgressMap(Map<int, int> progressMap) async {
    final payload = <String, int>{};
    for (final entry in progressMap.entries) {
      payload[entry.key.toString()] = entry.value;
    }

    await _box.put(AppConstants.adhkarProgressKey, payload);
  }

  Future<void> saveAdhkarRemainingCount({
    required int adhkarId,
    required int remainingCount,
  }) async {
    final progressMap = getAdhkarProgressMap();
    progressMap[adhkarId] = remainingCount < 0 ? 0 : remainingCount;
    await saveAdhkarProgressMap(progressMap);
  }

  Future<void> removeAdhkarProgressForIds(Iterable<int> ids) async {
    final progressMap = getAdhkarProgressMap();
    for (final id in ids) {
      progressMap.remove(id);
    }
    await saveAdhkarProgressMap(progressMap);
  }

  int getTasbeehCount() {
    return _box.get(AppConstants.tasbeehCountKey, defaultValue: 0) as int;
  }

  Future<void> saveTasbeehCount(int value) async {
    await _box.put(AppConstants.tasbeehCountKey, value);
  }

  String getThemeMode() {
    return _box.get(AppConstants.themeModeKey, defaultValue: 'dark') as String;
  }

  Future<void> saveThemeMode(String value) async {
    await _box.put(AppConstants.themeModeKey, value);
  }

  String? getLocaleCode() {
    final value = _box.get(AppConstants.localeCodeKey);
    if (value is String && value.isNotEmpty) {
      return value;
    }
    return null;
  }

  Future<void> saveLocaleCode(String localeCode) async {
    await _box.put(AppConstants.localeCodeKey, localeCode);
  }

  bool getNotificationsEnabled() {
    return _box.get(AppConstants.notificationsEnabledKey, defaultValue: true)
        as bool;
  }

  Future<void> saveNotificationsEnabled(bool enabled) async {
    await _box.put(AppConstants.notificationsEnabledKey, enabled);
  }

  String getMorningReminderTime() {
    return _box.get(
          AppConstants.morningReminderKey,
          defaultValue: AppConstants.defaultMorningReminder,
        )
        as String;
  }

  Future<void> saveMorningReminderTime(String time) async {
    await _box.put(AppConstants.morningReminderKey, time);
  }

  String getEveningReminderTime() {
    return _box.get(
          AppConstants.eveningReminderKey,
          defaultValue: AppConstants.defaultEveningReminder,
        )
        as String;
  }

  Future<void> saveEveningReminderTime(String time) async {
    await _box.put(AppConstants.eveningReminderKey, time);
  }

  String getSleepReminderTime() {
    return _box.get(
          AppConstants.sleepReminderKey,
          defaultValue: AppConstants.defaultSleepReminder,
        )
        as String;
  }

  Future<void> saveSleepReminderTime(String time) async {
    await _box.put(AppConstants.sleepReminderKey, time);
  }

  String getWakingReminderTime() {
    return _box.get(
          AppConstants.wakingReminderKey,
          defaultValue: AppConstants.defaultWakingReminder,
        )
        as String;
  }

  Future<void> saveWakingReminderTime(String time) async {
    await _box.put(AppConstants.wakingReminderKey, time);
  }

  String getFridayReminderTime() {
    return _box.get(
          AppConstants.fridayReminderKey,
          defaultValue: AppConstants.defaultFridayReminder,
        )
        as String;
  }

  Future<void> saveFridayReminderTime(String time) async {
    await _box.put(AppConstants.fridayReminderKey, time);
  }

  bool getUse24HourFormat() {
    return _box.get(AppConstants.timeFormatKey, defaultValue: false) as bool;
  }

  Future<void> saveUse24HourFormat(bool value) async {
    await _box.put(AppConstants.timeFormatKey, value);
  }

  Map<String, dynamic>? getReaderProgress(String categoryKey) {
    final raw = _box.get('reader_progress_$categoryKey');
    if (raw is Map) {
      return Map<String, dynamic>.from(raw);
    }
    return null;
  }

  Future<void> saveReaderProgress({
    required String categoryKey,
    required int index,
    required int remainingCount,
  }) async {
    await _box.put('reader_progress_$categoryKey', {
      'index': index,
      'remainingCount': remainingCount,
    });
  }

  Future<void> clearReaderProgress(String categoryKey) async {
    await _box.delete('reader_progress_$categoryKey');
  }
}
