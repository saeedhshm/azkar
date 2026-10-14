import 'package:azkar/core/di/service_locator.dart';
import 'package:azkar/features/quran/actions/presentation/cubit/ayah_actions_cubit.dart';
import 'package:azkar/features/quran/actions/presentation/widgets/ayah_actions_sheet.dart';
import 'package:azkar/features/quran/domain/entities/quran_selected_ayah.dart';
import 'package:azkar/features/quran/tafsir/domain/entities/tafsir_entry.dart';
import 'package:azkar/features/quran/tafsir/domain/repositories/tafsir_repository.dart';
import 'package:azkar/features/quran/tafsir/domain/usecases/get_tafsir_use_case.dart';
import 'package:azkar/features/quran/tafsir/presentation/widgets/tafsir_reader_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeTafsirRepository implements TafsirRepository {
  @override
  Future<TafsirEntry> getTafsir({
    required int surahNumber,
    required int ayahNumber,
    required String sourceId,
  }) async {
    return TafsirEntry(
      id: '$sourceId-$surahNumber:$ayahNumber',
      surahNumber: surahNumber,
      ayahNumber: ayahNumber,
      sourceName: sourceId,
      sourceLanguage: 'ar',
      text: 'نص التفسير ' * 50,
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
  setUp(() {
    if (!getIt.isRegistered<AyahActionsCubit>()) {
      getIt.registerFactory<AyahActionsCubit>(
        () => AyahActionsCubit(GetTafsirUseCase(_FakeTafsirRepository())),
      );
    }
  });

  tearDown(() async {
    await getIt.reset();
  });

  Future<void> pumpSheet(
    WidgetTester tester, {
    required String ayahText,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          // Mimic the bounded height of a modal bottom sheet.
          body: SizedBox(
            height: 320,
            child: AyahActionsSheet(
              selectedAyah: const QuranSelectedAyah(
                pageNumber: 42,
                polygonId: 'p1',
                surahNumber: 2,
                ayahNumber: 255,
                lineNumber: 1,
              ),
              surahName: 'سورة البقرة',
              ayahText: ayahText,
              onToggleBookmark: () {},
              isBookmarked: false,
              onPlayAyah: () {},
              isFavoriteReciter: false,
              onToggleFavoriteReciter: () {},
            ),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));
  }

  /// Opens the actions sheet as a real modal route, like the reader does.
  Future<void> pumpSheetAsModalRoute(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
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
                    surahNumber: 2,
                    ayahNumber: 255,
                    lineNumber: 1,
                  ),
                  surahName: 'سورة البقرة',
                  ayahText: 'نص آية قصير',
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

  testWidgets('does not overflow with a very long ayah text', (tester) async {
    // Regression: a long verse overflowed the sheet's Column by ~57px.
    await pumpSheet(tester, ayahText: 'آية الكرسي ونص طويل ' * 60);

    expect(tester.takeException(), isNull);
    expect(find.textContaining('آية الكرسي'), findsWidgets);
  });

  testWidgets('does not overflow when the tafsir preview is loaded', (
    tester,
  ) async {
    await pumpSheet(tester, ayahText: 'نص آية قصير');

    // Load the tafsir preview, which adds a large block below the actions.
    await tester.tap(find.text('quran.view_tafsir'));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 100));

    expect(tester.takeException(), isNull);
  });

  testWidgets('opening tafsir from the action row finds its cubit', (
    tester,
  ) async {
    // Regression: TafsirReaderSheet looked up AyahActionsCubit from the new
    // modal route, which cannot see the opening route's providers, crashing
    // with "Could not find the correct Provider<AyahActionsCubit>".
    await pumpSheetAsModalRoute(tester);

    await tester.tap(find.byIcon(Icons.auto_stories_rounded).first);
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));

    expect(tester.takeException(), isNull);
    expect(find.byType(TafsirReaderSheet), findsOneWidget);
  });

  testWidgets('opening full tafsir from the preview finds its cubit', (
    tester,
  ) async {
    await pumpSheetAsModalRoute(tester);

    // Load the preview first.
    await tester.tap(find.text('quran.view_tafsir'));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 200));

    // Then open the full reader from the preview ("view_full" row).
    await tester.tap(find.text('quran.view_full'));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));

    expect(tester.takeException(), isNull);
    expect(find.byType(TafsirReaderSheet), findsOneWidget);
  });
}
