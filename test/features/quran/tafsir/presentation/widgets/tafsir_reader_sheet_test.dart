import 'dart:async';

import 'package:azkar/core/di/service_locator.dart';
import 'package:azkar/features/quran/actions/presentation/cubit/ayah_actions_cubit.dart';
import 'package:azkar/features/quran/actions/presentation/widgets/ayah_actions_sheet.dart';
import 'package:azkar/features/quran/domain/entities/quran_selected_ayah.dart';
import 'package:azkar/features/quran/tafsir/domain/entities/tafsir_entry.dart';
import 'package:azkar/features/quran/tafsir/domain/repositories/tafsir_repository.dart';
import 'package:azkar/features/quran/tafsir/domain/usecases/get_tafsir_use_case.dart';
import 'package:azkar/features/quran/tafsir/presentation/utils/default_tafsir_source.dart';
import 'package:azkar/features/quran/tafsir/presentation/widgets/tafsir_reader_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

/// Returns distinguishable text per source so a mismatch is observable.
class _FakeTafsirRepository implements TafsirRepository {
  @override
  Future<TafsirEntry> getTafsir({
    required int surahNumber,
    required int ayahNumber,
    required String sourceId,
  }) async {
    final language = sourceId == 'ibn_kathir' ? 'en' : 'ar';
    return TafsirEntry(
      id: '$sourceId-$surahNumber:$ayahNumber',
      surahNumber: surahNumber,
      ayahNumber: ayahNumber,
      sourceName: sourceId,
      sourceLanguage: language,
      text: 'TEXT-$sourceId distinctive body',
    );
  }

  @override
  Future<List<TafsirEntry>> getMultipleTafsir({
    required int surahNumber,
    required int ayahNumber,
    required List<String> sourceIds,
  }) async {
    return [
      for (final id in sourceIds)
        await getTafsir(
          surahNumber: surahNumber,
          ayahNumber: ayahNumber,
          sourceId: id,
        ),
    ];
  }
}

void main() {
  late AyahActionsCubit cubit;

  setUp(() {
    cubit = AyahActionsCubit(GetTafsirUseCase(_FakeTafsirRepository()));
    getIt.registerSingleton<AyahActionsCubit>(cubit);
  });

  tearDown(() async {
    await getIt.reset();
  });

  Future<void> pumpApp(WidgetTester tester, Locale locale) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: locale,
        supportedLocales: const [Locale('en'), Locale('ar')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => showModalBottomSheet<void>(
                context: context,
                showDragHandle: true,
                builder: (_) => AyahActionsSheet(
                  selectedAyah: const QuranSelectedAyah(
                    pageNumber: 42,
                    polygonId: 'p1',
                    surahNumber: 57,
                    ayahNumber: 9,
                    lineNumber: 1,
                  ),
                  surahName: 'سورة الحديد',
                  ayahText: 'نص الآية',
                  onToggleBookmark: () {},
                  isBookmarked: false,
                  onPlayAyah: () {},
                  isFavoriteReciter: false,
                  onToggleFavoriteReciter: () {},
                ),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 300));
  }

  Future<void> openReaderFromActionRow(WidgetTester tester) async {
    await tester.tap(find.byIcon(Icons.auto_stories_rounded).first);
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));
  }

  testWidgets(
    'reader shows the selected source entry, not the last loaded one',
    (tester) async {
      // Regression (sura 57:9): the Jalalayn chip was selected while an
      // Ibn Kathir entry loaded later took over the whole body.
      await cubit.loadTafsir(
        surahNumber: 57,
        ayahNumber: 9,
        sourceId: 'jalalayn',
      );
      await cubit.loadTafsir(
        surahNumber: 57,
        ayahNumber: 9,
        sourceId: 'ibn_kathir',
      );
      expect(cubit.state.tafsirEntries.last.id, startsWith('ibn_kathir'));

      await pumpApp(tester, const Locale('ar'));
      await openReaderFromActionRow(tester);

      expect(tester.takeException(), isNull);
      expect(find.byType(TafsirReaderSheet), findsOneWidget);
      // Arabic app locale defaults to Jalalayn: its text must be shown...
      expect(find.textContaining('TEXT-jalalayn'), findsWidgets);
      // ...and the later-loaded English entry must not leak in.
      expect(find.textContaining('TEXT-ibn_kathir'), findsNothing);
    },
  );

  testWidgets('English app locale defaults to Ibn Kathir', (tester) async {
    await pumpApp(tester, const Locale('en'));
    await openReaderFromActionRow(tester);

    expect(tester.takeException(), isNull);
    expect(find.byType(TafsirReaderSheet), findsOneWidget);
    expect(find.textContaining('TEXT-ibn_kathir'), findsWidgets);
    expect(find.textContaining('TEXT-jalalayn'), findsNothing);
  });

  testWidgets('Arabic app shows only Arabic source chips', (tester) async {
    await pumpApp(tester, const Locale('ar'));
    await openReaderFromActionRow(tester);

    expect(tester.takeException(), isNull);
    expect(find.byType(TafsirReaderSheet), findsOneWidget);
    expect(find.text('التفسير الميسر'), findsOneWidget);
    expect(find.text('تفسير ابن كثير'), findsOneWidget);
    expect(find.text('Tafsir Ibn Kathir'), findsNothing);
  });

  testWidgets('English app hides the selector for its single source', (
    tester,
  ) async {
    await pumpApp(tester, const Locale('en'));
    await openReaderFromActionRow(tester);

    expect(tester.takeException(), isNull);
    expect(find.byType(TafsirReaderSheet), findsOneWidget);
    // No source chips at all: Ibn Kathir is the only English tafsir.
    expect(find.text('تفسير الجلالين'), findsNothing);
    expect(find.text('Tafsir Ibn Kathir'), findsNothing);
    expect(find.textContaining('TEXT-ibn_kathir'), findsWidgets);
  });

  testWidgets('resolves the default without any localization setup', (
    tester,
  ) async {
    // The lookup must work under a plain MaterialApp: no EasyLocalization
    // ancestor, no asset loading, no order-dependent state.
    String? resolvedAr;
    String? resolvedEn;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ar'),
        supportedLocales: const [Locale('en'), Locale('ar')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: Builder(
          builder: (context) {
            resolvedAr = defaultTafsirSourceId(context);
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        supportedLocales: const [Locale('en'), Locale('ar')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: Builder(
          builder: (context) {
            resolvedEn = defaultTafsirSourceId(context);
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(resolvedAr, 'jalalayn');
    expect(resolvedEn, 'ibn_kathir');
  });

  testWidgets('closing the reader mid-load never throws on completion', (
    tester,
  ) async {
    // Regression: "Cannot emit new states after calling close" when the sheet
    // was dismissed while its fetch was still in flight.
    final gated = _GatedTafsirRepository();
    await getIt.unregister<AyahActionsCubit>();
    getIt.registerFactory<AyahActionsCubit>(
      () => AyahActionsCubit(GetTafsirUseCase(gated)),
    );

    await pumpApp(tester, const Locale('ar'));
    await openReaderFromActionRow(tester);
    expect(find.byType(TafsirReaderSheet), findsOneWidget);

    // Dismiss the reader while the fetch is still pending (as if the user
    // swiped it away), then let the pop animation (and cubit disposal)
    // finish.
    Navigator.of(tester.element(find.byType(TafsirReaderSheet))).pop();
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }
    expect(find.byType(TafsirReaderSheet), findsNothing);

    gated.complete();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 100));

    expect(tester.takeException(), isNull);
  });
}

/// Repository whose fetch only finishes when the test allows it.
class _GatedTafsirRepository implements TafsirRepository {
  final _completer = Completer<TafsirEntry>();

  void complete() {
    if (!_completer.isCompleted) {
      _completer.complete(
        const TafsirEntry(
          id: 'jalalayn-57:9',
          surahNumber: 57,
          ayahNumber: 9,
          sourceName: 'jalalayn',
          sourceLanguage: 'ar',
          text: 'TEXT-jalalayn distinctive body',
        ),
      );
    }
  }

  @override
  Future<TafsirEntry> getTafsir({
    required int surahNumber,
    required int ayahNumber,
    required String sourceId,
  }) {
    return _completer.future;
  }

  @override
  Future<List<TafsirEntry>> getMultipleTafsir({
    required int surahNumber,
    required int ayahNumber,
    required List<String> sourceIds,
  }) async {
    return [
      await getTafsir(
        surahNumber: surahNumber,
        ayahNumber: ayahNumber,
        sourceId: sourceIds.first,
      ),
    ];
  }
}
