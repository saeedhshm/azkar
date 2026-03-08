import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/repositories/adhkar_repository.dart';
import 'favorites_state.dart';

class FavoritesCubit extends Cubit<FavoritesState> {
  FavoritesCubit(this._repository) : super(const FavoritesState());

  final AdhkarRepository _repository;

  Future<void> loadFavorites() async {
    emit(state.copyWith(status: FavoritesStatus.loading));

    try {
      final items = await _repository.getFavorites();
      emit(state.copyWith(status: FavoritesStatus.success, items: items));
    } catch (error) {
      emit(
        state.copyWith(
          status: FavoritesStatus.failure,
          errorMessage: error.toString(),
        ),
      );
    }
  }

  Future<void> toggleFavorite(int adhkarId) async {
    await _repository.toggleFavorite(adhkarId);
    await loadFavorites();
  }
}
