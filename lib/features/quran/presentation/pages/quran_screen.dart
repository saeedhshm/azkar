import 'package:flutter/material.dart';

import 'quran_reader_screen.dart';

class QuranScreen extends StatelessWidget {
  const QuranScreen({super.key, this.initialPageNumber});

  final int? initialPageNumber;

  @override
  Widget build(BuildContext context) {
    return QuranReaderScreen(initialPageNumber: initialPageNumber);
  }
}
