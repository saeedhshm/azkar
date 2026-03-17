import 'dart:math';
import 'dart:ui';

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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return BlocProvider<ReaderCubit>(
      create: (_) => getIt<ReaderCubit>()
        ..initialize(
          categoryKey: widget.categoryKey,
          startIndex: widget.startIndex,
          initialAdhkarId: widget.initialAdhkarId,
        ),
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          title: Text('reader.title'.tr()),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: Stack(
          children: [
            _ReaderBackground(isDark: isDark),
            SafeArea(
              child: BlocBuilder<ReaderCubit, ReaderState>(
                builder: (context, state) {
                  if (state.status == ReaderStatus.loading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (state.status == ReaderStatus.failure) {
                    return Center(
                      child: Text(
                        state.errorMessage ?? 'reader.failed_open'.tr(),
                      ),
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
                  final percent = (progress * 100).clamp(0, 100).round();
                  final isCurrentAudioPlaying =
                      _isPlaying && _activeAudioPath == current.audioPath;

                  final accent = isDark
                      ? const Color(0xFF6EE7E8)
                      : const Color(0xFFB8862B);
                  final accentDeep = isDark
                      ? const Color(0xFF0FB9B1)
                      : const Color(0xFF8A6422);

                  return LayoutBuilder(
                    builder: (context, constraints) {
                      final isCompact = constraints.maxWidth < 390;

                      return SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: constraints.maxHeight - 36,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _GlassCard(
                                isDark: isDark,
                                child: Column(
                                  children: [
                                    Text(
                                      '${state.currentIndex + 1} / ${state.items.length}',
                                      style: theme.textTheme.titleSmall
                                          ?.copyWith(
                                            letterSpacing: 1.2,
                                            color: isDark
                                                ? Colors.white70
                                                : Colors.black54,
                                          ),
                                    ),
                                    const SizedBox(height: 12),
                                    AnimatedSwitcher(
                                      duration: const Duration(
                                        milliseconds: 280,
                                      ),
                                      child: Text(
                                        current.text,
                                        key: ValueKey<int>(current.id),
                                        textAlign: TextAlign.center,
                                        textDirection: TextDirection.rtl,
                                        style: theme.textTheme.headlineSmall
                                            ?.copyWith(
                                              height: 1.8,
                                              color: isDark
                                                  ? Colors.white
                                                  : const Color(0xFF1D2530),
                                            ),
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      'reader.repeat_label'.tr(
                                        namedArgs: {'count': total.toString()},
                                      ),
                                      style: theme.textTheme.bodyMedium
                                          ?.copyWith(
                                            color: isDark
                                                ? Colors.white70
                                                : Colors.black54,
                                          ),
                                    ),
                                    const SizedBox(height: 18),
                                    _ProgressBar(
                                      progress: progress,
                                      accent: accent,
                                      isDark: isDark,
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      '$percent%',
                                      style: theme.textTheme.titleMedium
                                          ?.copyWith(
                                            color: isDark
                                                ? Colors.white70
                                                : Colors.black54,
                                          ),
                                    ),
                                    if (current.description.isNotEmpty)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 16),
                                        child: Text(
                                          current.description,
                                          textAlign: TextAlign.center,
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(
                                                color: isDark
                                                    ? Colors.white60
                                                    : Colors.black45,
                                              ),
                                        ),
                                      ),
                                    if (current.reference.isNotEmpty)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 6),
                                        child: Text(
                                          current.reference,
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(
                                                color: isDark
                                                    ? Colors.white60
                                                    : Colors.black45,
                                              ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 20),
                              _GlowButton(
                                enabled: state.remainingCount > 0,
                                onTap: state.remainingCount > 0
                                    ? () => context
                                          .read<ReaderCubit>()
                                          .decrementCounter()
                                    : null,
                                accent: accent,
                                accentDeep: accentDeep,
                                label: Text(
                                  'reader.tasbeeh_button'.tr(),
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    color: const Color(0xFF6EE7E8),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                state.remainingCount > 0
                                    ? '${'reader.remaining'.tr()}: ${state.remainingCount}'
                                    : 'reader.completed'.tr(),
                                textAlign: TextAlign.center,
                                style: theme.textTheme.titleSmall?.copyWith(
                                  color: isDark
                                      ? Colors.white70
                                      : Colors.black54,
                                ),
                              ),
                              const SizedBox(height: 18),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  _ActionCircle(
                                    onTap: current.audioPath.isNotEmpty
                                        ? () => _toggleAudio(
                                            context,
                                            current.audioPath,
                                          )
                                        : null,
                                    icon: isCurrentAudioPlaying
                                        ? Icons.stop_circle
                                        : Icons.volume_up_rounded,
                                    accent: accent,
                                    isDark: isDark,
                                  ),
                                  _ActionCircle(
                                    onTap: () {
                                      context
                                          .read<ReaderCubit>()
                                          .toggleFavorite();
                                    },
                                    icon: isFavorite
                                        ? Icons.star_rounded
                                        : Icons.star_border_rounded,
                                    accent: accent,
                                    isDark: isDark,
                                  ),
                                  _ActionCircle(
                                    onTap: () =>
                                        _copyText(context, current.text),
                                    icon: Icons.copy_all_rounded,
                                    accent: accent,
                                    isDark: isDark,
                                  ),
                                  _ActionCircle(
                                    onTap: () => _shareText(current.text),
                                    icon: Icons.share_rounded,
                                    accent: accent,
                                    isDark: isDark,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 18),
                              _NavigationPill(
                                isDark: isDark,
                                onPrevious: state.currentIndex > 0
                                    ? () =>
                                          context.read<ReaderCubit>().previous()
                                    : null,
                                onNext:
                                    state.currentIndex < state.items.length - 1
                                    ? () => context.read<ReaderCubit>().next()
                                    : null,
                                isCompact: isCompact,
                              ),
                              const SizedBox(height: 16),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReaderBackground extends StatelessWidget {
  const _ReaderBackground({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final gradient = isDark
        ? const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0A1220), Color(0xFF0F1C2E), Color(0xFF071A1B)],
          )
        : const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF6F0E5), Color(0xFFF2E7D6), Color(0xFFEADCC4)],
          );

    return DecoratedBox(
      decoration: BoxDecoration(gradient: gradient),
      child: CustomPaint(
        painter: _StarFieldPainter(isDark: isDark),
        child: Container(),
      ),
    );
  }
}

class _StarFieldPainter extends CustomPainter {
  _StarFieldPainter({required this.isDark});

  final bool isDark;

  @override
  void paint(Canvas canvas, Size size) {
    final random = Random(7);
    final starCount = isDark ? 120 : 60;
    final baseOpacity = isDark ? 0.45 : 0.2;

    for (var i = 0; i < starCount; i++) {
      final dx = random.nextDouble() * size.width;
      final dy = random.nextDouble() * size.height;
      final radius = random.nextDouble() * 1.4 + 0.3;
      final opacity = baseOpacity + random.nextDouble() * 0.4;
      final paint = Paint()
        ..color = (isDark ? Colors.white : const Color(0xFFB48A45)).withValues(
          alpha: opacity,
        );
      canvas.drawCircle(Offset(dx, dy), radius, paint);
    }

    final glowPaint = Paint()
      ..shader =
          RadialGradient(
            colors: isDark
                ? [
                    const Color(0xFF3BE8E8).withValues(alpha: 0.18),
                    Colors.transparent,
                  ]
                : [
                    const Color(0xFFB8862B).withValues(alpha: 0.2),
                    Colors.transparent,
                  ],
          ).createShader(
            Rect.fromCircle(
              center: Offset(size.width * 0.5, size.height * 0.7),
              radius: size.width * 0.8,
            ),
          );
    canvas.drawRect(Offset.zero & size, glowPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _GlassCard extends StatelessWidget {
  const _GlassCard({required this.child, required this.isDark});

  final Widget child;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.15)
        : const Color(0xFFBFA272).withValues(alpha: 0.35);
    final background = isDark
        ? Colors.white.withValues(alpha: 0.06)
        : Colors.white.withValues(alpha: 0.55);

    return ClipRRect(
      borderRadius: BorderRadius.circular(26),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: borderColor, width: 1.2),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
            child: child,
          ),
        ),
      ),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({
    required this.progress,
    required this.accent,
    required this.isDark,
  });

  final double progress;
  final Color accent;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final background = isDark
        ? Colors.white.withValues(alpha: 0.12)
        : Colors.black.withValues(alpha: 0.08);
    final gradient = LinearGradient(
      colors: [accent.withValues(alpha: 0.9), accent.withValues(alpha: 0.6)],
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(50),
      child: SizedBox(
        height: 10,
        child: Stack(
          fit: StackFit.expand,
          children: [
            ColoredBox(color: background),
            FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: progress,
              child: DecoratedBox(
                decoration: BoxDecoration(gradient: gradient),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GlowButton extends StatelessWidget {
  const _GlowButton({
    required this.enabled,
    required this.onTap,
    required this.accent,
    required this.accentDeep,
    required this.label,
  });

  final bool enabled;
  final VoidCallback? onTap;
  final Color accent;
  final Color accentDeep;
  final Widget label;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 70,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Glowing outer shadow
          if (enabled)
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(44),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6EE7E8).withValues(alpha: 0.25),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                  BoxShadow(
                    color: const Color(0xFF6EE7E8).withValues(alpha: 0.1),
                    blurRadius: 20,
                  ),
                ],
              ),
            ),
          // Main metallic button
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(44),
              border: Border.all(
                color: enabled
                    ? const Color(0xFF6EE7E8).withValues(alpha: 0.8)
                    : Colors.grey.withValues(alpha: 0.6),
                width: 2,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(42),
              child: Stack(
                children: [
                  // Metallic gradient background
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: enabled
                            ? [
                                const Color(0xFF4A5568).withValues(alpha: 0.9),
                                const Color(0xFF2D3748).withValues(alpha: 0.95),
                                const Color(0xFF1A202C).withValues(alpha: 0.9),
                              ]
                            : [
                                Colors.grey.shade400.withValues(alpha: 0.8),
                                Colors.grey.shade500.withValues(alpha: 0.85),
                                Colors.grey.shade600.withValues(alpha: 0.8),
                              ],
                      ),
                    ),
                  ),
                  // Metallic highlight effect
                  Align(
                    alignment: Alignment.topLeft,
                    child: Container(
                      width: double.infinity,
                      height: 25,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.white.withValues(alpha: enabled ? 0.3 : 0.15),
                            Colors.transparent,
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                  ),
                  // Subtle texture overlay
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                    ),
                  ),
                  // Inner border
                  Container(
                    margin: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(36),
                      border: Border.all(
                        color: enabled
                            ? const Color(0xFF6EE7E8).withValues(alpha: 0.3)
                            : Colors.grey.withValues(alpha: 0.2),
                        width: 1,
                      ),
                    ),
                  ),
                  // Touch area
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(42),
                      onTap: enabled ? onTap : null,
                      child: Center(
                        child: DefaultTextStyle(
                          style: TextStyle(
                            color: enabled
                                ? const Color(0xFF6EE7E8)
                                : Colors.grey.shade400,
                            fontWeight: FontWeight.w600,
                            fontSize: 18,
                          ),
                          child: label,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionCircle extends StatelessWidget {
  const _ActionCircle({
    required this.onTap,
    required this.icon,
    required this.accent,
    required this.isDark,
  });

  final VoidCallback? onTap;
  final IconData icon;
  final Color accent;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      width: 56,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Glowing outer shadow
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF6EE7E8).withValues(alpha: 0.25),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
                BoxShadow(
                  color: const Color(0xFF6EE7E8).withValues(alpha: 0.1),
                  blurRadius: 20,
                ),
              ],
            ),
          ),
          // Main metallic button
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFF6EE7E8).withValues(alpha: 0.8),
                width: 2,
              ),
            ),
            child: ClipOval(
              child: Stack(
                children: [
                  // Metallic gradient background
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          const Color(0xFF4A5568).withValues(alpha: 0.9),
                          const Color(0xFF2D3748).withValues(alpha: 0.95),
                          const Color(0xFF1A202C).withValues(alpha: 0.9),
                        ],
                      ),
                    ),
                  ),
                  // Metallic highlight effect
                  Align(
                    alignment: Alignment.topLeft,
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          colors: [
                            Colors.white.withValues(alpha: 0.3),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Subtle texture overlay
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                    ),
                  ),
                  // Inner border
                  Container(
                    margin: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFF6EE7E8).withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                  ),
                  // Touch area
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: onTap,
                      customBorder: const CircleBorder(),
                      child: Center(
                        child: Icon(
                          icon,
                          color: const Color(0xFF6EE7E8),
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavigationPill extends StatelessWidget {
  const _NavigationPill({
    required this.isDark,
    required this.onPrevious,
    required this.onNext,
    required this.isCompact,
  });

  final bool isDark;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;
  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: isCompact ? 54 : 58,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Glowing outer shadow
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF6EE7E8).withValues(alpha: 0.2),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
                BoxShadow(
                  color: const Color(0xFF6EE7E8).withValues(alpha: 0.08),
                  blurRadius: 20,
                ),
              ],
            ),
          ),
          // Main metallic pill
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: const Color(0xFF6EE7E8).withValues(alpha: 0.8),
                width: 2,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: Stack(
                children: [
                  // Metallic gradient background
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          const Color(0xFF4A5568).withValues(alpha: 0.9),
                          const Color(0xFF2D3748).withValues(alpha: 0.95),
                          const Color(0xFF1A202C).withValues(alpha: 0.9),
                        ],
                      ),
                    ),
                  ),
                  // Metallic highlight effect
                  Align(
                    alignment: Alignment.topLeft,
                    child: Container(
                      width: double.infinity,
                      height: 20,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.white.withValues(alpha: 0.25),
                            Colors.transparent,
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                  ),
                  // Subtle texture overlay
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                    ),
                  ),
                  // Inner border
                  Container(
                    margin: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(26),
                      border: Border.all(
                        color: const Color(0xFF6EE7E8).withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                  ),
                  // Navigation buttons
                  Row(
                    children: [
                      Expanded(
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: onPrevious,
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(28),
                              bottomLeft: Radius.circular(28),
                            ),
                            child: Center(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.arrow_back,
                                    color: const Color(0xFF6EE7E8),
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'common.previous'.tr(),
                                    style: TextStyle(
                                      color: const Color(0xFF6EE7E8),
                                      fontWeight: FontWeight.w500,
                                      fontSize: isCompact ? 14 : 15,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      Container(
                        width: 1,
                        height: isCompact ? 30 : 34,
                        color: const Color(0xFF6EE7E8).withValues(alpha: 0.4),
                      ),
                      Expanded(
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: onNext,
                            borderRadius: const BorderRadius.only(
                              topRight: Radius.circular(28),
                              bottomRight: Radius.circular(28),
                            ),
                            child: Center(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'common.next'.tr(),
                                    style: TextStyle(
                                      color: const Color(0xFF6EE7E8),
                                      fontWeight: FontWeight.w500,
                                      fontSize: isCompact ? 14 : 15,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Icon(
                                    Icons.arrow_forward,
                                    color: const Color(0xFF6EE7E8),
                                    size: 20,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
