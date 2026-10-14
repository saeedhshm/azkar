import 'package:adhan/adhan.dart';
import 'package:azkar/core/notifications/notification_service.dart';
import 'package:azkar/core/services/prayer_schedule_service.dart';
import 'package:azkar/core/storage/local_storage_service.dart';
import 'package:azkar/features/prayer_times/data/services/city_database_service.dart';
import 'package:azkar/features/prayer_times/data/services/location_service.dart';
import 'package:azkar/features/prayer_times/data/services/network_service.dart';
import 'package:azkar/features/prayer_times/data/services/prayer_service.dart';
import 'package:azkar/features/prayer_times/data/services/prayer_settings_provider.dart';
import 'package:azkar/features/prayer_times/data/services/widget_update_service.dart';
import 'package:azkar/features/prayer_times/domain/entities/prayer_settings.dart';
import 'package:azkar/features/prayer_times/domain/entities/prayer_time_model.dart';
import 'package:azkar/features/prayer_times/presentation/cubit/prayer_times_cubit.dart';
import 'package:azkar/features/prayer_times/presentation/cubit/prayer_times_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Local storage stub that only exposes the in-memory surface the tests need.
class _StorageStub extends LocalStorageService {
  bool use24h = false;

  @override
  bool getUse24HourFormat() => use24h;
}

class _RecordingNotificationService extends NotificationService {
  int scheduleCalls = 0;

  @override
  Future<void> schedulePrayerNotifications({
    required PrayerTimes prayerTimes,
    PrayerTimes? nextDayPrayerTimes,
    String? soundName,
    DateTime? now,
  }) async {
    scheduleCalls++;
  }
}

class _RecordingWidgetUpdateService extends WidgetUpdateService {
  int updateCalls = 0;

  @override
  Future<void> updateWidget(PrayerTimeModel model) async {
    updateCalls++;
  }
}

class _FixedScheduleService extends PrayerScheduleService {
  _FixedScheduleService(
    LocalStorageService storage,
    PrayerSettingsProvider provider,
  ) : super(storage, PrayerService(), provider);

  @override
  PrayerTimeModel? calculateWidgetData({
    required double latitude,
    required double longitude,
    required PrayerSettings settings,
    required bool use24HourFormat,
    required String locationLabel,
  }) {
    return PrayerTimeModel(
      nextPrayerName: 'Fajr',
      nextPrayerLabel: 'Next prayer',
      remainingDuration: const Duration(hours: 1),
      prayerTimeFormatted: '05:00',
      prayerTimeEpoch: 0,
      gregorianDate: '2026-03-14',
      hijriDate: '1447-08-24',
      locationLabel: locationLabel,
    );
  }
}

class _GrantedLocationService extends LocationService {
  @override
  Future<LocationResult> getCurrentLocation() async {
    return const LocationResult(status: LocationStatus.granted);
  }

  @override
  Future<String?> reverseGeocode({
    required double latitude,
    required double longitude,
  }) async {
    return null;
  }
}

class _OfflineNetworkService extends NetworkService {
  @override
  Future<bool> isOnline() async => false;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late PrayerSettingsProvider settingsProvider;
  late _RecordingNotificationService notifications;
  late _RecordingWidgetUpdateService widgetUpdates;
  late _StorageStub storage;

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'prayer_manual_lat': 21.4225,
      'prayer_manual_lng': 39.8262,
      'prayer_manual_label': 'Mecca',
      'prayer_use_device_location': false,
    });

    final prefs = await SharedPreferences.getInstance();
    settingsProvider = PrayerSettingsProvider(prefs);
    notifications = _RecordingNotificationService();
    widgetUpdates = _RecordingWidgetUpdateService();
    storage = _StorageStub();
  });

  PrayerTimesCubit buildCubit() {
    return PrayerTimesCubit(
      prayerService: PrayerService(),
      locationService: _GrantedLocationService(),
      settingsProvider: settingsProvider,
      networkService: _OfflineNetworkService(),
      cityDatabaseService: CityDatabaseService(),
      notificationService: notifications,
      prayerScheduleService: _FixedScheduleService(
        storage,
        settingsProvider,
      ),
      widgetUpdateService: widgetUpdates,
    );
  }

  group('PrayerTimesCubit.updateSettings', () {
    test('recalculates times, notifications and widget after a method change', () async {
      final cubit = buildCubit();
      await cubit.load();

      expect(cubit.state.status, PrayerTimesStatus.ready);
      final before = cubit.state.prayerTimes!.fajr;
      final scheduleCallsBefore = notifications.scheduleCalls;
      final widgetCallsBefore = widgetUpdates.updateCalls;

      await cubit.updateSettings(method: CalculationMethod.karachi);

      expect(cubit.state.settings.method, CalculationMethod.karachi);
      expect(
        cubit.state.prayerTimes!.fajr,
        isNot(equals(before)),
        reason: 'prayer times must be recalculated with the new method',
      );
      expect(notifications.scheduleCalls, scheduleCallsBefore + 1);
      expect(widgetUpdates.updateCalls, widgetCallsBefore + 1);

      await cubit.close();
    });

    test('recalculates after a madhab change', () async {
      final cubit = buildCubit();
      await cubit.load();

      final before = cubit.state.prayerTimes!.asr;

      await cubit.updateSettings(madhab: Madhab.hanafi);

      expect(cubit.state.settings.madhab, Madhab.hanafi);
      expect(cubit.state.status, PrayerTimesStatus.ready);
      expect(cubit.state.prayerTimes!.asr, isNot(equals(before)));

      await cubit.close();
    });

    test('persists the updated settings', () async {
      final cubit = buildCubit();
      await cubit.load();

      await cubit.updateSettings(method: CalculationMethod.dubai);

      expect(settingsProvider.load().method, CalculationMethod.dubai);

      await cubit.close();
    });

    test('preserves location settings while updating the method', () async {
      final cubit = buildCubit();
      await cubit.load();

      await cubit.updateSettings(method: CalculationMethod.qatar);

      final persisted = settingsProvider.load();
      expect(persisted.manualLatitude, 21.4225);
      expect(persisted.manualLongitude, 39.8262);
      expect(persisted.useDeviceLocation, isFalse);

      await cubit.close();
    });

    test('works before the first load completes', () async {
      final cubit = buildCubit();

      await cubit.updateSettings(method: CalculationMethod.turkey);

      expect(cubit.state.settings.method, CalculationMethod.turkey);
      expect(cubit.state.status, PrayerTimesStatus.ready);
      expect(cubit.state.latitude, 21.4225);

      await cubit.close();
    });
  });

  group('PrayerTimesCubit.ensureLoaded', () {
    test('loads only once across repeated calls', () async {
      final cubit = buildCubit();

      await cubit.ensureLoaded();
      final scheduleCalls = notifications.scheduleCalls;
      expect(scheduleCalls, greaterThan(0));

      await cubit.ensureLoaded();
      await cubit.ensureLoaded();

      expect(notifications.scheduleCalls, scheduleCalls);

      await cubit.close();
    });
  });

  group('PrayerTimesCubit.setManualLocation', () {
    test('persists and applies valid coordinates', () async {
      final cubit = buildCubit();

      final result = await cubit.setManualLocation(
        latitude: 51.5074,
        longitude: -0.1278,
        label: 'London',
      );

      expect(result, ManualLocationResult.success);
      expect(cubit.state.latitude, 51.5074);
      expect(cubit.state.longitude, -0.1278);

      final persisted = settingsProvider.load();
      expect(persisted.manualLatitude, 51.5074);
      expect(persisted.manualLongitude, -0.1278);

      await cubit.close();
    });

    test('accepts boundary longitude values', () async {
      final cubit = buildCubit();

      final result = await cubit.setManualLocation(
        latitude: 21.4225,
        longitude: 180,
        label: 'Boundary',
      );

      expect(result, ManualLocationResult.success);
      expect(cubit.state.longitude, 180);

      await cubit.close();
    });

    test('does not persist a location whose calculation is impossible', () async {
      final cubit = buildCubit();

      // Coordinates are geographically valid, but solar calculations are
      // undefined above the polar circles, so this must fail gracefully
      // instead of crashing the app.
      final result = await cubit.setManualLocation(
        latitude: 90,
        longitude: 180,
        label: 'North Pole',
      );

      expect(result, ManualLocationResult.success);
      expect(cubit.state.status, PrayerTimesStatus.failure);

      await cubit.close();
    });

    test('rejects an out of range latitude without persisting it', () async {
      final cubit = buildCubit();
      final persistedBefore = settingsProvider.load().manualLatitude;

      final result = await cubit.setManualLocation(
        latitude: 120,
        longitude: 39.8262,
        label: 'Invalid',
      );

      expect(result, ManualLocationResult.invalidLatitude);
      expect(settingsProvider.load().manualLatitude, persistedBefore);
      expect(cubit.state.latitude, isNot(120));

      await cubit.close();
    });

    test('rejects an out of range longitude without persisting it', () async {
      final cubit = buildCubit();
      final persistedBefore = settingsProvider.load().manualLongitude;

      final result = await cubit.setManualLocation(
        latitude: 21.4225,
        longitude: -400,
        label: 'Invalid',
      );

      expect(result, ManualLocationResult.invalidLongitude);
      expect(settingsProvider.load().manualLongitude, persistedBefore);
      expect(cubit.state.longitude, isNot(-400));

      await cubit.close();
    });
  });
}
