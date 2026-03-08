import 'package:flutter/material.dart';

class LocaleResolver {
  LocaleResolver._();

  static const List<String> supportedLanguageCodes = ['en', 'ar', 'tr', 'id'];

  static const Set<String> _arabicCountries = {
    'AE',
    'BH',
    'DJ',
    'DZ',
    'EG',
    'EH',
    'ER',
    'IQ',
    'JO',
    'KM',
    'KW',
    'LB',
    'LY',
    'MA',
    'MR',
    'OM',
    'PS',
    'QA',
    'SA',
    'SD',
    'SO',
    'SS',
    'SY',
    'TD',
    'TN',
    'YE',
  };

  static Locale resolveInitialLocale({
    required Locale deviceLocale,
    String? savedLocaleCode,
  }) {
    final normalizedSaved = _normalizeLanguageCode(savedLocaleCode);
    if (normalizedSaved != null) {
      return Locale(normalizedSaved);
    }

    final countryCode = deviceLocale.countryCode?.toUpperCase();
    if (countryCode != null && countryCode.isNotEmpty) {
      if (_arabicCountries.contains(countryCode)) {
        return const Locale('ar');
      }
      if (countryCode == 'TR') {
        return const Locale('tr');
      }
      if (countryCode == 'ID') {
        return const Locale('id');
      }

      final normalizedDevice = _normalizeLanguageCode(
        deviceLocale.languageCode,
      );
      if (normalizedDevice != null) {
        return Locale(normalizedDevice);
      }

      return const Locale('en');
    }

    final normalizedDevice = _normalizeLanguageCode(deviceLocale.languageCode);
    if (normalizedDevice != null) {
      return Locale(normalizedDevice);
    }

    return const Locale('en');
  }

  static String? _normalizeLanguageCode(String? code) {
    if (code == null || code.isEmpty) {
      return null;
    }

    final normalized = code.toLowerCase();
    if (normalized == 'in') {
      return 'id';
    }

    if (supportedLanguageCodes.contains(normalized)) {
      return normalized;
    }

    return null;
  }
}
