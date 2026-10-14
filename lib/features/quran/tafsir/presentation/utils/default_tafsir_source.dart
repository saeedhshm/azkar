import 'package:flutter/widgets.dart';

import '../../domain/entities/tafsir_source.dart';

/// Effective tafsir language for the current app locale.
///
/// Only Arabic and English tafsirs exist, so this is `'en'` for the English
/// app and `'ar'` for every other app language.
///
/// Reads [Localizations], which every [MaterialApp] provides, instead of the
/// localization package: the value is identical in production and the lookup
/// never needs extra setup.
String tafsirLanguageCode(BuildContext context) {
  final code = Localizations.localeOf(context).languageCode;
  return code == 'en' ? 'en' : 'ar';
}

/// Default tafsir source id for the current app language.
String defaultTafsirSourceId(BuildContext context) {
  return TafsirSource.defaultForLanguage(
    Localizations.localeOf(context).languageCode,
  );
}
