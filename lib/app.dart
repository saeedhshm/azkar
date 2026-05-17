import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';

import 'core/di/service_locator.dart';
import 'core/routing/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/quran/data/datasources/quran_page_image_cache_service.dart';
import 'features/quran/presentation/widgets/quran_initial_download_screen.dart';
import 'features/settings/presentation/cubit/theme_cubit.dart';
import 'features/settings/presentation/cubit/time_format_cubit.dart';

class AdhkarApp extends StatefulWidget {
  const AdhkarApp({super.key});

  @override
  State<AdhkarApp> createState() => _AdhkarAppState();
}

class _AdhkarAppState extends State<AdhkarApp> {
  bool _isReady = false;
  String? _initializationError;
  QuranPagesDownloadProgress _progress = const QuranPagesDownloadProgress(
    downloadedCount: 0,
    totalCount: QuranPageImageCacheService.lastPage,
  );

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    setState(() {
      _isReady = false;
      _initializationError = null;
      _progress = const QuranPagesDownloadProgress(
        downloadedCount: 0,
        totalCount: QuranPageImageCacheService.lastPage,
      );
    });

    try {
      await getIt<QuranPageImageCacheService>().ensurePagesCached(
        onProgress: (progress) {
          if (!mounted) {
            return;
          }
          setState(() => _progress = progress);
        },
      );
      if (!mounted) {
        return;
      }
      setState(() => _isReady = true);
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _initializationError = error.toString();
      });
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
          if (_isReady) {
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
          }

          return MaterialApp(
            title: 'Adhkar',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: themeMode,
            localizationsDelegates: context.localizationDelegates,
            supportedLocales: context.supportedLocales,
            locale: context.locale,
            home: QuranInitialDownloadScreen(
              progress: _progress,
              errorMessage: _initializationError,
              onRetry: _initializeApp,
            ),
          );
        },
      ),
    );
  }
}
