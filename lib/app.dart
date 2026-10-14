import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/di/service_locator.dart';
import 'core/routing/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/quran/data/datasources/quran_page_image_cache_service.dart';
import 'features/settings/presentation/cubit/theme_cubit.dart';
import 'features/settings/presentation/cubit/time_format_cubit.dart';

class AdhkarApp extends StatefulWidget {
  const AdhkarApp({super.key});

  @override
  State<AdhkarApp> createState() => _AdhkarAppState();
}

class _AdhkarAppState extends State<AdhkarApp> {
  @override
  void initState() {
    super.initState();
    // The app is usable immediately. Remaining Quran pages are downloaded
    // lazily while reading, so a slow or missing connection can never block
    // startup or hide the rest of the app.
    unawaited(_prefetchQuranPages());
  }

  /// Warms the Quran page cache in the background.
  ///
  /// Best effort only: pages are still downloaded on demand, so a failure here
  /// never removes an existing cache nor prevents reading cached pages.
  Future<void> _prefetchQuranPages() async {
    try {
      await getIt<QuranPageImageCacheService>().ensurePagesCached();
    } catch (_) {
      // Background prefetch failures are not user facing.
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<ThemeCubit>(
          create: (_) => getIt<ThemeCubit>()..loadTheme(),
        ),
        BlocProvider<TimeFormatCubit>(
          create: (_) => getIt<TimeFormatCubit>()..load(),
        ),
      ],
      child: BlocBuilder<ThemeCubit, ThemeMode>(
        builder: (context, themeMode) {
          return MaterialApp.router(
            title: 'Adhkar',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: themeMode,
            routerConfig: AppRouter.router,
            localizationsDelegates: context.localizationDelegates,
            supportedLocales: context.supportedLocales,
            locale: context.locale,
          );
        },
      ),
    );
  }
}
