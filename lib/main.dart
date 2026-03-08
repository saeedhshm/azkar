import 'package:flutter/widgets.dart';
import 'package:easy_localization/easy_localization.dart';

import 'app.dart';
import 'core/di/service_locator.dart';
import 'core/storage/local_storage_service.dart';
import 'core/utils/locale_resolver.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();
  await setupLocator();

  final localStorage = getIt<LocalStorageService>();
  final initialLocale = LocaleResolver.resolveInitialLocale(
    deviceLocale: WidgetsBinding.instance.platformDispatcher.locale,
    savedLocaleCode: localStorage.getLocaleCode(),
  );

  runApp(
    EasyLocalization(
      supportedLocales: const [
        Locale('en'),
        Locale('ar'),
        Locale('tr'),
        Locale('id'),
      ],
      path: 'assets/translations',
      fallbackLocale: const Locale('en'),
      startLocale: initialLocale,
      child: const AdhkarApp(),
    ),
  );
}
