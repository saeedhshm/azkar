import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/quran_selected_ayah.dart';
import 'quran_ayah_selection_state.dart';

class QuranAyahSelectionCubit extends Cubit<QuranAyahSelectionState> {
  QuranAyahSelectionCubit() : super(const QuranAyahSelectionState());

  void selectAyah(QuranSelectedAyah ayah) {
    emit(state.copyWith(selectedAyah: ayah));
  }

  void clearSelection() {
    emit(state.copyWith(selectedAyah: null));
  }
}
