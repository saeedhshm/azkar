import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'dart:ui' as ui;

import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/quran_surah.dart';

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
  String _query = '';
  int? _selectedSurah;

  @override
  void initState() {
    super.initState();
    _selectedSurah = widget.currentSurahNumber;
  }

  @override
  void dispose() {
    _queryController.dispose();
    _ayahController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = AppThemeColors.of(context);
    final filtered = widget.surahs
        .where((surah) {
          final q = _query.trim().toLowerCase();
          if (q.isEmpty) {
            return true;
          }
          return surah.name.contains(q) ||
              surah.englishName.toLowerCase().contains(q) ||
              surah.number.toString() == q;
        })
        .toList(growable: false);

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.82,
      minChildSize: 0.45,
      maxChildSize: 0.92,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: colors.cardSurface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
            border: Border(top: BorderSide(color: colors.softBorder)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: colors.mutedText.withValues(alpha: 0.28),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'quran.select_surah'.tr(),
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                      textAlign: TextAlign.center,
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
                child: ListView.separated(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 22),
                  itemCount: filtered.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final surah = filtered[index];
                    final selected = surah.number == widget.currentSurahNumber;
                    return _SurahRow(
                      surah: surah,
                      selected: selected,
                      onTap: () {
                        Navigator.pop(
                          context,
                          QuranSurahSelection(surahNumber: surah.number),
                        );
                      },
                      onSelected: () =>
                          setState(() => _selectedSurah = surah.number),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
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
    final colors = AppThemeColors.of(context);
    final gold = colors.accentColor ?? colors.countdownText;

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
              : colors.cardSurfaceTint.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? gold.withValues(alpha: 0.5) : colors.softBorder,
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
                  Text(
                    '${surah.englishNameTranslation} • ${surah.ayahCount} ${'quran.ayahs'.tr()}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.mutedText,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(
              surah.name,
              textDirection: ui.TextDirection.rtl,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w900,
                color: colors.secondaryText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
