import 'package:equatable/equatable.dart';

import '../../../tafsir/domain/entities/tafsir_entry.dart';

enum AyahActionStatus { idle, loadingTafsir, tafsirLoaded, tafsirError, executing }

class AyahActionsState extends Equatable {
  const AyahActionsState({
    required this.status,
    this.tafsirEntries = const [],
    this.activeSourceId,
    this.errorMessage,
  });

  const AyahActionsState.initial()
    : status = AyahActionStatus.idle,
      tafsirEntries = const [],
      activeSourceId = null,
      errorMessage = null;

  final AyahActionStatus status;
  final List<TafsirEntry> tafsirEntries;
  final String? activeSourceId;
  final String? errorMessage;

  bool get isLoading => status == AyahActionStatus.loadingTafsir;
  bool get hasTafsir => tafsirEntries.isNotEmpty;

  AyahActionsState copyWith({
    AyahActionStatus? status,
    List<TafsirEntry>? tafsirEntries,
    Object? activeSourceId = _sentinel,
    Object? errorMessage = _sentinel,
  }) {
    return AyahActionsState(
      status: status ?? this.status,
      tafsirEntries: tafsirEntries ?? this.tafsirEntries,
      activeSourceId: activeSourceId == _sentinel
          ? this.activeSourceId
          : activeSourceId as String?,
      errorMessage: errorMessage == _sentinel
          ? this.errorMessage
          : errorMessage as String?,
    );
  }

  @override
  List<Object?> get props => [status, tafsirEntries, activeSourceId, errorMessage];
}

const _sentinel = Object();
