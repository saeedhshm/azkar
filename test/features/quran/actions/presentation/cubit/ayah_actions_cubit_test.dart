import 'dart:async';

import 'package:azkar/features/quran/actions/presentation/cubit/ayah_actions_cubit.dart';
import 'package:azkar/features/quran/actions/presentation/cubit/ayah_actions_state.dart';
import 'package:azkar/features/quran/tafsir/domain/entities/tafsir_entry.dart';
import 'package:azkar/features/quran/tafsir/domain/repositories/tafsir_repository.dart';
import 'package:azkar/features/quran/tafsir/domain/usecases/get_tafsir_use_case.dart';
import 'package:flutter_test/flutter_test.dart';

class _RecordingTafsirRepository implements TafsirRepository {
  final List<({int surah, int ayah, String source})> requests = [];
  bool shouldFail = true;

  @override
  Future<TafsirEntry> getTafsir({
    required int surahNumber,
    required int ayahNumber,
    required String sourceId,
  }) async {
    requests.add((surah: surahNumber, ayah: ayahNumber, source: sourceId));

    if (shouldFail) {
      throw StateError('network unavailable');
    }

    return TafsirEntry(
      id: '$sourceId-$surahNumber:$ayahNumber',
      surahNumber: surahNumber,
      ayahNumber: ayahNumber,
      sourceName: sourceId,
      sourceLanguage: 'ar',
      text: 'Tafsir text for $surahNumber:$ayahNumber',
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
  group('AyahActionsCubit.loadTafsir', () {
    late _RecordingTafsirRepository repository;
    late AyahActionsCubit cubit;

    setUp(() {
      repository = _RecordingTafsirRepository();
      cubit = AyahActionsCubit(GetTafsirUseCase(repository));
    });

    tearDown(() async {
      await cubit.close();
    });

    test('reports an error and records the failing request', () async {
      await cubit.loadTafsir(surahNumber: 2, ayahNumber: 255, sourceId: 'ibn_kathir');

      expect(cubit.state.status, AyahActionStatus.tafsirError);
      expect(cubit.state.errorMessage, contains('network unavailable'));
      expect(repository.requests, [
        (surah: 2, ayah: 255, source: 'ibn_kathir'),
      ]);
    });

    test('a retry with the same arguments can succeed', () async {
      await cubit.loadTafsir(surahNumber: 2, ayahNumber: 255, sourceId: 'ibn_kathir');
      expect(cubit.state.status, AyahActionStatus.tafsirError);

      repository.shouldFail = false;
      await cubit.loadTafsir(surahNumber: 2, ayahNumber: 255, sourceId: 'ibn_kathir');

      expect(cubit.state.status, AyahActionStatus.tafsirLoaded);
      expect(cubit.state.hasTafsir, isTrue);
      expect(cubit.state.tafsirEntries.single.surahNumber, 2);
      expect(cubit.state.tafsirEntries.single.ayahNumber, 255);
      expect(repository.requests, hasLength(2));
      expect(repository.requests.last.source, 'ibn_kathir');
    });

    test('never requests an invalid surah or ayah', () async {
      await cubit.loadTafsir(surahNumber: 114, ayahNumber: 6, sourceId: 'jalalayn');

      for (final request in repository.requests) {
        expect(request.surah, inInclusiveRange(1, 114));
        expect(request.ayah, isNot(0));
        expect(request.source, isNotEmpty);
      }
    });

    test('loadTafsirSource skips an already loaded source', () async {
      repository.shouldFail = false;

      await cubit.loadTafsirSource(surahNumber: 1, ayahNumber: 1, sourceId: 'jalalayn');
      expect(repository.requests, hasLength(1));

      await cubit.loadTafsirSource(surahNumber: 1, ayahNumber: 1, sourceId: 'jalalayn');
      expect(repository.requests, hasLength(1));
    });

    test('loadTafsirSource loads a different source', () async {
      repository.shouldFail = false;

      await cubit.loadTafsirSource(surahNumber: 1, ayahNumber: 1, sourceId: 'jalalayn');
      await cubit.loadTafsirSource(surahNumber: 1, ayahNumber: 1, sourceId: 'ibn_kathir');

      expect(repository.requests.map((r) => r.source), ['jalalayn', 'ibn_kathir']);
      expect(cubit.state.tafsirEntries, hasLength(2));
    });

    group('close during flight', () {
      late _GatedTafsirRepository gated;
      late AyahActionsCubit gatedCubit;

      setUp(() {
        gated = _GatedTafsirRepository();
        gatedCubit = AyahActionsCubit(GetTafsirUseCase(gated));
      });

      tearDown(() async {
        gated.complete();
        await gatedCubit.close();
      });

      test('completing fetch after close does not throw', () async {
        // Regression: closing the sheet (pop) while a fetch was in flight
        // crashed with "Cannot emit new states after calling close" once the
        // fetch finished.
        final pending = gatedCubit.loadTafsir(
          surahNumber: 2,
          ayahNumber: 255,
          sourceId: 'jalalayn',
        );
        await gatedCubit.close();
        gated.complete();

        await pending;
      });

      test('failing fetch after close does not throw', () async {
        final pending = gatedCubit.loadTafsir(
          surahNumber: 2,
          ayahNumber: 255,
          sourceId: 'jalalayn',
        );
        await gatedCubit.close();
        gated.completeError(StateError('network unavailable'));

        await pending;
      });

      test('calling loadTafsir on a closed cubit is a no-op', () async {
        await gatedCubit.close();

        await gatedCubit.loadTafsir(
          surahNumber: 2,
          ayahNumber: 255,
          sourceId: 'jalalayn',
        );

        expect(gated.requested, isFalse);
      });
    });
  });
}

/// Repository whose fetch only finishes when the test allows it.
class _GatedTafsirRepository implements TafsirRepository {
  final _completer = Completer<TafsirEntry>();
  bool requested = false;

  void complete() {
    if (!_completer.isCompleted) {
      _completer.complete(
        const TafsirEntry(
          id: 'jalalayn-2:255',
          surahNumber: 2,
          ayahNumber: 255,
          sourceName: 'jalalayn',
          sourceLanguage: 'ar',
          text: 'text',
        ),
      );
    }
  }

  void completeError(Object error) {
    if (!_completer.isCompleted) {
      _completer.completeError(error);
    }
  }

  @override
  Future<TafsirEntry> getTafsir({
    required int surahNumber,
    required int ayahNumber,
    required String sourceId,
  }) {
    requested = true;
    return _completer.future;
  }

  @override
  Future<List<TafsirEntry>> getMultipleTafsir({
    required int surahNumber,
    required int ayahNumber,
    required List<String> sourceIds,
  }) async {
    return [await getTafsir(surahNumber: surahNumber, ayahNumber: ayahNumber, sourceId: sourceIds.first)];
  }
}
