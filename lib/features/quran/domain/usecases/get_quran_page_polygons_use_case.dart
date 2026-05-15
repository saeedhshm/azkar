import '../entities/quran_page.dart';
import '../repositories/quran_polygon_repository.dart';

class GetQuranPagePolygonsUseCase {
  const GetQuranPagePolygonsUseCase(this._repository);

  final QuranPolygonRepository _repository;

  Future<QuranPage> call(int pageNumber) {
    return _repository.getPagePolygons(pageNumber);
  }
}
