import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:share_plus/share_plus.dart';

import '../../../tafsir/domain/entities/tafsir_entry.dart';
import '../../../tafsir/domain/usecases/get_tafsir_use_case.dart';
import 'ayah_actions_state.dart';

class AyahActionsCubit extends Cubit<AyahActionsState> {
  AyahActionsCubit(this._getTafsir) : super(const AyahActionsState.initial());

  final GetTafsirUseCase _getTafsir;

  Future<void> loadTafsir({
    required int surahNumber,
    required int ayahNumber,
    String sourceId = 'jalalayn',
  }) async {
    // The sheet can be closed while a fetch is still in flight; emitting
    // afterwards throws "Cannot emit new states after calling close".
    if (isClosed) return;
    emit(
      state.copyWith(
        status: AyahActionStatus.loadingTafsir,
        activeSourceId: sourceId,
        errorMessage: null,
      ),
    );

    try {
      final entry = await _getTafsir(
        surahNumber: surahNumber,
        ayahNumber: ayahNumber,
        sourceId: sourceId,
      );
      if (isClosed) return;

      final entries = List<TafsirEntry>.from(state.tafsirEntries);
      entries.removeWhere((e) => e.id.startsWith(sourceId));
      entries.add(entry);

      emit(
        state.copyWith(
          status: AyahActionStatus.tafsirLoaded,
          tafsirEntries: entries,
        ),
      );
    } catch (e) {
      if (isClosed) return;
      emit(
        state.copyWith(
          status: AyahActionStatus.tafsirError,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  Future<void> loadTafsirSource({
    required int surahNumber,
    required int ayahNumber,
    required String sourceId,
  }) async {
    if (state.activeSourceId == sourceId &&
        state.tafsirEntries.any((e) => e.id.startsWith(sourceId))) {
      return;
    }
    await loadTafsir(
      surahNumber: surahNumber,
      ayahNumber: ayahNumber,
      sourceId: sourceId,
    );
  }

  Future<void> copyAyahText(String ayahText) async {
    if (isClosed) return;
    emit(state.copyWith(status: AyahActionStatus.executing));
    await Clipboard.setData(ClipboardData(text: ayahText));
    if (isClosed) return;
    emit(state.copyWith(status: AyahActionStatus.idle));
  }

  Future<void> shareAyah({
    required String ayahText,
    required String surahName,
    required int ayahNumber,
  }) async {
    if (isClosed) return;
    emit(state.copyWith(status: AyahActionStatus.executing));
    final text = '$surahName $ayahNumber: $ayahText';
    await SharePlus.instance.share(ShareParams(text: text));
    if (isClosed) return;
    emit(state.copyWith(status: AyahActionStatus.idle));
  }

  void reset() {
    emit(const AyahActionsState.initial());
  }
}
