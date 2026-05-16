import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/widgets/app_background.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../core/widgets/glow_button.dart';
import '../cubit/tasbeeh_cubit.dart';
import '../cubit/tasbeeh_state.dart';

class TasbeehCounterScreen extends StatefulWidget {
  const TasbeehCounterScreen({super.key});

  @override
  State<TasbeehCounterScreen> createState() => _TasbeehCounterScreenState();
}

class _TasbeehCounterScreenState extends State<TasbeehCounterScreen>
    with TickerProviderStateMixin {
  late final AnimationController _bounceController;
  late final Animation<double> _bounceAnimation;
  late final AnimationController _glowController;
  late final Animation<double> _glowAnimation;

  int _selectedPresetIndex = 0;

  static const List<_TasbeehPreset> _presets = [
    _TasbeehPreset('سُبحانَ الله', 33),
    _TasbeehPreset('الحَمدُ لله', 33),
    _TasbeehPreset('اللهُ أَكبَر', 33),
    _TasbeehPreset('لا إلهَ إلا الله', 100),
    _TasbeehPreset('اللَّهُمَّ صَلِّ عَلَى مُحَمَّد', 10),
  ];

  @override
  void initState() {
    super.initState();
    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 140),
      lowerBound: 0.85,
      upperBound: 1.0,
    )..value = 1.0;
    _bounceAnimation = CurvedAnimation(
      parent: _bounceController,
      curve: Curves.easeOut,
    );

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    _glowAnimation = CurvedAnimation(
      parent: _glowController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _bounceController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  void _onTap(TasbeehCubit cubit, TasbeehState state) {
    if (state.count >= _presets[_selectedPresetIndex].target) return;
    HapticFeedback.lightImpact();
    _bounceController.reverse().then((_) => _bounceController.forward());
    cubit.increment();
  }

  void _selectPreset(BuildContext context, int index) {
    setState(() => _selectedPresetIndex = index);
    context.read<TasbeehCubit>().reset();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppThemeColors.of(context);

    return BlocProvider<TasbeehCubit>(
      create: (_) => getIt<TasbeehCubit>()..load(),
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          leading: IconButton(
            icon: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: colors.pillBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: colors.softBorder),
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded, size: 16),
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Text(
            'common.tasbeeh_counter'.tr(),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
        ),
        body: Stack(
          children: [
            AppScaffoldBackground(
              particleCount: 100,
              particleSeed: 42,
              showRadialGlow: true,
              glowCenter: const Alignment(0, 0.2),
            ),
            SafeArea(
              child: BlocBuilder<TasbeehCubit, TasbeehState>(
                builder: (context, state) {
                  final cubit = context.read<TasbeehCubit>();
                  final target = _presets[_selectedPresetIndex].target;
                  final isCompleted = state.count >= target;
                  final progress = (state.count / target).clamp(0.0, 1.0);

                  return Column(
                    children: [
                      const SizedBox(height: 12),

                      // ── Preset chips ──────────────────
                      SizedBox(
                        height: 44,
                        child: ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          scrollDirection: Axis.horizontal,
                          itemCount: _presets.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(width: 8),
                          itemBuilder: (context, i) => _PresetChip(
                            preset: _presets[i],
                            selected: _selectedPresetIndex == i,
                            onTap: () => _selectPreset(context, i),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // ── Current phrase ────────────────
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: AppGlassCard(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 14),
                          child: Center(
                            child: Text(
                              _presets[_selectedPresetIndex].phrase,
                              textAlign: TextAlign.center,
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineSmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    height: 1.4,
                                  ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),

                      // ── Circular ring counter ─────────
                      Expanded(
                        child: Center(
                          child: _CounterRing(
                            progress: progress,
                            count: state.count,
                            target: target,
                            isCompleted: isCompleted,
                            bounceAnimation: _bounceAnimation,
                            glowAnimation: _glowAnimation,
                            onTap: () => _onTap(cubit, state),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // ── Stats row ─────────────────────
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Row(
                          children: [
                            _StatCard(
                              label: 'tasbeeh.total'.tr(),
                              value: state.count.toString(),
                            ),
                            const SizedBox(width: 10),
                            _StatCard(
                              label: 'tasbeeh.sessions'.tr(),
                              value: target > 0
                                  ? (state.count ~/ target).toString()
                                  : '0',
                            ),
                            const SizedBox(width: 10),
                            _StatCard(
                              label: 'tasbeeh.remaining'.tr(),
                              value: isCompleted
                                  ? '✓'
                                  : (target - (state.count % target == 0 && state.count > 0 ? target : state.count % target)).toString(),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      // ── Reset button ──────────────────
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: AppOutlineGlowButton(
                          label: Text('tasbeeh.reset'.tr()),
                          icon: Icons.restart_alt_rounded,
                          onTap: cubit.reset,
                          height: 46,
                          radius: AppRadius.xl,
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
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

// ─── Counter Ring ─────────────────────────────────────────────────────────────

class _CounterRing extends StatelessWidget {
  const _CounterRing({
    required this.progress,
    required this.count,
    required this.target,
    required this.isCompleted,
    required this.bounceAnimation,
    required this.glowAnimation,
    required this.onTap,
  });

  final double progress;
  final int count;
  final int target;
  final bool isCompleted;
  final Animation<double> bounceAnimation;
  final Animation<double> glowAnimation;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = AppThemeColors.of(context);
    final accent = isCompleted
        ? colors.successColor
        : (colors.accentColor ?? theme.colorScheme.primary);

    return AnimatedBuilder(
      animation: Listenable.merge([bounceAnimation, glowAnimation]),
      builder: (context, _) {
        final glow = glowAnimation.value;
        return GestureDetector(
          onTap: isCompleted ? null : onTap,
          child: Transform.scale(
            scale: bounceAnimation.value,
            child: SizedBox(
              width: 240,
              height: 240,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Animated glow ring
                  Container(
                    width: 240,
                    height: 240,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: accent.withValues(
                              alpha: (0.18 + glow * 0.12)
                                  .clamp(0.0, 1.0)),
                          blurRadius: 40 + glow * 20,
                          spreadRadius: glow * 8,
                        ),
                      ],
                    ),
                  ),
                  // Progress arc
                  CustomPaint(
                    size: const Size(240, 240),
                    painter: _RingPainter(
                      progress: progress,
                      color: accent,
                      trackColor: colors.softBorder,
                      strokeWidth: 8,
                    ),
                  ),
                  // Inner button
                  Container(
                    width: 196,
                    height: 196,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color.alphaBlend(
                            accent.withValues(alpha: 0.18),
                            theme.colorScheme.primary,
                          ),
                          theme.colorScheme.primary,
                          Color.alphaBlend(
                            Colors.black.withValues(alpha: 0.14),
                            theme.colorScheme.primary,
                          ),
                        ],
                      ),
                      border: Border.all(
                        color: accent.withValues(alpha: 0.7),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: theme.colorScheme.primary
                              .withValues(alpha: 0.35),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          transitionBuilder: (child, anim) =>
                              ScaleTransition(scale: anim, child: child),
                          child: Text(
                            count.toString(),
                            key: ValueKey<int>(count),
                            style: theme.textTheme.displayMedium?.copyWith(
                              color: theme.colorScheme.onPrimary,
                              fontWeight: FontWeight.w900,
                              fontSize: 62,
                              fontFeatures: const [
                                FontFeature.tabularFigures()
                              ],
                            ),
                          ),
                        ),
                        Text(
                          '/ $target',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onPrimary
                                .withValues(alpha: 0.65),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// ─── Ring Painter ─────────────────────────────────────────────────────────────

class _RingPainter extends CustomPainter {
  const _RingPainter({
    required this.progress,
    required this.color,
    required this.trackColor,
    required this.strokeWidth,
  });

  final double progress;
  final Color color;
  final Color trackColor;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Track
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, trackPaint);

    // Progress arc
    if (progress > 0) {
      final progressPaint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, strokeWidth * 0.4);

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -3.14159 / 2,
        2 * 3.14159 * progress,
        false,
        progressPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) =>
      old.progress != progress || old.color != color;
}

// ─── Preset Chip ─────────────────────────────────────────────────────────────

class _PresetChip extends StatelessWidget {
  const _PresetChip({
    required this.preset,
    required this.selected,
    required this.onTap,
  });

  final _TasbeehPreset preset;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = AppThemeColors.of(context);
    final accent = colors.accentColor ?? theme.colorScheme.primary;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? accent.withValues(alpha: 0.15)
              : colors.pillBg,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(
            color: selected
                ? accent.withValues(alpha: 0.5)
                : colors.softBorder,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              preset.phrase,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight:
                    selected ? FontWeight.w800 : FontWeight.w600,
                color: selected ? accent : colors.mutedText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Stat Card ────────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = AppThemeColors.of(context);

    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: colors.cardSurface,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: colors.softBorder),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w900,
                color: colors.accentColor ?? theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colors.mutedText,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Data ─────────────────────────────────────────────────────────────────────

class _TasbeehPreset {
  const _TasbeehPreset(this.phrase, this.target);
  final String phrase;
  final int target;
}
