import 'dart:async';

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
import '../../features/quran/data/datasources/quran_local_data_source.dart';
import '../../features/quran/data/datasources/quran_page_image_cache_service.dart';
import '../../features/quran/data/datasources/quran_polygon_local_data_source.dart';
import '../../features/quran/data/datasources/quran_search_index.dart';
import '../../features/quran/data/repositories/quran_bookmark_repository_impl.dart';
import '../../features/quran/data/repositories/quran_last_read_repository_impl.dart';
import '../../features/quran/data/repositories/quran_polygon_repository_impl.dart';
import '../../features/quran/data/repositories/quran_repository_impl.dart';
import '../../features/quran/domain/repositories/quran_bookmark_repository.dart';
import '../../features/quran/domain/repositories/quran_last_read_repository.dart';
import '../../features/quran/domain/repositories/quran_polygon_repository.dart';
import '../../features/quran/domain/usecases/get_quran_page_polygons_use_case.dart';
import '../../features/quran/domain/repositories/quran_repository.dart';
import '../../features/quran/domain/usecases/get_quran_surahs_use_case.dart';
import '../../features/quran/domain/usecases/search_quran_use_case.dart';
import '../../features/quran/presentation/cubit/quran_ayah_selection_cubit.dart';
import '../../features/quran/presentation/cubit/quran_highlight_cubit.dart';
import '../../features/quran/presentation/cubit/quran_polygon_cubit.dart';
import '../../features/quran/presentation/cubit/quran_cubit.dart';
import '../../features/quran/actions/presentation/cubit/ayah_actions_cubit.dart';
import '../../features/quran/audio/data/datasources/quran_audio_player_service.dart';
import '../../features/quran/audio/data/datasources/recitation_timing_data_source.dart';
import '../../features/quran/audio/data/repositories/recitation_repository_impl.dart';
import '../../features/quran/audio/domain/repositories/recitation_repository.dart';
import '../../features/quran/audio/presentation/cubit/quran_audio_cubit.dart';
import '../../features/quran/data/datasources/quran_recently_read_service.dart';
import '../../features/quran/services/quran_polygon_file_cache_service.dart';
import '../../features/quran/services/quran_polygon_hit_test_engine.dart';
import '../../features/quran/services/quran_svg_memory_cache.dart';
import '../../features/quran/services/quran_svg_page_service.dart';
import '../../features/quran/tafsir/data/datasources/tafsir_local_data_source.dart';
import '../../features/quran/tafsir/data/datasources/tafsir_remote_data_source.dart';
import '../../features/quran/tafsir/data/repositories/tafsir_repository_impl.dart';
import '../../features/quran/tafsir/domain/repositories/tafsir_repository.dart';
import '../../features/quran/tafsir/domain/usecases/get_tafsir_use_case.dart';
import '../notifications/notification_service.dart';
import '../storage/local_storage_service.dart';
import '../widgets/prayer_widget_service.dart';

final getIt = GetIt.instance;

Future<void> setupLocator() async {
  final localStorage = LocalStorageService();
  await localStorage.init();
  getIt.registerSingleton<LocalStorageService>(localStorage);

  final notifications = NotificationService();
  await notifications.init();
  getIt.registerSingleton<NotificationService>(notifications);

  getIt.registerLazySingleton<QuranRecentlyReadService>(
    () => QuranRecentlyReadService(getIt<LocalStorageService>()),
  );

  final prefs = await SharedPreferences.getInstance();
  getIt.registerSingleton<PrayerSettingsProvider>(
    PrayerSettingsProvider(prefs),
  );

  getIt.registerLazySingleton<PrayerService>(PrayerService.new);
  getIt.registerLazySingleton<LocationService>(LocationService.new);
  getIt.registerLazySingleton<NetworkService>(NetworkService.new);
  getIt.registerLazySingleton<CityDatabaseService>(CityDatabaseService.new);
  getIt.registerLazySingleton<PrayerWidgetService>(
    () => PrayerWidgetService(getIt<LocalStorageService>()),
  );
  final quranLocalDataSource = QuranLocalDataSource();
  getIt.registerSingleton<QuranLocalDataSource>(quranLocalDataSource);
  unawaited(quranLocalDataSource.loadSurahs());
  getIt.registerLazySingleton<QuranPageImageCacheService>(
    () => QuranPageImageCacheService(getIt<LocalStorageService>()),
  );
  getIt.registerLazySingleton<QuranPolygonFileCacheService>(
    () => QuranPolygonFileCacheService(getIt<LocalStorageService>()),
  );
  getIt.registerLazySingleton<QuranPolygonLocalDataSource>(
    () => QuranPolygonLocalDataSource(getIt<QuranPolygonFileCacheService>()),
  );
  getIt.registerLazySingleton<QuranSvgMemoryCache>(QuranSvgMemoryCache.new);
  getIt.registerLazySingleton<QuranSvgPageService>(
    () => QuranSvgPageService(
      getIt<QuranPageImageCacheService>(),
      getIt<QuranSvgMemoryCache>(),
    ),
  );
  getIt.registerLazySingleton<QuranPolygonHitTestEngine>(
    QuranPolygonHitTestEngine.new,
  );
  getIt.registerLazySingleton<QuranSearchIndex>(QuranSearchIndex.new);
  getIt.registerLazySingleton<QuranRepository>(
    () => QuranRepositoryImpl(
      getIt<QuranLocalDataSource>(),
      getIt<QuranSearchIndex>(),
    ),
  );
  getIt.registerLazySingleton<QuranPolygonRepository>(
    () => QuranPolygonRepositoryImpl(getIt<QuranPolygonLocalDataSource>()),
  );
  getIt.registerLazySingleton<GetQuranSurahsUseCase>(
    () => GetQuranSurahsUseCase(getIt<QuranRepository>()),
  );
  getIt.registerLazySingleton<GetQuranPagePolygonsUseCase>(
    () => GetQuranPagePolygonsUseCase(getIt<QuranPolygonRepository>()),
  );
  getIt.registerLazySingleton<SearchQuranUseCase>(
    () => SearchQuranUseCase(getIt<QuranRepository>()),
  );

  getIt.registerLazySingleton<RecitationTimingDataSource>(
    RecitationTimingDataSource.new,
  );
  getIt.registerLazySingleton<QuranAudioPlayerService>(
    QuranAudioPlayerService.new,
  );
  getIt.registerLazySingleton<RecitationRepository>(
    () => RecitationRepositoryImpl(getIt<RecitationTimingDataSource>()),
  );

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
      widgetService: getIt<PrayerWidgetService>(),
    ),
  );

  getIt.registerLazySingleton<QuranBookmarkRepository>(
    () => QuranBookmarkRepositoryImpl(getIt<LocalStorageService>()),
  );
  getIt.registerLazySingleton<QuranLastReadRepository>(
    () => QuranLastReadRepositoryImpl(getIt<LocalStorageService>()),
  );

  getIt.registerFactory<QuranCubit>(
    () => QuranCubit(
      getIt<GetQuranSurahsUseCase>(),
      getIt<SearchQuranUseCase>(),
      getIt<QuranLastReadRepository>(),
    ),
  );
  getIt.registerFactory<QuranPolygonCubit>(
    () => QuranPolygonCubit(
      getIt<GetQuranPagePolygonsUseCase>(),
      getIt<QuranPolygonRepository>(),
    ),
  );
  getIt.registerFactory<QuranAyahSelectionCubit>(QuranAyahSelectionCubit.new);
  getIt.registerFactory<QuranHighlightCubit>(
    () => QuranHighlightCubit(getIt<QuranBookmarkRepository>()),
  );
  getIt.registerFactory<QuranAudioCubit>(
    () => QuranAudioCubit(
      getIt<QuranAudioPlayerService>(),
      getIt<RecitationRepository>(),
    ),
  );

  getIt.registerLazySingleton<TafsirRemoteDataSource>(TafsirRemoteDataSource.new);
  getIt.registerLazySingleton<TafsirLocalDataSource>(TafsirLocalDataSource.new);
  getIt.registerLazySingleton<TafsirRepository>(
    () => TafsirRepositoryImpl(
      getIt<TafsirRemoteDataSource>(),
      getIt<TafsirLocalDataSource>(),
    ),
  );
  getIt.registerLazySingleton<GetTafsirUseCase>(
    () => GetTafsirUseCase(getIt<TafsirRepository>()),
  );
  getIt.registerFactory<AyahActionsCubit>(
    () => AyahActionsCubit(getIt<GetTafsirUseCase>()),
  );
}
