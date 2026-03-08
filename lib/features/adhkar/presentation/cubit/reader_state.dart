import 'package:equatable/equatable.dart';

import '../../domain/entities/adhkar.dart';

enum ReaderStatus { initial, loading, loaded, failure }

class ReaderState extends Equatable {
  const ReaderState({
    this.status = ReaderStatus.initial,
    this.items = const <Adhkar>[],
    this.currentIndex = 0,
    this.remainingCount = 0,
    this.favoriteIds = const <int>{},
    this.errorMessage,
  });

  final ReaderStatus status;
  final List<Adhkar> items;
  final int currentIndex;
  final int remainingCount;
  final Set<int> favoriteIds;
  final String? errorMessage;

  Adhkar? get currentAdhkar {
    if (items.isEmpty || currentIndex < 0 || currentIndex >= items.length) {
      return null;
    }
    return items[currentIndex];
  }

  ReaderState copyWith({
    ReaderStatus? status,
    List<Adhkar>? items,
    int? currentIndex,
    int? remainingCount,
    Set<int>? favoriteIds,
    String? errorMessage,
  }) {
    return ReaderState(
      status: status ?? this.status,
      items: items ?? this.items,
      currentIndex: currentIndex ?? this.currentIndex,
      remainingCount: remainingCount ?? this.remainingCount,
      favoriteIds: favoriteIds ?? this.favoriteIds,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    status,
    items,
    currentIndex,
    remainingCount,
    favoriteIds,
    errorMessage,
  ];
}
