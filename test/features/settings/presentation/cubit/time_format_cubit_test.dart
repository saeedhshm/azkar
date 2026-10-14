import 'package:azkar/core/storage/local_storage_service.dart';
import 'package:azkar/features/prayer_times/data/services/prayer_settings_provider.dart';
import 'package:azkar/features/settings/presentation/cubit/time_format_cubit.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Storage backed by an in-memory map, mirroring the Hive-backed service.
class InMemoryStorage extends LocalStorageService {
  InMemoryStorage([Map<String, Object?>? initial]) {
    if (initial != null) {
      _data.addAll(initial);
    }
  }

  final Map<String, Object?> _data = {};

  @override
  Object? getRaw(String key) => _data[key];

  @override
  Future<void> putRaw(String key, Object? value) async {
    _data[key] = value;
  }

  @override
  bool getUse24HourFormat() =>
      _data['time_format_24h'] as bool? ?? false;

  @override
  Future<void> saveUse24HourFormat(bool value) async {
    _data['time_format_24h'] = value;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PrayerSettingsProvider time format', () {
    test('reads the preference from the shared storage', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final storage = InMemoryStorage({'time_format_24h': true});

      final provider = PrayerSettingsProvider(prefs, localStorage: storage);

      expect(provider.getUse24HourFormat(), isTrue);
    });

    test('returns false when nothing is stored', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final storage = InMemoryStorage();

      final provider = PrayerSettingsProvider(prefs, localStorage: storage);

      expect(provider.getUse24HourFormat(), isFalse);
    });

    test('migrates the legacy SharedPreferences value once', () async {
      SharedPreferences.setMockInitialValues({'use_24_hour_format': true});
      final prefs = await SharedPreferences.getInstance();
      final storage = InMemoryStorage();

      final provider = PrayerSettingsProvider(prefs, localStorage: storage);

      expect(provider.migrateLegacyTimeFormat(), isTrue);
      expect(storage.getUse24HourFormat(), isTrue);
      expect(prefs.getBool('use_24_hour_format'), isNull);

      // A second run has nothing left to migrate.
      expect(provider.migrateLegacyTimeFormat(), isFalse);
    });

    test('does not migrate when the shared storage already has a value', () async {
      SharedPreferences.setMockInitialValues({'use_24_hour_format': true});
      final prefs = await SharedPreferences.getInstance();
      final storage = InMemoryStorage({'time_format_24h': false});

      final provider = PrayerSettingsProvider(prefs, localStorage: storage);

      expect(provider.getUse24HourFormat(), isFalse);
    });

    test('falls back to the legacy key without shared storage', () async {
      SharedPreferences.setMockInitialValues({'use_24_hour_format': true});
      final prefs = await SharedPreferences.getInstance();

      final provider = PrayerSettingsProvider(prefs);

      expect(provider.getUse24HourFormat(), isTrue);
    });
  });

  group('TimeFormatCubit', () {
    test('loads the value stored in the shared storage', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final storage = InMemoryStorage({'time_format_24h': true});
      final provider = PrayerSettingsProvider(prefs, localStorage: storage);

      final cubit = TimeFormatCubit(storage, provider);
      cubit.load();

      expect(cubit.state.use24h, isTrue);

      cubit.close();
    });

    test('migrates the legacy value before loading', () async {
      SharedPreferences.setMockInitialValues({'use_24_hour_format': true});
      final prefs = await SharedPreferences.getInstance();
      final storage = InMemoryStorage();
      final provider = PrayerSettingsProvider(prefs, localStorage: storage);

      final cubit = TimeFormatCubit(storage, provider);
      cubit.load();

      expect(cubit.state.use24h, isTrue);
      expect(storage.getUse24HourFormat(), isTrue);
      expect(prefs.getBool('use_24_hour_format'), isNull);

      cubit.close();
    });

    test('persists changes to the shared storage', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final storage = InMemoryStorage();
      final provider = PrayerSettingsProvider(prefs, localStorage: storage);

      final cubit = TimeFormatCubit(storage, provider);
      cubit.load();

      await cubit.setUse24h(true);

      expect(cubit.state.use24h, isTrue);
      expect(storage.getUse24HourFormat(), isTrue);
      // The provider must read the same store the cubit writes to.
      expect(provider.getUse24HourFormat(), isTrue);

      cubit.close();
    });
  });
}
