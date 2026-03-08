import 'package:equatable/equatable.dart';

import '../../domain/entities/adhkar.dart';

enum FavoritesStatus { initial, loading, success, failure }

class FavoritesState extends Equatable {
  const FavoritesState({
    this.status = FavoritesStatus.initial,
    this.items = const <Adhkar>[],
    this.errorMessage,
  });

  final FavoritesStatus status;
  final List<Adhkar> items;
  final String? errorMessage;

  FavoritesState copyWith({
    FavoritesStatus? status,
    List<Adhkar>? items,
    String? errorMessage,
  }) {
    return FavoritesState(
      status: status ?? this.status,
      items: items ?? this.items,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, items, errorMessage];
}
