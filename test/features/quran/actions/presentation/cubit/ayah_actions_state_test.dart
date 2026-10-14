import 'package:flutter_test/flutter_test.dart';
import 'package:azkar/features/quran/actions/presentation/cubit/ayah_actions_state.dart';
import 'package:azkar/features/quran/tafsir/domain/entities/tafsir_entry.dart';

void main() {
  group('AyahActionsState', () {
    test('initial state has correct defaults', () {
      const state = AyahActionsState.initial();
      expect(state.status, AyahActionStatus.idle);
      expect(state.tafsirEntries, isEmpty);
      expect(state.activeSourceId, isNull);
      expect(state.errorMessage, isNull);
    });

    test('isLoading returns true when loadingTafsir', () {
      final state = const AyahActionsState.initial().copyWith(
        status: AyahActionStatus.loadingTafsir,
      );
      expect(state.isLoading, isTrue);
    });

    test('isLoading returns false for idle', () {
      const state = AyahActionsState.initial();
      expect(state.isLoading, isFalse);
    });

    test('hasTafsir returns true when entries are present', () {
      final state = const AyahActionsState.initial().copyWith(
        status: AyahActionStatus.tafsirLoaded,
      );
      expect(state.hasTafsir, isFalse);
    });

    test('copyWith updates only specified fields', () {
      const state = AyahActionsState.initial();
      final updated = state.copyWith(
        status: AyahActionStatus.tafsirLoaded,
        errorMessage: null,
      );
      expect(updated.status, AyahActionStatus.tafsirLoaded);
      expect(updated.activeSourceId, isNull);
      expect(updated.tafsirEntries, isEmpty);
    });

    test('copyWith can set errorMessage to null', () {
      final state = const AyahActionsState.initial().copyWith(
        errorMessage: 'some error',
      );
      expect(state.errorMessage, 'some error');

      final cleared = state.copyWith(errorMessage: null);
      expect(cleared.errorMessage, isNull);
    });

    test('copyWith can set activeSourceId to null', () {
      final state = const AyahActionsState.initial().copyWith(
        activeSourceId: 'jalalayn',
      );
      expect(state.activeSourceId, 'jalalayn');

      final cleared = state.copyWith(activeSourceId: null);
      expect(cleared.activeSourceId, isNull);
    });

    test('props are correct', () {
      const state = AyahActionsState.initial();
      expect(state.props.length, 4);
    });

    group('entryForSource', () {
      const jalalayn = TafsirEntry(
        id: 'jalalayn-57:9',
        surahNumber: 57,
        ayahNumber: 9,
        sourceName: 'تفسير الجلالين',
        sourceLanguage: 'ar',
        text: 'arabic text',
      );
      const ibnKathir = TafsirEntry(
        id: 'ibn_kathir-57:9',
        surahNumber: 57,
        ayahNumber: 9,
        sourceName: 'Tafsir Ibn Kathir',
        sourceLanguage: 'en',
        text: 'english text',
      );

      AyahActionsState stateWithBoth() {
        return const AyahActionsState.initial().copyWith(
          status: AyahActionStatus.tafsirLoaded,
          tafsirEntries: [jalalayn, ibnKathir],
        );
      }

      test('returns the entry of the requested source, not the last one', () {
        final state = stateWithBoth();

        expect(state.entryForSource('jalalayn'), jalalayn);
        expect(state.entryForSource('ibn_kathir'), ibnKathir);
      });

      test('returns null when the source has no entry', () {
        final state = stateWithBoth();

        expect(state.entryForSource('muyassar'), isNull);
      });

      test('returns null when there are no entries', () {
        const state = AyahActionsState.initial();

        expect(state.entryForSource('jalalayn'), isNull);
      });
    });
  });
}
