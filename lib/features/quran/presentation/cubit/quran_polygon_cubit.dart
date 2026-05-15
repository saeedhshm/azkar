import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/get_quran_page_polygons_use_case.dart';
import '../../domain/repositories/quran_polygon_repository.dart';
import '../../services/quran_polygon_file_cache_service.dart';
import 'quran_polygon_state.dart';

class QuranPolygonCubit extends Cubit<QuranPolygonState> {
  QuranPolygonCubit(this._getPagePolygons, this._repository)
    : super(const QuranPolygonState.initial());

  final GetQuranPagePolygonsUseCase _getPagePolygons;
  final QuranPolygonRepository _repository;

  Future<void> loadPage(int pageNumber) async {
    final safePage = pageNumber
        .clamp(
          QuranPolygonFileCacheService.firstPage,
          QuranPolygonFileCacheService.lastPage,
        )
        .toInt();

    final cached = _repository.getCachedPagePolygons(safePage);
    if (cached != null) {
      emit(
        state.copyWith(
          status: QuranPolygonStatus.loaded,
          pageNumber: safePage,
          page: cached,
          errorMessage: null,
        ),
      );
      _repository.warmUpWindow(safePage, radius: 1);
      return;
    }

    emit(
      state.copyWith(
        status: QuranPolygonStatus.loading,
        pageNumber: safePage,
        errorMessage: null,
      ),
    );

    try {
      final page = await _getPagePolygons(safePage);
      emit(
        state.copyWith(
          status: QuranPolygonStatus.loaded,
          pageNumber: safePage,
          page: page,
          errorMessage: null,
        ),
      );
      _repository.warmUpWindow(safePage, radius: 1);
    } catch (error) {
      emit(
        state.copyWith(
          status: QuranPolygonStatus.failure,
          pageNumber: safePage,
          errorMessage: error.toString(),
        ),
      );
    }
  }

  void highlightPolygon(String? polygonId) {
    emit(state.copyWith(highlightedPolygonId: polygonId));
  }

  void clearHighlight() {
    emit(state.copyWith(highlightedPolygonId: null));
  }
}
