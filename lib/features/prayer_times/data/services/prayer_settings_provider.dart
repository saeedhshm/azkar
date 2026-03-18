import 'package:adhan/adhan.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/prayer_settings.dart';

class PrayerSettingsProvider {
  PrayerSettingsProvider(this._prefs);

  final SharedPreferences _prefs;

  static const _methodKey = 'prayer_calc_method';
  static const _madhabKey = 'prayer_madhab';
  static const _useDeviceLocationKey = 'prayer_use_device_location';
  static const _manualLatKey = 'prayer_manual_lat';
  static const _manualLngKey = 'prayer_manual_lng';
  static const _manualLabelKey = 'prayer_manual_label';
  static const _cachedLatKey = 'prayer_cached_lat';
  static const _cachedLngKey = 'prayer_cached_lng';
  static const _cachedLabelKey = 'prayer_cached_label';
  static const _customSoundKey = 'prayer_custom_sound';
  static const _offsetPrefix = 'prayer_offset_';

  PrayerSettings load() {
    final method = _methodFromKey(_prefs.getString(_methodKey));
    final madhab = _madhabFromKey(_prefs.getString(_madhabKey));
    final useDeviceLocation = _prefs.getBool(_useDeviceLocationKey) ?? true;
    final manualLat = _prefs.getDouble(_manualLatKey);
    final manualLng = _prefs.getDouble(_manualLngKey);
    final manualLabel = _prefs.getString(_manualLabelKey);
    final customSound = _prefs.getString(_customSoundKey);

    final offsets = <Prayer, int>{
      Prayer.fajr: _prefs.getInt('${_offsetPrefix}fajr') ?? 0,
      Prayer.dhuhr: _prefs.getInt('${_offsetPrefix}dhuhr') ?? 0,
      Prayer.asr: _prefs.getInt('${_offsetPrefix}asr') ?? 0,
      Prayer.maghrib: _prefs.getInt('${_offsetPrefix}maghrib') ?? 0,
      Prayer.isha: _prefs.getInt('${_offsetPrefix}isha') ?? 0,
    };

    return PrayerSettings(
      method: method,
      madhab: madhab,
      offsets: offsets,
      useDeviceLocation: useDeviceLocation,
      manualLatitude: manualLat,
      manualLongitude: manualLng,
      manualLabel: manualLabel,
      customAdhanSound: customSound,
    );
  }

  Future<void> save(PrayerSettings settings) async {
    await _prefs.setString(_methodKey, _methodToKey(settings.method));
    await _prefs.setString(_madhabKey, _madhabToKey(settings.madhab));
    await _prefs.setBool(_useDeviceLocationKey, settings.useDeviceLocation);

    if (settings.manualLatitude != null && settings.manualLongitude != null) {
      await _prefs.setDouble(_manualLatKey, settings.manualLatitude!);
      await _prefs.setDouble(_manualLngKey, settings.manualLongitude!);
    }

    if (settings.manualLabel != null) {
      await _prefs.setString(_manualLabelKey, settings.manualLabel!);
    }

    if (settings.customAdhanSound != null &&
        settings.customAdhanSound!.isNotEmpty) {
      await _prefs.setString(_customSoundKey, settings.customAdhanSound!);
    } else {
      await _prefs.remove(_customSoundKey);
    }

    for (final entry in settings.offsets.entries) {
      await _prefs.setInt(
        '${_offsetPrefix}${_prayerKey(entry.key)}',
        entry.value,
      );
    }
  }

  Future<void> saveManualLocation({
    required double latitude,
    required double longitude,
    required String label,
  }) async {
    await _prefs.setDouble(_manualLatKey, latitude);
    await _prefs.setDouble(_manualLngKey, longitude);
    await _prefs.setString(_manualLabelKey, label);
    await _prefs.setBool(_useDeviceLocationKey, false);
  }

  CachedLocation? loadCachedLocation() {
    final latitude = _prefs.getDouble(_cachedLatKey);
    final longitude = _prefs.getDouble(_cachedLngKey);
    final label = _prefs.getString(_cachedLabelKey);
    if (latitude == null || longitude == null || label == null) {
      return null;
    }
    return CachedLocation(
      latitude: latitude,
      longitude: longitude,
      label: label,
    );
  }

  Future<void> saveCachedLocation({
    required double latitude,
    required double longitude,
    required String label,
  }) async {
    await _prefs.setDouble(_cachedLatKey, latitude);
    await _prefs.setDouble(_cachedLngKey, longitude);
    await _prefs.setString(_cachedLabelKey, label);
  }

  Future<void> setUseDeviceLocation(bool useDeviceLocation) async {
    await _prefs.setBool(_useDeviceLocationKey, useDeviceLocation);
  }

  Future<void> saveCustomSound(String? sound) async {
    if (sound == null || sound.isEmpty) {
      await _prefs.remove(_customSoundKey);
    } else {
      await _prefs.setString(_customSoundKey, sound);
    }
  }

  String _methodToKey(CalculationMethod method) {
    return switch (method) {
      CalculationMethod.muslim_world_league => 'mwl',
      CalculationMethod.egyptian => 'egyptian',
      CalculationMethod.karachi => 'karachi',
      CalculationMethod.umm_al_qura => 'umm_al_qura',
      CalculationMethod.dubai => 'dubai',
      CalculationMethod.qatar => 'qatar',
      CalculationMethod.kuwait => 'kuwait',
      CalculationMethod.moon_sighting_committee => 'moonsighting',
      CalculationMethod.singapore => 'singapore',
      CalculationMethod.turkey => 'turkey',
      CalculationMethod.tehran => 'tehran',
      CalculationMethod.north_america => 'north_america',
      CalculationMethod.other => 'other',
    };
  }

  CalculationMethod _methodFromKey(String? value) {
    switch (value) {
      case 'mwl':
        return CalculationMethod.muslim_world_league;
      case 'karachi':
        return CalculationMethod.karachi;
      case 'umm_al_qura':
        return CalculationMethod.umm_al_qura;
      case 'dubai':
        return CalculationMethod.dubai;
      case 'qatar':
        return CalculationMethod.qatar;
      case 'kuwait':
        return CalculationMethod.kuwait;
      case 'moonsighting':
        return CalculationMethod.moon_sighting_committee;
      case 'singapore':
        return CalculationMethod.singapore;
      case 'turkey':
        return CalculationMethod.turkey;
      case 'tehran':
        return CalculationMethod.tehran;
      case 'north_america':
        return CalculationMethod.north_america;
      case 'other':
        return CalculationMethod.other;
      case 'egyptian':
      default:
        return CalculationMethod.egyptian;
    }
  }

  String _madhabToKey(Madhab madhab) {
    return madhab == Madhab.hanafi ? 'hanafi' : 'shafi';
  }

  Madhab _madhabFromKey(String? value) {
    return value == 'hanafi' ? Madhab.hanafi : Madhab.shafi;
  }

  String _prayerKey(Prayer prayer) {
    return switch (prayer) {
      Prayer.fajr => 'fajr',
      Prayer.dhuhr => 'dhuhr',
      Prayer.asr => 'asr',
      Prayer.maghrib => 'maghrib',
      Prayer.isha => 'isha',
      Prayer.sunrise => 'sunrise',
      Prayer.none => 'none',
    };
  }
}

class CachedLocation {
  const CachedLocation({
    required this.latitude,
    required this.longitude,
    required this.label,
  });

  final double latitude;
  final double longitude;
  final String label;
}
