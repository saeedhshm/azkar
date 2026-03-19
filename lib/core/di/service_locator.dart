import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/adhkar/data/datasources/adhkar_local_data_source.dart';
import '../../features/adhkar/data/repositories/adhkar_repository_impl.dart';
import '../../features/adhkar/domain/repositories/adhkar_repository.dart';
import '../../features/adhkar/domain/usecases/get_adhkar_by_category.dart';
import '../../features/adhkar/domain/usecases/search_adhkar.dart';
import '../../features/adhkar/presentation/cubit/adhkar_cubit.dart';
import '../../features/adhkar/presentation/cubit/favorites_cubit.dart';
import '../../features/adhkar/presentation/cubit/reader_cubit.dart';
import '../../features/settings/presentation/cubit/notification_settings_cubit.dart';
import '../../features/settings/presentation/cubit/theme_cubit.dart';
import '../../features/settings/presentation/cubit/time_format_cubit.dart';
import '../../features/tasbeeh/data/repositories/tasbeeh_repository_impl.dart';
import '../../features/tasbeeh/domain/repositories/tasbeeh_repository.dart';
import '../../features/tasbeeh/presentation/cubit/tasbeeh_cubit.dart';
import '../../features/prayer_times/data/services/location_service.dart';
import '../../features/prayer_times/data/services/prayer_service.dart';
import '../../features/prayer_times/data/services/prayer_settings_provider.dart';
import '../../features/prayer_times/data/services/network_service.dart';
import '../../features/prayer_times/data/services/city_database_service.dart';
import '../../features/prayer_times/presentation/cubit/prayer_times_cubit.dart';
import '../notifications/notification_service.dart';
import '../storage/local_storage_service.dart';

final getIt = GetIt.instance;

Future<void> setupLocator() async {
  final localStorage = LocalStorageService();
  await localStorage.init();
  getIt.registerSingleton<LocalStorageService>(localStorage);

  final notifications = NotificationService();
  await notifications.init();
  getIt.registerSingleton<NotificationService>(notifications);

  final prefs = await SharedPreferences.getInstance();
  getIt.registerSingleton<PrayerSettingsProvider>(
    PrayerSettingsProvider(prefs),
  );

  getIt.registerLazySingleton<PrayerService>(PrayerService.new);
  getIt.registerLazySingleton<LocationService>(LocationService.new);
  getIt.registerLazySingleton<NetworkService>(NetworkService.new);
  getIt.registerLazySingleton<CityDatabaseService>(CityDatabaseService.new);

  getIt.registerLazySingleton<AdhkarLocalDataSource>(AdhkarLocalDataSource.new);

  getIt.registerLazySingleton<AdhkarRepository>(
    () => AdhkarRepositoryImpl(
      localDataSource: getIt<AdhkarLocalDataSource>(),
      localStorage: getIt<LocalStorageService>(),
    ),
  );

  getIt.registerLazySingleton<TasbeehRepository>(
    () => TasbeehRepositoryImpl(getIt<LocalStorageService>()),
  );

  getIt.registerLazySingleton<GetAdhkarByCategoryUseCase>(
    () => GetAdhkarByCategoryUseCase(getIt<AdhkarRepository>()),
  );

  getIt.registerLazySingleton<SearchAdhkarUseCase>(
    () => SearchAdhkarUseCase(getIt<AdhkarRepository>()),
  );

  getIt.registerFactory<ThemeCubit>(
    () => ThemeCubit(getIt<LocalStorageService>()),
  );

  getIt.registerFactory<TimeFormatCubit>(
    () => TimeFormatCubit(getIt<LocalStorageService>()),
  );

  getIt.registerFactory<AdhkarCubit>(
    () => AdhkarCubit(
      getAdhkarByCategoryUseCase: getIt<GetAdhkarByCategoryUseCase>(),
      searchAdhkarUseCase: getIt<SearchAdhkarUseCase>(),
      repository: getIt<AdhkarRepository>(),
    ),
  );

  getIt.registerFactory<FavoritesCubit>(
    () => FavoritesCubit(getIt<AdhkarRepository>()),
  );

  getIt.registerFactory<ReaderCubit>(
    () => ReaderCubit(getIt<AdhkarRepository>()),
  );

  getIt.registerFactory<TasbeehCubit>(
    () => TasbeehCubit(getIt<TasbeehRepository>()),
  );

  getIt.registerFactory<NotificationSettingsCubit>(
    () => NotificationSettingsCubit(
      localStorage: getIt<LocalStorageService>(),
      notificationService: getIt<NotificationService>(),
    ),
  );

  getIt.registerFactory<PrayerTimesCubit>(
    () => PrayerTimesCubit(
      prayerService: getIt<PrayerService>(),
      locationService: getIt<LocationService>(),
      settingsProvider: getIt<PrayerSettingsProvider>(),
      networkService: getIt<NetworkService>(),
      cityDatabaseService: getIt<CityDatabaseService>(),
      notificationService: getIt<NotificationService>(),
    ),
  );
}
