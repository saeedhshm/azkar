import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/quran_ayah.dart';
import '../../domain/entities/quran_surah.dart';
import 'quran_ayah_tile.dart';
import 'quran_mushaf_frame.dart';

class QuranSurahPage extends StatefulWidget {
  const QuranSurahPage({
    super.key,
    required this.surah,
    required this.selectedAyahNumber,
    required this.onAyahTap,
  });

  final QuranSurah surah;
  final int? selectedAyahNumber;
  final ValueChanged<QuranAyah> onAyahTap;

  @override
  State<QuranSurahPage> createState() => _QuranSurahPageState();
}

class _QuranSurahPageState extends State<QuranSurahPage> {
  final _scrollController = ScrollController();

  @override
  void didUpdateWidget(covariant QuranSurahPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedAyahNumber != null &&
        widget.selectedAyahNumber != oldWidget.selectedAyahNumber) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _scrollToSelectedAyah(),
      );
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToSelectedAyah() {
    if (!_scrollController.hasClients || widget.selectedAyahNumber == null) {
      return;
    }
    final estimated = 145.0 + ((widget.selectedAyahNumber! - 1) * 128.0);
    final target = math.min(
      estimated,
      _scrollController.position.maxScrollExtent,
    );
    _scrollController.animateTo(
      target,
      duration: const Duration(milliseconds: 520),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: QuranMushafFrame(
        child: CustomScrollView(
          controller: _scrollController,
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          slivers: [
            SliverToBoxAdapter(child: _SurahHeader(surah: widget.surah)),
            SliverList.builder(
              itemCount: widget.surah.ayahs.length,
              itemBuilder: (context, index) {
                final ayah = widget.surah.ayahs[index];
                return QuranAyahTile(
                  ayah: ayah,
                  selected: widget.selectedAyahNumber == ayah.numberInSurah,
                  onTap: () => widget.onAyahTap(ayah),
                );
              },
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 12)),
          ],
        ),
      ),
    );
  }
}

class _SurahHeader extends StatelessWidget {
  const _SurahHeader({required this.surah});

  final QuranSurah surah;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = AppThemeColors.of(context);
    final gold = colors.accentColor ?? colors.countdownText;
    final revelationKey = surah.revelationType.toLowerCase() == 'meccan'
        ? 'quran.meccan'
        : 'quran.medinan';

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 14),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _MetaChip(
                label:
                    '${'quran.juz'.tr()} ${surah.ayahs.isEmpty ? '-' : surah.ayahs.first.juz}',
              ),
              const SizedBox(width: 8),
              _MetaChip(label: revelationKey.tr()),
              const SizedBox(width: 8),
              _MetaChip(label: '${surah.ayahCount} ${'quran.ayahs'.tr()}'),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            surah.name,
            textDirection: ui.TextDirection.rtl,
            textAlign: TextAlign.center,
            style: theme.textTheme.displaySmall?.copyWith(
              fontFamily: 'Cairo',
              fontWeight: FontWeight.w900,
              color: gold,
              height: 1.25,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${surah.number}. ${surah.englishName} • ${surah.englishNameTranslation}',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colors.mutedText,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: 160,
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  gold.withValues(alpha: 0.75),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = AppThemeColors.of(context);
    final gold = colors.accentColor ?? colors.countdownText;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: gold.withValues(alpha: 0.1),
        border: Border.all(color: gold.withValues(alpha: 0.22)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: colors.secondaryText,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
