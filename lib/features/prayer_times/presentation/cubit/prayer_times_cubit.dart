import 'dart:async';

import 'package:adhan/adhan.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:intl/intl.dart';

import '../../../../core/notifications/notification_service.dart';
import '../../data/models/city_entry.dart';
import '../../data/services/city_database_service.dart';
import '../../data/services/location_service.dart';
import '../../data/services/network_service.dart';
import '../../data/services/prayer_service.dart';
import '../../data/services/prayer_settings_provider.dart';
import '../../../../core/services/prayer_schedule_service.dart';
import '../../data/services/widget_update_service.dart';
import '../../domain/entities/prayer_settings.dart';
import 'prayer_times_state.dart';

/// Cubit managing prayer times state and widget updates.
///
/// Responsibilities:
/// - Load and calculate prayer times
/// - Manage location (GPS or manual)
/// - Update home widget via WidgetUpdateService
/// - Schedule notifications
/// - Maintain 1-second ticker for UI countdown
///
/// Widget updates are handled separately by Android's AlarmManager
/// via WidgetUpdateReceiver for background reliability.
class PrayerTimesCubit extends Cubit<PrayerTimesState> {
  PrayerTimesCubit({
    required PrayerService prayerService,
    required LocationService locationService,
    required PrayerSettingsProvider settingsProvider,
    required NetworkService networkService,
    required CityDatabaseService cityDatabaseService,
    required NotificationService notificationService,
    required PrayerScheduleService prayerScheduleService,
    required WidgetUpdateService widgetUpdateService,
  }) : _prayerService = prayerService,
       _locationService = locationService,
       _settingsProvider = settingsProvider,
       _networkService = networkService,
       _cityDatabaseService = cityDatabaseService,
       _notificationService = notificationService,
       _prayerScheduleService = prayerScheduleService,
       _widgetUpdateService = widgetUpdateService,
       super(PrayerTimesState(settings: PrayerSettings.defaults()));

  final PrayerService _prayerService;
  final LocationService _locationService;
  final PrayerSettingsProvider _settingsProvider;
  final NetworkService _networkService;
  final CityDatabaseService _cityDatabaseService;
  final NotificationService _notificationService;
  final PrayerScheduleService _prayerScheduleService;
  final WidgetUpdateService _widgetUpdateService;

  Timer? _ticker;

  /// Method channel for communicating with Android native code
  static const _platform = MethodChannel('com.example.azkar/widget');

  /// Loads prayer times and initializes all services.
  ///
  /// This is the main entry point called when the app starts or
  /// when the user refreshes prayer times.
  Future<void> load() async {
    emit(state.copyWith(status: PrayerTimesStatus.loading));

    final settings = _settingsProvider.load();
    final cachedLocation = _settingsProvider.loadCachedLocation();
    final isOnline = await _networkService.isOnline();
    if (isOnline) {
      unawaited(_cityDatabaseService.ensureDownloaded());
    }

    if (settings.useDeviceLocation) {
      final result = await _locationService.getCurrentLocation();

      if (result.status == LocationStatus.permissionDenied) {
        if (settings.manualLatitude != null &&
            settings.manualLongitude != null) {
          await _loadForCoordinates(
            settings: settings.copyWith(useDeviceLocation: false),
            latitude: settings.manualLatitude!,
            longitude: settings.manualLongitude!,
            locationLabel: settings.manualLabel,
          );
          return;
        }
        if (cachedLocation != null) {
          await _loadForCoordinates(
            settings: settings,
            latitude: cachedLocation.latitude,
            longitude: cachedLocation.longitude,
            locationLabel: cachedLocation.label,
          );
          return;
        }
        emit(
          state.copyWith(
            status: PrayerTimesStatus.permissionDenied,
            settings: settings,
          ),
        );
        return;
      }

      if (result.status == LocationStatus.permissionDeniedForever) {
        if (settings.manualLatitude != null &&
            settings.manualLongitude != null) {
          await _loadForCoordinates(
            settings: settings.copyWith(useDeviceLocation: false),
            latitude: settings.manualLatitude!,
            longitude: settings.manualLongitude!,
            locationLabel: settings.manualLabel,
          );
          return;
        }
        if (cachedLocation != null) {
          await _loadForCoordinates(
            settings: settings,
            latitude: cachedLocation.latitude,
            longitude: cachedLocation.longitude,
            locationLabel: cachedLocation.label,
          );
          return;
        }
        emit(
          state.copyWith(
            status: PrayerTimesStatus.permissionDeniedForever,
            settings: settings,
          ),
        );
        return;
      }

      if (result.status == LocationStatus.serviceDisabled) {
        if (settings.manualLatitude != null &&
            settings.manualLongitude != null) {
          await _loadForCoordinates(
            settings: settings.copyWith(useDeviceLocation: false),
            latitude: settings.manualLatitude!,
            longitude: settings.manualLongitude!,
            locationLabel: settings.manualLabel,
          );
          return;
        }
        if (cachedLocation != null) {
          await _loadForCoordinates(
            settings: settings,
            latitude: cachedLocation.latitude,
            longitude: cachedLocation.longitude,
            locationLabel: cachedLocation.label,
          );
          return;
        }
        emit(
          state.copyWith(
            status: PrayerTimesStatus.serviceDisabled,
            settings: settings,
          ),
        );
        return;
      }

      final latitude = result.latitude;
      final longitude = result.longitude;

      if (latitude == null || longitude == null) {
        emit(
          state.copyWith(
            status: PrayerTimesStatus.failure,
            settings: settings,
            errorMessage: 'Missing coordinates',
          ),
        );
        return;
      }

      String? label;
      if (isOnline) {
        label = await _locationService.reverseGeocode(
          latitude: latitude,
          longitude: longitude,
        );
        if (label != null && label.trim().isNotEmpty) {
          await _settingsProvider.saveCachedLocation(
            latitude: latitude,
            longitude: longitude,
            label: label,
          );
        }
      }

      label ??= cachedLocation?.label;

      await _loadForCoordinates(
        settings: settings,
        latitude: latitude,
        longitude: longitude,
        locationLabel: label ?? settings.manualLabel ?? 'GPS',
      );
    } else if (settings.manualLatitude != null &&
        settings.manualLongitude != null) {
      await _loadForCoordinates(
        settings: settings,
        latitude: settings.manualLatitude!,
        longitude: settings.manualLongitude!,
        locationLabel: settings.manualLabel,
      );
    } else if (cachedLocation != null) {
      await _loadForCoordinates(
        settings: settings,
        latitude: cachedLocation.latitude,
        longitude: cachedLocation.longitude,
        locationLabel: cachedLocation.label,
      );
    } else {
      emit(
        state.copyWith(
          status: PrayerTimesStatus.permissionDenied,
          settings: settings,
        ),
      );
    }
  }

  Future<void> setManualLocation({
    required double latitude,
    required double longitude,
    required String label,
  }) async {
    await _settingsProvider.saveManualLocation(
      latitude: latitude,
      longitude: longitude,
      label: label,
    );

    final settings = _settingsProvider.load().copyWith(
      useDeviceLocation: false,
      manualLatitude: latitude,
      manualLongitude: longitude,
      manualLabel: label,
    );

    await _settingsProvider.save(settings);

    await _loadForCoordinates(
      settings: settings,
      latitude: latitude,
      longitude: longitude,
      locationLabel: label,
    );
  }

  Future<bool> ensureCityDatabaseAvailable() async {
    if (await _cityDatabaseService.isDownloaded()) {
      return true;
    }
    final downloaded = await _cityDatabaseService.ensureDownloaded();
    return downloaded;
  }

  String? getCityDownloadError() => _cityDatabaseService.lastError;

  Future<List<CityEntry>> searchCities(String query) {
    return _cityDatabaseService.search(query);
  }

  Future<bool> isOnline() => _networkService.isOnline();

  Future<void> useDeviceLocation() async {
    await _settingsProvider.setUseDeviceLocation(true);
    await load();
  }

  Future<void> updateSettings({
    CalculationMethod? method,
    Madhab? madhab,
    Map<Prayer, int>? offsets,
    String? customSound,
    bool setCustomSound = false,
  }) async {
    final updated = state.settings.copyWith(
      method: method,
      madhab: madhab,
      offsets: offsets,
      customAdhanSound: setCustomSound
          ? customSound
          : state.settings.customAdhanSound,
    );
    await _settingsProvider.save(updated);
    await _loadForCoordinates(
      settings: updated,
      latitude: state.latitude,
      longitude: state.longitude,
      locationLabel: state.locationLabel,
    );
  }

  Future<void> refresh() async => load();

  /// Starts Android native background widget updates.
  ///
  /// This triggers the WidgetUpdateReceiver to begin scheduling
  /// 60-second widget updates via AlarmManager.
  ///
  /// Called when the app successfully loads prayer times.
  Future<void> _startAndroidWidgetUpdates() async {
    try {
      await _platform.invokeMethod('startWidgetUpdates');
    } catch (e) {
      // Platform channel not available or error - widget updates
      // will still work when the app is in foreground via the ticker
    }
  }

  /// Loads prayer times for specific coordinates and updates all services.
  Future<void> _loadForCoordinates({
    required PrayerSettings settings,
    required double? latitude,
    required double? longitude,
    required String? locationLabel,
  }) async {
    if (latitude == null || longitude == null) {
      emit(
        state.copyWith(
          status: PrayerTimesStatus.failure,
          settings: settings,
          errorMessage: 'Missing coordinates',
        ),
      );
      return;
    }

    final coordinates = Coordinates(latitude, longitude);
    final now = DateTime.now();
    final summary = _prayerService.buildSummary(
      coordinates: coordinates,
      date: now,
      settings: settings,
    );

    final gregorianDate = DateFormat.yMMMMEEEEd().format(DateTime.now());
    final hijri = HijriCalendar.fromDate(DateTime.now());
    final hijriLine = hijri.toFormat('dd MMMM yyyy');

    emit(
      state.copyWith(
        status: PrayerTimesStatus.ready,
        settings: settings,
        latitude: latitude,
        longitude: longitude,
        locationLabel: locationLabel,
        prayerTimes: summary.prayerTimes,
        currentPrayer: summary.currentPrayer,
        nextPrayer: summary.nextPrayer,
        nextPrayerTime: summary.nextPrayerTime,
        countdown: summary.countdown,
        gregorianDate: gregorianDate,
        hijriDate: hijriLine,
      ),
    );

    // Schedule prayer notifications
    await _notificationService.schedulePrayerNotifications(
      prayerTimes: summary.prayerTimes,
      soundName: settings.customAdhanSound,
    );

    // Update widget with recalculated data
    await _updateWidget(
      latitude: latitude,
      longitude: longitude,
      settings: settings,
      locationLabel: locationLabel ?? settings.manualLabel ?? 'GPS',
    );

    // Start Android background widget updates
    await _startAndroidWidgetUpdates();

    // Start UI ticker for in-app countdown display
    _startTicker();
  }

  /// Updates the home widget using the new service architecture.
  ///
  /// This method:
  /// 1. Uses PrayerScheduleService to calculate next prayer dynamically
  /// 2. Handles Isha → Fajr transition correctly
  /// 3. Prevents negative countdown values
  /// 4. Uses WidgetUpdateService to save and trigger widget update
  Future<void> _updateWidget({
    required double latitude,
    required double longitude,
    required PrayerSettings settings,
    required String locationLabel,
  }) async {
    final use24h = _settingsProvider.getUse24HourFormat();

    final model = _prayerScheduleService.calculateWidgetData(
      latitude: latitude,
      longitude: longitude,
      settings: settings,
      use24HourFormat: use24h,
      locationLabel: locationLabel,
    );

    if (model != null) {
      await _widgetUpdateService.updateWidget(model);
    }
  }

  /// Starts a 1-second ticker for updating the in-app UI countdown.
  ///
  /// This ticker:
  /// - Recalculates prayer times when the next prayer passes
  /// - Updates widget data every time recalculation happens
  /// - Handles day transitions (Isha → Fajr)
  /// - Stops automatically when cubit is closed
  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (state.prayerTimes == null ||
          state.latitude == null ||
          state.longitude == null) {
        return;
      }

      final now = DateTime.now();
      final nextTime = state.nextPrayerTime;

      // If next prayer time has passed, recalculate everything
      if (nextTime == null || nextTime.isBefore(now)) {
        _loadForCoordinates(
          settings: state.settings,
          latitude: state.latitude,
          longitude: state.longitude,
          locationLabel: state.locationLabel,
        );
        return;
      }

      // Update UI countdown only
      final remaining = nextTime.difference(now);
      if (!remaining.isNegative) {
        emit(state.copyWith(countdown: remaining));
      }

      // Recalculate at day boundary (after Isha, before Fajr)
      if (now.day != nextTime.day) {
        _loadForCoordinates(
          settings: state.settings,
          latitude: state.latitude,
          longitude: state.longitude,
          locationLabel: state.locationLabel,
        );
      }
    });
  }

  @override
  Future<void> close() {
    _ticker?.cancel();
    return super.close();
  }
}
