import 'package:flutter_test/flutter_test.dart';
import 'package:azkar/features/quran/actions/presentation/cubit/ayah_actions_state.dart';

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
  });
}
