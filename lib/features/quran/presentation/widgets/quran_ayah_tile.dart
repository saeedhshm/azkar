import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/quran_ayah.dart';

class QuranAyahTile extends StatelessWidget {
  const QuranAyahTile({
    super.key,
    required this.ayah,
    required this.selected,
    required this.onTap,
  });

  final QuranAyah ayah;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = AppThemeColors.of(context);
    final gold = colors.accentColor ?? colors.countdownText;
    final isDark = theme.brightness == Brightness.dark;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      margin: const EdgeInsets.symmetric(vertical: 5),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: selected
            ? gold.withValues(alpha: isDark ? 0.16 : 0.18)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: selected ? gold.withValues(alpha: 0.56) : Colors.transparent,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(text: ayah.text),
                const TextSpan(text: '  '),
                WidgetSpan(
                  alignment: PlaceholderAlignment.middle,
                  child: _VerseMarker(
                    number: ayah.numberInSurah,
                    selected: selected,
                  ),
                ),
              ],
            ),
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontFamily: 'Cairo',
              height: 2.05,
              fontWeight: FontWeight.w700,
              fontSize: 25,
              color: selected
                  ? colors.countdownText
                  : theme.colorScheme.onSurface,
            ),
          ),
        ),
      ),
    );
  }
}

class _VerseMarker extends StatelessWidget {
  const _VerseMarker({required this.number, required this.selected});

  final int number;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final colors = AppThemeColors.of(context);
    final gold = colors.accentColor ?? colors.countdownText;

    return Container(
      width: 28,
      height: 28,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: gold.withValues(alpha: 0.72)),
        color: selected ? gold.withValues(alpha: 0.2) : Colors.transparent,
      ),
      child: Text(
        '$number',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: gold,
          fontWeight: FontWeight.w900,
          fontSize: 10,
        ),
      ),
    );
  }
}
