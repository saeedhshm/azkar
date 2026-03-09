import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/adhkar.dart';
import '../../domain/repositories/adhkar_repository.dart';
import '../../domain/usecases/get_adhkar_by_category.dart';
import '../../domain/usecases/search_adhkar.dart';
import 'adhkar_state.dart';

class AdhkarCubit extends Cubit<AdhkarState> {
  AdhkarCubit({
    required GetAdhkarByCategoryUseCase getAdhkarByCategoryUseCase,
    required SearchAdhkarUseCase searchAdhkarUseCase,
    required AdhkarRepository repository,
  }) : _getAdhkarByCategoryUseCase = getAdhkarByCategoryUseCase,
       _searchAdhkarUseCase = searchAdhkarUseCase,
       _repository = repository,
       super(const AdhkarState());

  final GetAdhkarByCategoryUseCase _getAdhkarByCategoryUseCase;
  final SearchAdhkarUseCase _searchAdhkarUseCase;
  final AdhkarRepository _repository;

  String _categoryKey = 'morning_adhkar';
  List<Adhkar> _baseItems = const <Adhkar>[];

  Future<void> loadCategory(String categoryKey) async {
    emit(state.copyWith(status: AdhkarStatus.loading));
    _categoryKey = categoryKey;

    try {
      _baseItems = await _getAdhkarByCategoryUseCase(categoryKey);
      final favoriteIds = await _repository.getFavoriteIds();
      final remainingByAdhkarId = await _repository.getAdhkarProgressMap();

      emit(
        state.copyWith(
          status: AdhkarStatus.success,
          items: _baseItems,
          favoriteIds: favoriteIds,
          remainingByAdhkarId: remainingByAdhkarId,
          query: '',
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: AdhkarStatus.failure,
          errorMessage: error.toString(),
        ),
      );
    }
  }

  Future<void> search(String query) async {
    if (state.status != AdhkarStatus.success) {
      return;
    }

    if (query.trim().isEmpty) {
      emit(state.copyWith(items: _baseItems, query: ''));
      return;
    }

    final filtered = await _searchAdhkarUseCase(query, category: _categoryKey);
    emit(state.copyWith(items: filtered, query: query));
  }

  Future<void> toggleFavorite(int adhkarId) async {
    await _repository.toggleFavorite(adhkarId);
    final favoriteIds = await _repository.getFavoriteIds();
    emit(state.copyWith(favoriteIds: favoriteIds));
  }
}
