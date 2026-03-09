import 'package:equatable/equatable.dart';

import '../../domain/entities/adhkar.dart';

enum AdhkarStatus { initial, loading, success, failure }

class AdhkarState extends Equatable {
  const AdhkarState({
    this.status = AdhkarStatus.initial,
    this.items = const <Adhkar>[],
    this.favoriteIds = const <int>{},
    this.remainingByAdhkarId = const <int, int>{},
    this.query = '',
    this.errorMessage,
  });

  final AdhkarStatus status;
  final List<Adhkar> items;
  final Set<int> favoriteIds;
  final Map<int, int> remainingByAdhkarId;
  final String query;
  final String? errorMessage;

  AdhkarState copyWith({
    AdhkarStatus? status,
    List<Adhkar>? items,
    Set<int>? favoriteIds,
    Map<int, int>? remainingByAdhkarId,
    String? query,
    String? errorMessage,
  }) {
    return AdhkarState(
      status: status ?? this.status,
      items: items ?? this.items,
      favoriteIds: favoriteIds ?? this.favoriteIds,
      remainingByAdhkarId: remainingByAdhkarId ?? this.remainingByAdhkarId,
      query: query ?? this.query,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    status,
    items,
    favoriteIds,
    remainingByAdhkarId,
    query,
    errorMessage,
  ];
}
