import 'dart:ui' as ui;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/di/service_locator.dart';
import '../../../domain/entities/quran_selected_ayah.dart';
import '../../../tafsir/domain/entities/tafsir_entry.dart';
import '../../../tafsir/presentation/widgets/tafsir_reader_sheet.dart';
import '../cubit/ayah_actions_cubit.dart';
import '../cubit/ayah_actions_state.dart';

class AyahActionsSheet extends StatelessWidget {
  const AyahActionsSheet({
    super.key,
    required this.selectedAyah,
    required this.surahName,
    required this.ayahText,
    required this.onToggleBookmark,
    required this.isBookmarked,
    required this.onPlayAyah,
    required this.isFavoriteReciter,
    required this.onToggleFavoriteReciter,
    this.onCopy,
    this.onShare,
  });

  final QuranSelectedAyah selectedAyah;
  final String surahName;
  final String ayahText;
  final VoidCallback onToggleBookmark;
  final bool isBookmarked;
  final VoidCallback onPlayAyah;
  final bool isFavoriteReciter;
  final VoidCallback onToggleFavoriteReciter;
  final VoidCallback? onCopy;
  final VoidCallback? onShare;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocProvider(
      create: (_) => getIt<AyahActionsCubit>(),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Header(
                surahName: surahName,
                selectedAyah: selectedAyah,
                theme: theme,
                isFavoriteReciter: isFavoriteReciter,
                onToggleFavoriteReciter: onToggleFavoriteReciter,
              ),
              const SizedBox(height: 14),
              _AyahTextField(ayahText: ayahText, theme: theme),
              const SizedBox(height: 16),
              _ActionRow(
                selectedAyah: selectedAyah,
                surahName: surahName,
                ayahText: ayahText,
                isBookmarked: isBookmarked,
                onToggleBookmark: onToggleBookmark,
                onPlayAyah: onPlayAyah,
                onCopy: onCopy,
                onShare: onShare,
              ),
              const SizedBox(height: 12),
              _TafsirPreview(
                selectedAyah: selectedAyah,
                surahName: surahName,
                ayahText: ayahText,
                theme: theme,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.surahName,
    required this.selectedAyah,
    required this.theme,
    required this.isFavoriteReciter,
    required this.onToggleFavoriteReciter,
  });

  final String surahName;
  final QuranSelectedAyah selectedAyah;
  final ThemeData theme;
  final bool isFavoriteReciter;
  final VoidCallback onToggleFavoriteReciter;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(surahName, style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
              const SizedBox(height: 4),
              Text(
                selectedAyah.hasValidAyah
                    ? '${'quran.ayah_number'.tr()} ${selectedAyah.ayahNumber}'
                    : 'quran.ayah_metadata_unavailable'.tr(),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          icon: Icon(
            isFavoriteReciter ? Icons.favorite_rounded : Icons.favorite_outline_rounded,
            color: isFavoriteReciter ? Colors.red : theme.colorScheme.onSurface.withValues(alpha: 0.5),
            size: 22,
          ),
          onPressed: onToggleFavoriteReciter,
          tooltip: 'quran.favorite_reciter'.tr(),
        ),
      ],
    );
  }
}

class _AyahTextField extends StatelessWidget {
  const _AyahTextField({required this.ayahText, required this.theme});

  final String ayahText;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          ayahText,
          textDirection: ui.TextDirection.rtl,
          style: theme.textTheme.bodyLarge?.copyWith(height: 1.7),
        ),
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.selectedAyah,
    required this.surahName,
    required this.ayahText,
    required this.isBookmarked,
    required this.onToggleBookmark,
    required this.onPlayAyah,
    this.onCopy,
    this.onShare,
  });

  final QuranSelectedAyah selectedAyah;
  final String surahName;
  final String ayahText;
  final bool isBookmarked;
  final VoidCallback onToggleBookmark;
  final VoidCallback onPlayAyah;
  final VoidCallback? onCopy;
  final VoidCallback? onShare;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _ActionButton(
          icon: Icons.auto_stories_rounded,
          label: 'quran.tafsir'.tr(),
          color: const Color(0xFF6C63FF),
          onTap: () {
            Navigator.pop(context);
            _openTafsir(context);
          },
        ),
        _ActionButton(
          icon: Icons.copy_rounded,
          label: 'common.copy'.tr(),
          color: const Color(0xFF34C759),
          onTap: onCopy ?? () {
            context.read<AyahActionsCubit>().copyAyahText(ayahText);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('common.copied'.tr()),
                duration: const Duration(seconds: 1),
              ),
            );
          },
        ),
        _ActionButton(
          icon: Icons.share_rounded,
          label: 'common.share'.tr(),
          color: const Color(0xFF007AFF),
          onTap: onShare ?? () => context.read<AyahActionsCubit>().shareAyah(
            ayahText: ayahText,
            surahName: surahName,
            ayahNumber: selectedAyah.ayahNumber,
          ),
        ),
        _ActionButton(
          icon: isBookmarked ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
          label: 'quran.bookmark'.tr(),
          color: const Color(0xFF28A745),
          onTap: onToggleBookmark,
        ),
        _ActionButton(
          icon: Icons.play_circle_rounded,
          label: 'quran.play'.tr(),
          color: const Color(0xFFFF9500),
          onTap: () {
            Navigator.pop(context);
            onPlayAyah();
          },
        ),
      ],
    );
  }

  void _openTafsir(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      showDragHandle: true,
      builder: (_) => TafsirReaderSheet(
        surahNumber: selectedAyah.surahNumber,
        ayahNumber: selectedAyah.ayahNumber,
        surahName: surahName,
        ayahText: ayahText,
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.w600,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TafsirPreview extends StatelessWidget {
  const _TafsirPreview({
    required this.selectedAyah,
    required this.surahName,
    required this.ayahText,
    required this.theme,
  });

  final QuranSelectedAyah selectedAyah;
  final String surahName;
  final String ayahText;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AyahActionsCubit, AyahActionsState>(
      builder: (context, state) {
        if (state.isLoading) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2)),
            ),
          );
        }

        if (state.status == AyahActionStatus.tafsirError) {
          return _TafsirError(
            onRetry: () => context.read<AyahActionsCubit>().loadTafsir(
              surahNumber: selectedAyah.surahNumber,
              ayahNumber: selectedAyah.ayahNumber,
            ),
            theme: theme,
          );
        }

        if (state.status == AyahActionStatus.idle && !state.hasTafsir) {
          return _TafsirPrompt(
            onTap: () => context.read<AyahActionsCubit>().loadTafsir(
              surahNumber: selectedAyah.surahNumber,
              ayahNumber: selectedAyah.ayahNumber,
            ),
            theme: theme,
          );
        }

        if (state.hasTafsir) {
          final entry = state.tafsirEntries.last;
          return _TafsirContent(
            entry: entry,
            onViewMore: () {
              showModalBottomSheet<void>(
                context: context,
                isScrollControlled: true,
                backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                showDragHandle: true,
                builder: (_) => TafsirReaderSheet(
                  surahNumber: selectedAyah.surahNumber,
                  ayahNumber: selectedAyah.ayahNumber,
                  surahName: surahName,
                  ayahText: ayahText,
                ),
              );
            },
          );
        }

        return const SizedBox.shrink();
      },
    );
  }
}

class _TafsirPrompt extends StatelessWidget {
  const _TafsirPrompt({required this.onTap, required this.theme});

  final VoidCallback onTap;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: theme.colorScheme.outlineVariant),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.auto_stories_rounded, size: 18, color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
            const SizedBox(width: 8),
            Text(
              'quran.view_tafsir'.tr(),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TafsirError extends StatelessWidget {
  const _TafsirError({required this.onRetry, required this.theme});

  final VoidCallback onRetry;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline_rounded, size: 18, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Text('quran.tafsir_load_failed'.tr(), style: theme.textTheme.bodySmall),
          const SizedBox(width: 8),
          TextButton(onPressed: onRetry, child: Text('common.retry'.tr())),
        ],
      ),
    );
  }
}

class _TafsirContent extends StatelessWidget {
  const _TafsirContent({
    required this.entry,
    required this.onViewMore,
  });

  final TafsirEntry entry;
  final VoidCallback onViewMore;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onViewMore,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: theme.colorScheme.outlineVariant),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(Icons.auto_stories_rounded, size: 16, color: const Color(0xFF6C63FF)),
                const SizedBox(width: 6),
                Text(
                  entry.sourceName,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: const Color(0xFF6C63FF),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                Text(
                  'quran.view_full'.tr(),
                  style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
                ),
                Icon(Icons.chevron_right, size: 16, color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              entry.text,
              textDirection: entry.sourceLanguage == 'ar' ? ui.TextDirection.rtl : ui.TextDirection.ltr,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}
