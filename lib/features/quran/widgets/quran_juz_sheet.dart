import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../services/quran_juz_data.dart';

class QuranJuzSheet extends StatelessWidget {
  const QuranJuzSheet({
    super.key,
    required this.currentJuz,
    required this.onJuzSelected,
  });

  final int currentJuz;
  final void Function(int juzNumber, int pageNumber) onJuzSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = AppThemeColors.of(context);
    final juzList = QuranJuzData.all;

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(20),
            ),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                child: Row(
                  children: [
                    Icon(
                      Icons.auto_stories_rounded,
                      color: colors.accentColor ?? colors.countdownText,
                      size: 22,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'quran.juz_index'.tr(),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: (colors.accentColor ?? colors.countdownText)
                            .withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${juzList.length} ${'quran.juz'.tr()}',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colors.accentColor ?? colors.countdownText,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: GridView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.all(12),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 1.2,
                  ),
                  itemCount: juzList.length,
                  itemBuilder: (context, index) {
                    final juz = juzList[index];
                    final isSelected = juz.number == currentJuz;
                    return _JuzTile(
                      juz: juz,
                      isSelected: isSelected,
                      progress: isSelected
                          ? QuranJuzData.juzProgress(
                              QuranJuzData.all
                                  .firstWhere((j) => j.number == currentJuz)
                                  .startPage,
                            )
                          : 0.0,
                      onTap: () {
                        onJuzSelected(juz.number, juz.startPage);
                        Navigator.pop(context);
                      },
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

class _JuzTile extends StatelessWidget {
  const _JuzTile({
    required this.juz,
    required this.isSelected,
    required this.onTap,
    this.progress = 0.0,
  });

  final QuranJuzData juz;
  final bool isSelected;
  final VoidCallback onTap;
  final double progress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = AppThemeColors.of(context);
    final gold = colors.accentColor ?? colors.countdownText;

    return Material(
      color: isSelected
          ? gold.withValues(alpha: 0.15)
          : colors.cardSurface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: isSelected
                ? Border.all(color: gold, width: 1.5)
                : Border.all(color: colors.softBorder.withValues(alpha: 0.5)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected
                      ? gold
                      : colors.softBorder.withValues(alpha: 0.5),
                ),
                child: Center(
                  child: Text(
                    '${juz.number}',
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: isSelected
                          ? Colors.white
                          : colors.secondaryText,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '${'quran.juz'.tr()} ${juz.number}',
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight:
                      isSelected ? FontWeight.w800 : FontWeight.w500,
                  color: isSelected ? gold : colors.secondaryText,
                ),
                textAlign: TextAlign.center,
              ),
              Text(
                '${'quran.page'.tr()} ${juz.startPage}',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colors.mutedText,
                  fontSize: 10,
                ),
              ),
              Text(
                'Surah ${juz.startSurah}:${juz.startAyah}',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colors.mutedText,
                  fontSize: 9,
                ),
              ),
              if (isSelected && progress > 0) ...[
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: colors.softBorder.withValues(alpha: 0.5),
                    valueColor: AlwaysStoppedAnimation<Color>(gold),
                    minHeight: 2,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
