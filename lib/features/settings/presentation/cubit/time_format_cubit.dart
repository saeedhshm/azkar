import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/storage/local_storage_service.dart';
import '../../../prayer_times/data/services/prayer_settings_provider.dart';

class TimeFormatState extends Equatable {
  const TimeFormatState({required this.use24h});

  final bool use24h;

  @override
  List<Object?> get props => [use24h];
}

class TimeFormatCubit extends Cubit<TimeFormatState> {
  TimeFormatCubit(this._storage, this._settingsProvider)
    : super(const TimeFormatState(use24h: false));

  final LocalStorageService _storage;
  final PrayerSettingsProvider _settingsProvider;

  void load() {
    // Move any value saved by an earlier release into the shared store so the
    // app and the home widget read the same preference.
    _settingsProvider.migrateLegacyTimeFormat();
    emit(TimeFormatState(use24h: _storage.getUse24HourFormat()));
  }

  Future<void> setUse24h(bool value) async {
    await _storage.saveUse24HourFormat(value);
    emit(TimeFormatState(use24h: value));
  }
}
