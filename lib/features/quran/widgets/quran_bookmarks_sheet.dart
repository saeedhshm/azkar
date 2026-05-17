import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/services.dart';

import '../domain/entities/ayah_highlight.dart';
import '../presentation/cubit/quran_cubit.dart';
import '../presentation/cubit/quran_highlight_cubit.dart';
import '../presentation/cubit/quran_highlight_state.dart';
import '../presentation/cubit/quran_state.dart';

class QuranBookmarksSheet extends StatefulWidget {
  const QuranBookmarksSheet({super.key, required this.onNavigate});

  final void Function(
    int pageNumber,
    int surahNumber,
    int ayahNumber,
  ) onNavigate;

  @override
  State<QuranBookmarksSheet> createState() => _QuranBookmarksSheetState();
}

class _QuranBookmarksSheetState extends State<QuranBookmarksSheet> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.bookmark_rounded,
                  color: const Color(0xFF28A745),
                  size: 22,
                ),
                const SizedBox(width: 8),
                Text(
                  'quran.bookmarks_title'.tr(),
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            BlocBuilder<QuranHighlightCubit, QuranHighlightState>(
              builder: (context, state) {
                final bookmarks = state.bookmarkHighlights;
                if (bookmarks.isEmpty) {
                  return _EmptyState(theme: theme);
                }
                return Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: bookmarks.length,
                    separatorBuilder: (c, i) => const SizedBox(height: 4),
                    itemBuilder: (context, index) {
                      final highlight = bookmarks[index];
                      return Dismissible(
                        key: ValueKey(highlight.id),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 16),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.delete_rounded,
                            color: Colors.red,
                          ),
                        ),
                        onDismissed: (_) {
                          HapticFeedback.lightImpact();
                          context
                              .read<QuranHighlightCubit>()
                              .toggleBookmarkHighlight(highlight);
                        },
                        child: _BookmarkTile(
                          highlight: highlight,
                          onTap: () => widget.onNavigate(
                            highlight.pageNumber,
                            highlight.surahNumber,
                            highlight.ayahNumber,
                          ),
                          onDelete: () {
                            HapticFeedback.lightImpact();
                            context
                                .read<QuranHighlightCubit>()
                                .toggleBookmarkHighlight(highlight);
                          },
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.bookmark_border_rounded,
              size: 48,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 12),
            Text(
              'quran.no_bookmarks'.tr(),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BookmarkTile extends StatelessWidget {
  const _BookmarkTile({
    required this.highlight,
    required this.onTap,
    required this.onDelete,
  });

  final AyahHighlight highlight;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFF28A745).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.bookmark_rounded,
                  color: Color(0xFF28A745),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _surahName(context),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${'quran.ayah_number'.tr()} ${highlight.ayahNumber} • ${'quran.page'.tr()} ${highlight.pageNumber}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(
                  Icons.close_rounded,
                  size: 18,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                ),
                onPressed: onDelete,
                splashRadius: 18,
                tooltip: 'quran.remove_bookmark'.tr(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _surahName(BuildContext context) {
    final quranState = context.read<QuranCubit>().state;
    if (quranState.status != QuranStatus.loaded) {
      return '${'quran.surah'.tr()} ${highlight.surahNumber}';
    }
    for (final surah in quranState.surahs) {
      if (surah.number == highlight.surahNumber) {
        return surah.name;
      }
    }
    return '${'quran.surah'.tr()} ${highlight.surahNumber}';
  }
}
