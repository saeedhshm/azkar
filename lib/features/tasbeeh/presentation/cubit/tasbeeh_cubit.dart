import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/repositories/tasbeeh_repository.dart';
import 'tasbeeh_state.dart';

class TasbeehCubit extends Cubit<TasbeehState> {
  TasbeehCubit(this._repository) : super(const TasbeehState());

  final TasbeehRepository _repository;

  Future<void> load() async {
    emit(state.copyWith(status: TasbeehStatus.loading));
    final count = await _repository.getCount();
    emit(state.copyWith(status: TasbeehStatus.ready, count: count));
  }

  Future<void> increment() async {
    final next = state.count + 1;
    emit(state.copyWith(count: next));
    await HapticFeedback.selectionClick();
    await _repository.saveCount(next);
  }

  Future<void> reset() async {
    emit(state.copyWith(count: 0));
    await _repository.reset();
  }
}
