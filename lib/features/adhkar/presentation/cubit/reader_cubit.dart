import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/repositories/adhkar_repository.dart';
import 'reader_state.dart';

class ReaderCubit extends Cubit<ReaderState> {
  ReaderCubit(this._repository) : super(const ReaderState());

  final AdhkarRepository _repository;

  String _categoryKey = 'morning_adhkar';
  Map<int, int> _remainingByAdhkarId = <int, int>{};

  Future<void> initialize({
    required String categoryKey,
    int startIndex = 0,
    int? initialAdhkarId,
  }) async {
    emit(state.copyWith(status: ReaderStatus.loading));
    _categoryKey = categoryKey;

    try {
      final items = await _repository.getAdhkarByCategory(categoryKey);
      if (items.isEmpty) {
        emit(
          state.copyWith(
            status: ReaderStatus.failure,
            errorMessage: 'No adhkar found in this category.',
          ),
        );
        return;
      }

      int resolvedIndex = startIndex.clamp(0, items.length - 1);
      if (initialAdhkarId != null) {
        final byId = items.indexWhere((item) => item.id == initialAdhkarId);
        if (byId != -1) {
          resolvedIndex = byId;
        }
      }

      final savedProgress = await _repository.getReaderProgress(categoryKey);
      if (savedProgress != null && initialAdhkarId == null && startIndex == 0) {
        resolvedIndex = savedProgress.index.clamp(0, items.length - 1);
      }

      final favoriteIds = await _repository.getFavoriteIds();
      _remainingByAdhkarId = await _repository.getAdhkarProgressMap();

      final savedProgressApplies =
          savedProgress != null &&
          savedProgress.index == resolvedIndex &&
          savedProgress.remainingCount > 0;

      final currentId = items[resolvedIndex].id;
      final storedRemaining = _remainingByAdhkarId[currentId];
      final remainingCount =
          storedRemaining ??
          (savedProgressApplies
              ? savedProgress.remainingCount
              : items[resolvedIndex].count);

      final nextState = state.copyWith(
        status: ReaderStatus.loaded,
        items: items,
        currentIndex: resolvedIndex,
        remainingCount: remainingCount,
        favoriteIds: favoriteIds,
      );

      emit(nextState);
      await _persistProgress(nextState);
    } catch (error) {
      emit(
        state.copyWith(
          status: ReaderStatus.failure,
          errorMessage: error.toString(),
        ),
      );
    }
  }

  Future<void> decrementCounter() async {
    if (state.status != ReaderStatus.loaded || state.remainingCount <= 0) {
      return;
    }

    await HapticFeedback.mediumImpact();

    final updatedRemaining = state.remainingCount - 1;
    final hasNext = state.currentIndex < state.items.length - 1;
    final currentAdhkarId = state.items[state.currentIndex].id;

    _remainingByAdhkarId[currentAdhkarId] = updatedRemaining;
    await _repository.saveAdhkarRemainingCount(
      adhkarId: currentAdhkarId,
      remainingCount: updatedRemaining,
    );

    final nextIndex = state.currentIndex + 1;
    final nextRemaining = hasNext
        ? _remainingByAdhkarId[state.items[nextIndex].id] ??
              state.items[nextIndex].count
        : 0;

    final nextState = updatedRemaining == 0 && hasNext
        ? state.copyWith(currentIndex: nextIndex, remainingCount: nextRemaining)
        : state.copyWith(remainingCount: updatedRemaining);

    emit(nextState);
    await _persistProgress(nextState);
  }

  Future<void> next() async {
    if (state.status != ReaderStatus.loaded ||
        state.currentIndex >= state.items.length - 1) {
      return;
    }

    final index = state.currentIndex + 1;
    final nextState = state.copyWith(
      currentIndex: index,
      remainingCount:
          _remainingByAdhkarId[state.items[index].id] ??
          state.items[index].count,
    );

    emit(nextState);
    await _persistProgress(nextState);
  }

  Future<void> previous() async {
    if (state.status != ReaderStatus.loaded || state.currentIndex <= 0) {
      return;
    }

    final index = state.currentIndex - 1;
    final nextState = state.copyWith(
      currentIndex: index,
      remainingCount:
          _remainingByAdhkarId[state.items[index].id] ??
          state.items[index].count,
    );

    emit(nextState);
    await _persistProgress(nextState);
  }

  Future<void> toggleFavorite() async {
    final current = state.currentAdhkar;
    if (current == null) {
      return;
    }

    await _repository.toggleFavorite(current.id);
    final favoriteIds = await _repository.getFavoriteIds();
    emit(state.copyWith(favoriteIds: favoriteIds));
  }

  Future<void> _persistProgress(ReaderState currentState) {
    return _repository.saveReaderProgress(
      categoryKey: _categoryKey,
      index: currentState.currentIndex,
      remainingCount: currentState.remainingCount,
    );
  }
}
