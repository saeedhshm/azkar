import 'dart:ui' as ui;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../domain/entities/quran_search_result.dart';
import '../../services/quran_search_text_utils.dart';

class QuranSearchResults extends StatelessWidget {
  const QuranSearchResults({
    super.key,
    required this.results,
    required this.onResultTap,
  });

  final List<QuranSearchResult> results;
  final ValueChanged<QuranSearchResult> onResultTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final gold = theme.colorScheme.primary;

    if (results.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'quran.no_results'.tr(),
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 104),
      itemCount: results.length + 1,
      separatorBuilder: (c, i) =>
          i == 0 ? const SizedBox(height: 10) : const SizedBox(height: 8),
      itemBuilder: (context, index) {
        if (index == 0) {
          return Text(
            '${'quran.search_results'.tr()} (${results.length})',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          );
        }
        final result = results[index - 1];
        return InkWell(
          onTap: () => onResultTap(result),
          borderRadius: BorderRadius.circular(22),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: theme.colorScheme.outlineVariant),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(
                    alpha: theme.brightness == Brightness.dark ? 0.2 : 0.05,
                  ),
                  blurRadius: 14,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(999),
                        color: gold.withValues(alpha: 0.12),
                      ),
                      child: Text(
                        '${result.surah.number}:${result.ayah.numberInSurah}',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: gold,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            '${result.surah.englishName} • ${result.surah.name}',
                            textDirection: ui.TextDirection.ltr,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                  ],
                ),
                const SizedBox(height: 10),
                Directionality(
                  textDirection: ui.TextDirection.rtl,
                  child: result.matchedWord != null
                      ? RichText(
                          text: TextSpan(
                            children: _highlightMatches(
                              original: result.ayah.text,
                              normalizedQuery: result.matchedWord!,
                              baseStyle: theme.textTheme.titleMedium!.copyWith(
                                fontFamily: 'Cairo',
                                height: 1.9,
                                fontWeight: FontWeight.w700,
                                color: theme.colorScheme.onSurface,
                              ),
                              highlightStyle: theme.textTheme.titleMedium!
                                  .copyWith(
                                fontFamily: 'Cairo',
                                height: 1.9,
                                fontWeight: FontWeight.w900,
                                color: gold,
                                backgroundColor: gold.withValues(alpha: 0.15),
                              ),
                            ),
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.right,
                        )
                      : Text(
                          result.ayah.text,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.right,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontFamily: 'Cairo',
                            height: 1.9,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  List<TextSpan> _highlightMatches({
    required String original,
    required String normalizedQuery,
    required TextStyle baseStyle,
    required TextStyle highlightStyle,
  }) {
    final words = original.split(' ');
    final spans = <TextSpan>[];
    for (var i = 0; i < words.length; i++) {
      final word = words[i];
      final normalized = QuranSearchTextUtils.normalize(word);
      final isMatch = normalized.contains(normalizedQuery) ||
          normalizedQuery.contains(normalized);
      if (spans.isNotEmpty) {
        spans.add(TextSpan(text: ' ', style: baseStyle));
      }
      spans.add(TextSpan(
        text: word,
        style: isMatch ? highlightStyle : baseStyle,
      ));
    }
    return spans;
  }
}
