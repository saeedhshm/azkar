import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/services.dart';

import '../../../../../core/theme/app_theme.dart';
import '../../domain/entities/reciter.dart';
import '../../data/datasources/quran_audio_player_service.dart';
import '../cubit/quran_audio_cubit.dart';
import '../cubit/quran_audio_state.dart';

class QuranPlaybackControls extends StatelessWidget {
  const QuranPlaybackControls({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = AppThemeColors.of(context);
    final theme = Theme.of(context);

    return BlocBuilder<QuranAudioCubit, QuranAudioState>(
      buildWhen: (previous, current) =>
          previous.playerState != current.playerState ||
          previous.currentSurahNumber != current.currentSurahNumber ||
          previous.currentAyahNumber != current.currentAyahNumber ||
          previous.positionMs != current.positionMs ||
          previous.durationMs != current.durationMs,
      builder: (context, state) {
        if (!state.isActive && state.playerState != AudioPlayerState.loading) {
          return const SizedBox.shrink();
        }

        final isDark = theme.brightness == Brightness.dark;

        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          builder: (context, value, child) {
            return Opacity(
              opacity: value,
              child: Transform.translate(
                offset: Offset(0, 20 * (1 - value)),
                child: child,
              ),
            );
          },
          child: Container(
            decoration: BoxDecoration(
              color: colors.cardSurface.withValues(
                alpha: isDark ? 0.94 : 0.97,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: colors.softBorder),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.34 : 0.1),
                  blurRadius: 22,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _PlaybackProgress(colors: colors),
                const SizedBox(height: 6),
                _PlaybackRow(colors: colors),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _PlaybackProgress extends StatelessWidget {
  const _PlaybackProgress({required this.colors});

  final AppThemeColors colors;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<QuranAudioCubit>().state;

    return LayoutBuilder(
      builder: (context, constraints) {
        return GestureDetector(
          onTapDown: (details) {
            HapticFeedback.lightImpact();
            final ratio = (details.localPosition.dx / constraints.maxWidth)
                .clamp(0.0, 1.0);
            final seekMs = (ratio * state.durationMs).toInt();
            context
                .read<QuranAudioCubit>()
                .seekToPosition(Duration(milliseconds: seekMs));
          },
          child: SizedBox(
            height: 24,
            child: Stack(
              alignment: Alignment.centerLeft,
              children: [
                Container(
                  height: 3,
                  decoration: BoxDecoration(
                    color: colors.softBorder,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                FractionallySizedBox(
                  widthFactor: state.progress.clamp(0.0, 1.0),
                  child: Container(
                    height: 3,
                    decoration: BoxDecoration(
                      color: colors.accentColor ?? colors.countdownText,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Positioned(
                  left: (state.progress.clamp(0.0, 1.0) *
                          constraints.maxWidth) -
                      6,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: colors.accentColor ?? colors.countdownText,
                      border: Border.all(
                        color: colors.cardSurface,
                        width: 2,
                      ),
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
}

class _PlaybackRow extends StatelessWidget {
  const _PlaybackRow({required this.colors});

  final AppThemeColors colors;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<QuranAudioCubit>().state;
    final theme = Theme.of(context);
    final audioCubit = context.read<QuranAudioCubit>();
    final isFavorite = state.reciter != null &&
        audioCubit.isFavoriteReciter(state.reciter!);

    return Row(
      children: [
        SizedBox(
          width: 48,
          child: Text(
            state.currentAyahNumber > 0
                ? 'آية ${state.currentAyahNumber}'
                : _formatDuration(state.positionMs),
            style: theme.textTheme.labelSmall?.copyWith(
              color: colors.secondaryText,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Expanded(
          child: Center(
            child: GestureDetector(
              onTap: () => _showReciterSheet(context),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isFavorite)
                    Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: Icon(
                        Icons.star_rounded,
                        size: 14,
                        color: colors.accentColor ?? colors.countdownText,
                      ),
                    ),
                  Flexible(
                    child: Text(
                      state.currentSurahNumber > 0
                          ? 'سورة ${state.currentSurahNumber}'
                          : '',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colors.mutedText,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        IconButton(
          iconSize: 28,
          onPressed: () {
            HapticFeedback.lightImpact();
            context.read<QuranAudioCubit>().stop();
          },
          icon: Icon(Icons.stop_rounded, color: colors.secondaryText),
          tooltip: 'common.stop'.tr(),
        ),
        IconButton(
          iconSize: 34,
          onPressed: () {
            HapticFeedback.mediumImpact();
            final cubit = context.read<QuranAudioCubit>();
            if (state.isPlaying) {
              cubit.pause();
            } else if (state.isPaused) {
              cubit.resume();
            }
          },
          icon: Icon(
            state.isPlaying
                ? Icons.pause_circle_filled
                : Icons.play_circle_filled,
            color: colors.accentColor ?? colors.countdownText,
          ),
          tooltip: state.isPlaying ? 'common.pause'.tr() : 'common.play'.tr(),
        ),
        IconButton(
          iconSize: 28,
          onPressed: () => _showReciterSheet(context),
          icon: Stack(
            clipBehavior: Clip.none,
            children: [
              Icon(
                Icons.headphones_rounded,
                color: colors.secondaryText,
              ),
              if (isFavorite)
                Positioned(
                  top: -2,
                  right: -2,
                  child: Icon(
                    Icons.star_rounded,
                    size: 10,
                    color: colors.accentColor ?? colors.countdownText,
                  ),
                ),
            ],
          ),
          tooltip: 'quran.reciter'.tr(),
        ),
        SizedBox(
          width: 48,
          child: Text(
            _formatDuration(state.durationMs),
            textAlign: TextAlign.end,
            style: theme.textTheme.labelSmall?.copyWith(
              color: colors.mutedText,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  void _showReciterSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      showDragHandle: true,
      builder: (sheetContext) => const _ReciterSheet(),
    );
  }
}

class _ReciterSheet extends StatelessWidget {
  const _ReciterSheet();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = AppThemeColors.of(context);
    final state = context.watch<QuranAudioCubit>().state;
    final reciters = Reciter.defaults;
    final currentReciter = state.reciter;
    final audioCubit = context.read<QuranAudioCubit>();

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'quran.select_reciter'.tr(),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 12),
            ...reciters.map((reciter) {
              final isSelected = currentReciter?.id == reciter.id;
              final isFav = audioCubit.isFavoriteReciter(reciter);
              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: ListTile(
                  selected: isSelected,
                  selectedTileColor: colors.cardSurface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: isSelected
                        ? BorderSide(
                            color: colors.accentColor ?? colors.countdownText,
                          )
                        : BorderSide.none,
                  ),
                  title: Row(
                    children: [
                      Expanded(
                        child: Text(
                          reciter.name,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight:
                                isSelected ? FontWeight.w800 : FontWeight.w500,
                          ),
                        ),
                      ),
                      IconButton(
                        iconSize: 20,
                        onPressed: () {
                          audioCubit.setFavoriteReciter(reciter);
                          Navigator.pop(context);
                        },
                        icon: Icon(
                          isFav
                              ? Icons.star_rounded
                              : Icons.star_border_rounded,
                          color: isFav
                              ? (colors.accentColor ?? colors.countdownText)
                              : colors.mutedText,
                        ),
                        tooltip: 'quran.set_favorite_reciter'.tr(),
                      ),
                    ],
                  ),
                  subtitle: Text(
                    reciter.arabicName,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colors.mutedText,
                    ),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isFav)
                        Icon(
                          Icons.star_rounded,
                          size: 16,
                          color: colors.accentColor ?? colors.countdownText,
                        ),
                      if (isSelected)
                        Padding(
                          padding: const EdgeInsets.only(left: 4),
                          child: Icon(
                            Icons.check_circle_rounded,
                            color: colors.accentColor ?? colors.countdownText,
                          ),
                        ),
                    ],
                  ),
                  onTap: () {
                    audioCubit.setReciter(reciter);
                    Navigator.pop(context);
                  },
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

String _formatDuration(int ms) {
  if (ms <= 0) return '0:00';
  final totalSeconds = (ms / 1000).round();
  final minutes = totalSeconds ~/ 60;
  final seconds = totalSeconds % 60;
  return '$minutes:${seconds.toString().padLeft(2, '0')}';
}
