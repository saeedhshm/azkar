import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'dart:ui' as ui;

import '../../domain/entities/quran_surah.dart';
import '../../services/quran_juz_data.dart';

class QuranSurahSelection {
  const QuranSurahSelection({required this.surahNumber, this.ayahNumber});

  final int surahNumber;
  final int? ayahNumber;
}

class QuranSurahSheet extends StatefulWidget {
  const QuranSurahSheet({
    super.key,
    required this.surahs,
    required this.currentSurahNumber,
  });

  final List<QuranSurah> surahs;
  final int currentSurahNumber;

  @override
  State<QuranSurahSheet> createState() => _QuranSurahSheetState();
}

class _QuranSurahSheetState extends State<QuranSurahSheet> {
  final _queryController = TextEditingController();
  final _ayahController = TextEditingController();
  final _scrollController = ScrollController();
  String _query = '';
  int? _selectedSurah;
  bool _showGrouped = true;

  @override
  void initState() {
    super.initState();
    _selectedSurah = widget.currentSurahNumber;
  }

  @override
  void dispose() {
    _queryController.dispose();
    _ayahController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  List<QuranSurah> get _filtered {
    return widget.surahs.where((surah) {
      final q = _query.trim().toLowerCase();
      if (q.isEmpty) return true;
      return surah.name.contains(q) ||
          surah.englishName.toLowerCase().contains(q) ||
          surah.englishNameTranslation.toLowerCase().contains(q) ||
          surah.number.toString() == q;
    }).toList(growable: false);
  }

  List<QuranSurah> get _makki =>
      _filtered.where((s) => s.revelationType == 'Meccan').toList();
  List<QuranSurah> get _madani =>
      _filtered.where((s) => s.revelationType == 'Medinan').toList();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filtered = _filtered;
    final showGrouped = _showGrouped && _query.isEmpty;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.82,
      minChildSize: 0.45,
      maxChildSize: 0.92,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerLow,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(30),
            ),
            border: Border(top: BorderSide(color: theme.colorScheme.outlineVariant)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.28),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.format_list_bulleted_rounded,
                          color: theme.colorScheme.primary,
                          size: 22,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'quran.select_surah'.tr(),
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const Spacer(),
                        if (_query.isEmpty)
                          IconButton(
                            icon: Icon(
                              showGrouped
                                  ? Icons.list_rounded
                                  : Icons.grid_view_rounded,
                              size: 20,
                            ),
                            onPressed: () =>
                                setState(() => _showGrouped = !_showGrouped),
                            tooltip: showGrouped
                                ? 'quran.list_view'.tr()
                                : 'quran.grid_view'.tr(),
                            splashRadius: 20,
                          ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: _queryController,
                      onChanged: (value) => setState(() => _query = value),
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.search_rounded),
                        hintText: 'quran.search_hint'.tr(),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _ayahController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'quran.ayah_number'.tr(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        FilledButton(
                          onPressed: () {
                            final surahNumber =
                                _selectedSurah ?? widget.currentSurahNumber;
                            final ayahNumber = int.tryParse(
                              _ayahController.text.trim(),
                            );
                            Navigator.pop(
                              context,
                              QuranSurahSelection(
                                surahNumber: surahNumber,
                                ayahNumber: ayahNumber,
                              ),
                            );
                          },
                          child: Text('quran.jump'.tr()),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: showGrouped
                    ? _GroupedSurahList(
                        makki: _makki,
                        madani: _madani,
                        currentSurahNumber: widget.currentSurahNumber,
                        scrollController: scrollController,
                        onTap: (surah) {
                          Navigator.pop(
                            context,
                            QuranSurahSelection(surahNumber: surah.number),
                          );
                        },
                        onSelected: (surah) =>
                            setState(() => _selectedSurah = surah.number),
                      )
                    : Stack(
                        children: [
                          ListView.separated(
                            controller: scrollController,
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 22),
                            itemCount: filtered.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: 8),
                            itemBuilder: (context, index) {
                              final surah = filtered[index];
                              final selected =
                                  surah.number == widget.currentSurahNumber;
                              return _SurahRow(
                                surah: surah,
                                selected: selected,
                                onTap: () {
                                  Navigator.pop(
                                    context,
                                    QuranSurahSelection(
                                      surahNumber: surah.number,
                                    ),
                                  );
                                },
                                onSelected: () => setState(
                                    () => _selectedSurah = surah.number),
                              );
                            },
                          ),
                          if (_query.isEmpty &&
                              widget.surahs == filtered &&
                              !showGrouped)
                            Positioned(
                              right: 4,
                              top: 0,
                              bottom: 0,
                              child: _SurahIndexBar(
                                surahs: widget.surahs,
                                scrollController: scrollController,
                              ),
                            ),
                        ],
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _GroupedSurahList extends StatelessWidget {
  const _GroupedSurahList({
    required this.makki,
    required this.madani,
    required this.currentSurahNumber,
    required this.scrollController,
    required this.onTap,
    required this.onSelected,
  });

  final List<QuranSurah> makki;
  final List<QuranSurah> madani;
  final int currentSurahNumber;
  final ScrollController scrollController;
  final void Function(QuranSurah surah) onTap;
  final void Function(QuranSurah surah) onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 22),
      children: [
        if (makki.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            child: Row(
              children: [
                Icon(Icons.location_city_rounded,
                    size: 16, color: theme.colorScheme.primary),
                const SizedBox(width: 6),
                Text(
                  'quran.makki'.tr(),
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '(${makki.length})',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ),
          ...makki.map(
            (surah) => _SurahRow(
              surah: surah,
              selected: surah.number == currentSurahNumber,
              onTap: () => onTap(surah),
              onSelected: () => onSelected(surah),
            ),
          ),
          const SizedBox(height: 12),
        ],
        if (madani.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            child: Row(
              children: [
                Icon(Icons.mosque_rounded,
                    size: 16, color: const Color(0xFF6C63FF)),
                const SizedBox(width: 6),
                Text(
                  'quran.madani'.tr(),
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: const Color(0xFF6C63FF),
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '(${madani.length})',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ),
          ...madani.map(
            (surah) => _SurahRow(
              surah: surah,
              selected: surah.number == currentSurahNumber,
              onTap: () => onTap(surah),
              onSelected: () => onSelected(surah),
            ),
          ),
        ],
      ],
    );
  }
}

class _SurahIndexBar extends StatelessWidget {
  const _SurahIndexBar({
    required this.surahs,
    required this.scrollController,
  });

  final List<QuranSurah> surahs;
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    final uniqueLetters = <String>{};
    final labels = <String>[];
    for (final surah in surahs) {
      final letter = surah.englishName.isNotEmpty
          ? surah.englishName[0].toUpperCase()
          : '';
      if (letter.isNotEmpty && uniqueLetters.add(letter)) {
        labels.add(letter);
      }
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (final letter in labels)
          GestureDetector(
            onTap: () {
              final index = surahs.indexWhere(
                (s) =>
                    s.englishName.isNotEmpty &&
                    s.englishName[0].toUpperCase() == letter,
              );
              if (index >= 0 && scrollController.hasClients) {
                scrollController.animateTo(
                  index * 72.0,
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOut,
                );
              }
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 1),
              child: Text(
                letter,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _SurahRow extends StatelessWidget {
  const _SurahRow({
    required this.surah,
    required this.selected,
    required this.onTap,
    required this.onSelected,
  });

  final QuranSurah surah;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final gold = theme.colorScheme.primary;
    final juz = QuranJuzData.juzForSurah(surah.number);

    return InkWell(
      onTap: onTap,
      onLongPress: onSelected,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected
              ? gold.withValues(alpha: 0.14)
              : theme.colorScheme.primary.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? gold.withValues(alpha: 0.5)
                : theme.colorScheme.outlineVariant,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: gold.withValues(alpha: 0.14),
              ),
              child: Text(
                '${surah.number}',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: gold,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    surah.englishName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        '${surah.englishNameTranslation} • ${surah.ayahCount} ${'quran.ayahs'.tr()}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                        ),
                      ),
                      if (juz != null) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 4, vertical: 1),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary
                                    .withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Juz ${juz.number}',
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontSize: 9,
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  surah.name,
                  textDirection: ui.TextDirection.rtl,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
                if (surah.revelationType == 'Meccan')
                  Text(
                    'quran.makki'.tr(),
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontSize: 9,
                      color: theme.colorScheme.primary,
                    ),
                  )
                else
                  Text(
                    'quran.madani'.tr(),
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontSize: 9,
                      color: const Color(0xFF6C63FF),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
