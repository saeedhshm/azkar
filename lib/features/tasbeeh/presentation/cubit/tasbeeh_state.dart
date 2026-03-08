import 'package:equatable/equatable.dart';

enum TasbeehStatus { initial, loading, ready }

class TasbeehState extends Equatable {
  const TasbeehState({this.status = TasbeehStatus.initial, this.count = 0});

  final TasbeehStatus status;
  final int count;

  TasbeehState copyWith({TasbeehStatus? status, int? count}) {
    return TasbeehState(
      status: status ?? this.status,
      count: count ?? this.count,
    );
  }

  @override
  List<Object> get props => [status, count];
}
