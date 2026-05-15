import 'package:equatable/equatable.dart';

import '../../domain/entities/quran_page.dart';

enum QuranPolygonStatus { initial, loading, loaded, failure }

class QuranPolygonState extends Equatable {
  const QuranPolygonState({
    required this.status,
    required this.pageNumber,
    required this.page,
    required this.highlightedPolygonId,
    this.errorMessage,
  });

  const QuranPolygonState.initial()
    : status = QuranPolygonStatus.initial,
      pageNumber = 1,
      page = null,
      highlightedPolygonId = null,
      errorMessage = null;

  final QuranPolygonStatus status;
  final int pageNumber;
  final QuranPage? page;
  final String? highlightedPolygonId;
  final String? errorMessage;

  QuranPolygonState copyWith({
    QuranPolygonStatus? status,
    int? pageNumber,
    Object? page = _sentinel,
    Object? highlightedPolygonId = _sentinel,
    Object? errorMessage = _sentinel,
  }) {
    return QuranPolygonState(
      status: status ?? this.status,
      pageNumber: pageNumber ?? this.pageNumber,
      page: page == _sentinel ? this.page : page as QuranPage?,
      highlightedPolygonId: highlightedPolygonId == _sentinel
          ? this.highlightedPolygonId
          : highlightedPolygonId as String?,
      errorMessage: errorMessage == _sentinel
          ? this.errorMessage
          : errorMessage as String?,
    );
  }

  @override
  List<Object?> get props => [
    status,
    pageNumber,
    page,
    highlightedPolygonId,
    errorMessage,
  ];
}

const _sentinel = Object();
