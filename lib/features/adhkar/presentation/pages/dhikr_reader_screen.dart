import 'package:audioplayers/audioplayers.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/di/service_locator.dart';
import '../cubit/reader_cubit.dart';
import '../cubit/reader_state.dart';

class DhikrReaderScreen extends StatefulWidget {
  const DhikrReaderScreen({
    super.key,
    required this.categoryKey,
    required this.startIndex,
    this.initialAdhkarId,
  });

  final String categoryKey;
  final int startIndex;
  final int? initialAdhkarId;

  @override
  State<DhikrReaderScreen> createState() => _DhikrReaderScreenState();
}

class _DhikrReaderScreenState extends State<DhikrReaderScreen> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  String? _activeAudioPath;

  @override
  void initState() {
    super.initState();
    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isPlaying = state == PlayerState.playing;
      });
    });
    _audioPlayer.onPlayerComplete.listen((_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isPlaying = false;
      });
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _copyText(BuildContext context, String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('reader.copied'.tr())));
    }
  }

  Future<void> _shareText(String text) {
    return SharePlus.instance.share(ShareParams(text: text));
  }

  Future<void> _toggleAudio(BuildContext context, String audioPath) async {
    if (audioPath.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('reader.audio_unavailable'.tr())));
      return;
    }

    try {
      final isSameTrack = _activeAudioPath == audioPath;

      if (_isPlaying && isSameTrack) {
        await _audioPlayer.stop();
        if (mounted) {
          setState(() {
            _isPlaying = false;
          });
        }
        return;
      }

      await _audioPlayer.stop();
      try {
        await _audioPlayer.play(AssetSource(audioPath));
      } catch (_) {
        final bundleBytes = await rootBundle.load('assets/$audioPath');
        await _audioPlayer.play(BytesSource(bundleBytes.buffer.asUint8List()));
      }

      if (mounted) {
        setState(() {
          _isPlaying = true;
          _activeAudioPath = audioPath;
        });
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('reader.audio_failed'.tr())));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ReaderCubit>(
      create: (_) => getIt<ReaderCubit>()
        ..initialize(
          categoryKey: widget.categoryKey,
          startIndex: widget.startIndex,
          initialAdhkarId: widget.initialAdhkarId,
        ),
      child: Scaffold(
        appBar: AppBar(title: Text('reader.title'.tr())),
        body: BlocBuilder<ReaderCubit, ReaderState>(
          builder: (context, state) {
            if (state.status == ReaderStatus.loading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state.status == ReaderStatus.failure) {
              return Center(
                child: Text(state.errorMessage ?? 'reader.failed_open'.tr()),
              );
            }

            final current = state.currentAdhkar;
            if (current == null) {
              return Center(child: Text('reader.no_dhikr'.tr()));
            }

            final isFavorite = state.favoriteIds.contains(current.id);
            final total = current.count;
            final done = (total - state.remainingCount).clamp(0, total);
            final progress = total == 0 ? 0.0 : done / total;
            final isCurrentAudioPlaying =
                _isPlaying && _activeAudioPath == current.audioPath;

            return LayoutBuilder(
              builder: (context, constraints) {
                final isCompact = constraints.maxWidth < 390;

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight - 32,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              children: [
                                Text(
                                  '${state.currentIndex + 1} / ${state.items.length}',
                                  style: Theme.of(context).textTheme.labelLarge,
                                ),
                                const SizedBox(height: 10),
                                AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 280),
                                  child: Text(
                                    current.text,
                                    key: ValueKey<int>(current.id),
                                    textAlign: TextAlign.center,
                                    textDirection: TextDirection.rtl,
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineSmall
                                        ?.copyWith(height: 1.8),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                if (current.description.isNotEmpty)
                                  Text(
                                    current.description,
                                    textAlign: TextAlign.center,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodyMedium,
                                  ),
                                if (current.reference.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 8),
                                    child: Text(
                                      current.reference,
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodySmall,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        LinearProgressIndicator(value: progress),
                        const SizedBox(height: 6),
                        Text(
                          '${'reader.progress'.tr()}: $done / $total',
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),
                        FilledButton.icon(
                          onPressed: state.remainingCount > 0
                              ? () => context
                                    .read<ReaderCubit>()
                                    .decrementCounter()
                              : null,
                          icon: const Icon(Icons.exposure_minus_1),
                          label: Text(
                            state.remainingCount > 0
                                ? '${'reader.remaining'.tr()}: ${state.remainingCount}'
                                : 'reader.completed'.tr(),
                          ),
                          style: FilledButton.styleFrom(
                            minimumSize: const Size.fromHeight(56),
                          ),
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          onPressed: current.audioPath.isNotEmpty
                              ? () => _toggleAudio(context, current.audioPath)
                              : null,
                          icon: Icon(
                            isCurrentAudioPlaying
                                ? Icons.stop_circle_outlined
                                : Icons.play_circle_outline,
                          ),
                          label: Text(
                            isCurrentAudioPlaying
                                ? 'reader.stop_audio'.tr()
                                : 'reader.play_audio'.tr(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (isCompact) ...[
                          OutlinedButton.icon(
                            onPressed: state.currentIndex > 0
                                ? () => context.read<ReaderCubit>().previous()
                                : null,
                            icon: const Icon(Icons.arrow_back),
                            label: Text('common.previous'.tr()),
                          ),
                          const SizedBox(height: 10),
                          OutlinedButton.icon(
                            onPressed:
                                state.currentIndex < state.items.length - 1
                                ? () => context.read<ReaderCubit>().next()
                                : null,
                            icon: const Icon(Icons.arrow_forward),
                            label: Text('common.next'.tr()),
                          ),
                        ] else
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: state.currentIndex > 0
                                      ? () => context
                                            .read<ReaderCubit>()
                                            .previous()
                                      : null,
                                  icon: const Icon(Icons.arrow_back),
                                  label: Text('common.previous'.tr()),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed:
                                      state.currentIndex <
                                          state.items.length - 1
                                      ? () => context.read<ReaderCubit>().next()
                                      : null,
                                  icon: const Icon(Icons.arrow_forward),
                                  label: Text('common.next'.tr()),
                                ),
                              ),
                            ],
                          ),
                        const SizedBox(height: 12),
                        if (isCompact) ...[
                          OutlinedButton.icon(
                            onPressed: () {
                              context.read<ReaderCubit>().toggleFavorite();
                            },
                            icon: Icon(
                              isFavorite
                                  ? Icons.bookmark
                                  : Icons.bookmark_border_outlined,
                            ),
                            label: Text('common.favorite'.tr()),
                          ),
                          const SizedBox(height: 10),
                          OutlinedButton.icon(
                            onPressed: () => _copyText(context, current.text),
                            icon: const Icon(Icons.copy_outlined),
                            label: Text('common.copy'.tr()),
                          ),
                          const SizedBox(height: 10),
                          OutlinedButton.icon(
                            onPressed: () => _shareText(current.text),
                            icon: const Icon(Icons.share_outlined),
                            label: Text('common.share'.tr()),
                          ),
                        ] else
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () {
                                    context
                                        .read<ReaderCubit>()
                                        .toggleFavorite();
                                  },
                                  icon: Icon(
                                    isFavorite
                                        ? Icons.bookmark
                                        : Icons.bookmark_border_outlined,
                                  ),
                                  label: Text('common.favorite'.tr()),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () =>
                                      _copyText(context, current.text),
                                  icon: const Icon(Icons.copy_outlined),
                                  label: Text('common.copy'.tr()),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () => _shareText(current.text),
                                  icon: const Icon(Icons.share_outlined),
                                  label: Text('common.share'.tr()),
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
