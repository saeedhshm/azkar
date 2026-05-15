import 'package:equatable/equatable.dart';

import '../../domain/entities/quran_selected_ayah.dart';

class QuranAyahSelectionState extends Equatable {
  const QuranAyahSelectionState({this.selectedAyah});

  final QuranSelectedAyah? selectedAyah;

  QuranAyahSelectionState copyWith({Object? selectedAyah = _sentinel}) {
    return QuranAyahSelectionState(
      selectedAyah: selectedAyah == _sentinel
          ? this.selectedAyah
          : selectedAyah as QuranSelectedAyah?,
    );
  }

  @override
  List<Object?> get props => [selectedAyah];
}

const _sentinel = Object();
