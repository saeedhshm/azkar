import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/widgets/app_background.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../core/widgets/glow_button.dart';
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

class _DhikrReaderScreenState extends State<DhikrReaderScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _countBounce;

  @override
  void initState() {
    super.initState();
    _countBounce = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
      lowerBound: 1.0,
      upperBound: 1.15,
    );
  }

  @override
  void dispose() {
    _countBounce.dispose();
    super.dispose();
  }

  void _triggerBounce() {
    HapticFeedback.lightImpact();
    _countBounce.forward().then((_) => _countBounce.reverse());
  }

  Future<void> _copyText(BuildContext context, String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('reader.copied'.tr())),
      );
    }
  }

  Future<void> _shareText(String text) {
    return SharePlus.instance.share(ShareParams(text: text));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = AppThemeColors.of(context);

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
            'reader.title'.tr(),
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        body: Stack(
          children: [
            AppScaffoldBackground(
              particleCount: 90,
              particleSeed: 7,
              showRadialGlow: true,
              glowCenter: const Alignment(0, 0.6),
            ),
            SafeArea(
              child: BlocConsumer<ReaderCubit, ReaderState>(
                listener: (context, state) {
                  if (state.remainingCount > 0) return;
                  // completed
                },
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

                  final isFav = state.favoriteIds.contains(current.id);
                  final total = current.count;
                  final done = (total - state.remainingCount).clamp(0, total);
                  final progress = total == 0 ? 0.0 : done / total;
                  final isCompleted = state.remainingCount == 0;

                  return LayoutBuilder(
                    builder: (context, constraints) {
                      final isCompact = constraints.maxWidth < 390;

                      return SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: constraints.maxHeight - 30,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Index indicator
                              Center(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: colors.pillBg,
                                    borderRadius:
                                        BorderRadius.circular(AppRadius.pill),
                                    border:
                                        Border.all(color: colors.softBorder),
                                  ),
                                  child: Text(
                                    '${state.currentIndex + 1} / ${state.items.length}',
                                    style:
                                        theme.textTheme.labelSmall?.copyWith(
                                      color: colors.mutedText,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 14),

                              // Main dhikr card
                              AppGlassCard(
                                padding: const EdgeInsets.all(20),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    // Dhikr text
                                    AnimatedSwitcher(
                                      duration:
                                          const Duration(milliseconds: 300),
                                      transitionBuilder: (child, anim) =>
                                          FadeTransition(
                                              opacity: anim, child: child),
                                      child: Text(
                                        current.text,
                                        key: ValueKey<int>(current.id),
                                        textAlign: TextAlign.center,
                                        textDirection: TextDirection.rtl,
                                        style: theme.textTheme.titleLarge
                                            ?.copyWith(
                                          height: 1.9,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 16),

                                    // Repeat label
                                    Center(
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 12, vertical: 5),
                                        decoration: BoxDecoration(
                                          color:
                                              (colors.accentColor ?? theme.colorScheme.primary)
                                                  .withValues(alpha: 0.12),
                                          borderRadius: BorderRadius.circular(
                                              AppRadius.pill),
                                        ),
                                        child: Text(
                                          'reader.repeat_label'.tr(namedArgs: {
                                            'count': total.toString()
                                          }),
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(
                                            color: colors.accentColor ??
                                                theme.colorScheme.primary,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 18),

                                    // Progress bar
                                    _ProgressBar(
                                        progress: progress,
                                        isCompleted: isCompleted,
                                        colors: colors),
                                    const SizedBox(height: 8),

                                    // Progress text
                                    Center(
                                      child: Text(
                                        isCompleted
                                            ? '✓ ${'reader.completed'.tr()}'
                                            : '${done} / ${total}',
                                        style: theme.textTheme.bodySmall
                                            ?.copyWith(
                                          color: isCompleted
                                              ? colors.successColor
                                              : colors.mutedText,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),

                                    // Description
                                    if (current.description.isNotEmpty) ...[
                                      const SizedBox(height: 14),
                                      const Divider(),
                                      const SizedBox(height: 10),
                                      Text(
                                        current.description,
                                        textAlign: TextAlign.center,
                                        style: theme.textTheme.bodySmall
                                            ?.copyWith(
                                          color: colors.mutedText,
                                          height: 1.6,
                                        ),
                                      ),
                                    ],

                                    // Reference
                                    if (current.reference.isNotEmpty) ...[
                                      const SizedBox(height: 6),
                                      Text(
                                        current.reference,
                                        textAlign: TextAlign.center,
                                        style: theme.textTheme.bodySmall
                                            ?.copyWith(
                                          color: colors.mutedText
                                              .withValues(alpha: 0.7),
                                          fontStyle: FontStyle.italic,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              const SizedBox(height: 18),

                              // Main count button
                              AppGlowButton(
                                enabled: !isCompleted,
                                onTap: isCompleted
                                    ? null
                                    : () {
                                        _triggerBounce();
                                        context
                                            .read<ReaderCubit>()
                                            .decrementCounter();
                                      },
                                label: Text(
                                  isCompleted
                                      ? '✓ ${'reader.completed'.tr()}'
                                      : 'reader.tasbeeh_button'.tr(),
                                ),
                                height: 64,
                              ),
                              const SizedBox(height: 10),

                              // Remaining display
                              Center(
                                child: AnimatedBuilder(
                                  animation: _countBounce,
                                  builder: (_, child) => Transform.scale(
                                    scale: _countBounce.value,
                                    child: child,
                                  ),
                                  child: Text(
                                    !isCompleted
                                        ? '${'reader.remaining'.tr()}: ${state.remainingCount}'
                                        : 'reader.completed'.tr(),
                                    style:
                                        theme.textTheme.bodyMedium?.copyWith(
                                      color: isCompleted
                                          ? colors.successColor
                                          : colors.mutedText,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),

                              // Action circle row
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  AppActionCircle(
                                    icon: Icons.volume_up_rounded,
                                    onTap: null,
                                    tooltip: 'common.audio'.tr(),
                                    size: isCompact ? 46 : 52,
                                  ),
                                  AppActionCircle(
                                    icon: isFav
                                        ? Icons.star_rounded
                                        : Icons.star_border_rounded,
                                    isActive: isFav,
                                    onTap: () => context
                                        .read<ReaderCubit>()
                                        .toggleFavorite(),
                                    tooltip: 'common.favorites'.tr(),
                                    size: isCompact ? 46 : 52,
                                  ),
                                  AppActionCircle(
                                    icon: Icons.copy_all_rounded,
                                    onTap: () =>
                                        _copyText(context, current.text),
                                    tooltip: 'common.copy'.tr(),
                                    size: isCompact ? 46 : 52,
                                  ),
                                  AppActionCircle(
                                    icon: Icons.share_rounded,
                                    onTap: () => _shareText(current.text),
                                    tooltip: 'common.share'.tr(),
                                    size: isCompact ? 46 : 52,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),

                              // Navigation pill
                              _NavigationPill(
                                onPrevious: state.currentIndex > 0
                                    ? () =>
                                        context.read<ReaderCubit>().previous()
                                    : null,
                                onNext:
                                    state.currentIndex < state.items.length - 1
                                        ? () =>
                                            context.read<ReaderCubit>().next()
                                        : null,
                                currentIndex: state.currentIndex,
                                total: state.items.length,
                              ),
                              const SizedBox(height: 12),
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

// ─── Progress Bar ─────────────────────────────────────────────────────────────

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({
    required this.progress,
    required this.isCompleted,
    required this.colors,
  });

  final double progress;
  final bool isCompleted;
  final AppThemeColors colors;

  @override
  Widget build(BuildContext context) {
    final accent = isCompleted
        ? colors.successColor
        : (colors.accentColor ?? Theme.of(context).colorScheme.primary);

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.pill),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        height: 8,
        child: Stack(
          fit: StackFit.expand,
          children: [
            ColoredBox(color: colors.softBorder),
            FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: progress.clamp(0, 1),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      accent.withValues(alpha: 0.85),
                      accent,
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: accent.withValues(alpha: 0.4),
                      blurRadius: 6,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Navigation Pill ──────────────────────────────────────────────────────────

class _NavigationPill extends StatelessWidget {
  const _NavigationPill({
    required this.onPrevious,
    required this.onNext,
    required this.currentIndex,
    required this.total,
  });

  final VoidCallback? onPrevious;
  final VoidCallback? onNext;
  final int currentIndex;
  final int total;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = AppThemeColors.of(context);
    final primary = theme.colorScheme.primary;

    return Container(
      height: 54,
      decoration: BoxDecoration(
        color: colors.cardSurface,
        borderRadius: BorderRadius.circular(AppRadius.xxl),
        border: Border.all(
          color: primary.withValues(alpha: 0.6),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: primary.withValues(alpha: 0.15),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Previous
          Expanded(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: const BorderRadius.horizontal(
                    left: Radius.circular(AppRadius.xxl)),
                onTap: onPrevious,
                child: Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.chevron_left_rounded,
                        color: onPrevious != null
                            ? primary
                            : colors.mutedText.withValues(alpha: 0.4),
                        size: 22,
                      ),
                      Text(
                        'reader.previous'.tr(),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: onPrevious != null
                              ? primary
                              : colors.mutedText.withValues(alpha: 0.4),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Divider with index
          Container(
            width: 1,
            height: 28,
            color: colors.softBorder,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              '${currentIndex + 1}/$total',
              style: theme.textTheme.labelSmall?.copyWith(
                color: colors.mutedText,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
          ),
          Container(
            width: 1,
            height: 28,
            color: colors.softBorder,
          ),
          // Next
          Expanded(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: const BorderRadius.horizontal(
                    right: Radius.circular(AppRadius.xxl)),
                onTap: onNext,
                child: Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'reader.next'.tr(),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: onNext != null
                              ? primary
                              : colors.mutedText.withValues(alpha: 0.4),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Icon(
                        Icons.chevron_right_rounded,
                        color: onNext != null
                            ? primary
                            : colors.mutedText.withValues(alpha: 0.4),
                        size: 22,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
