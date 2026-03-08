import 'package:equatable/equatable.dart';

class ReaderProgress extends Equatable {
  const ReaderProgress({required this.index, required this.remainingCount});

  final int index;
  final int remainingCount;

  @override
  List<Object> get props => [index, remainingCount];
}
