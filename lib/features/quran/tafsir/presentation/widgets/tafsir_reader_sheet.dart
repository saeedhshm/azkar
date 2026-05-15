import 'dart:ui' as ui;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/theme/app_theme.dart';
import '../../../actions/presentation/cubit/ayah_actions_cubit.dart';
import '../../../actions/presentation/cubit/ayah_actions_state.dart';
import '../../../tafsir/domain/entities/tafsir_source.dart';

class TafsirReaderSheet extends StatelessWidget {
  const TafsirReaderSheet({
    super.key,
    required this.surahNumber,
    required this.ayahNumber,
    required this.surahName,
    required this.ayahText,
    this.initialSourceId,
  });

  final int surahNumber;
  final int ayahNumber;
  final String surahName;
  final String ayahText;
  final String? initialSourceId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: context.read<AyahActionsCubit>(),
      child: _TafsirReaderSheetBody(
        surahNumber: surahNumber,
        ayahNumber: ayahNumber,
        surahName: surahName,
        ayahText: ayahText,
        initialSourceId: initialSourceId,
      ),
    );
  }
}

class _TafsirReaderSheetBody extends StatefulWidget {
  const _TafsirReaderSheetBody({
    required this.surahNumber,
    required this.ayahNumber,
    required this.surahName,
    required this.ayahText,
    this.initialSourceId,
  });

  final int surahNumber;
  final int ayahNumber;
  final String surahName;
  final String ayahText;
  final String? initialSourceId;

  @override
  State<_TafsirReaderSheetBody> createState() => _TafsirReaderSheetBodyState();
}

class _TafsirReaderSheetBodyState extends State<_TafsirReaderSheetBody> {
  late String _selectedSourceId;

  @override
  void initState() {
    super.initState();
    _selectedSourceId = widget.initialSourceId ?? 'jalalayn';
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadTafsirIfNeeded();
    });
  }

  void _loadTafsirIfNeeded() {
    final cubit = context.read<AyahActionsCubit>();
    final state = cubit.state;
    final hasForSource = state.tafsirEntries.any(
      (e) => e.id.startsWith(_selectedSourceId),
    );
    if (!hasForSource) {
      cubit.loadTafsirSource(
        surahNumber: widget.surahNumber,
        ayahNumber: widget.ayahNumber,
        sourceId: _selectedSourceId,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = AppThemeColors.of(context);

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          child: Column(
            children: [
              _TafsirHeader(
                surahName: widget.surahName,
                ayahNumber: widget.ayahNumber,
                ayahText: widget.ayahText,
                theme: theme,
                colors: colors,
              ),
              const SizedBox(height: 12),
              _SourceSelector(
                selectedSourceId: _selectedSourceId,
                onChanged: (sourceId) {
                  setState(() => _selectedSourceId = sourceId);
                  context.read<AyahActionsCubit>().loadTafsirSource(
                    surahNumber: widget.surahNumber,
                    ayahNumber: widget.ayahNumber,
                    sourceId: sourceId,
                  );
                },
                theme: theme,
                colors: colors,
              ),
              const SizedBox(height: 12),
              Expanded(
                child: _TafsirBody(
                  scrollController: scrollController,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _TafsirHeader extends StatelessWidget {
  const _TafsirHeader({
    required this.surahName,
    required this.ayahNumber,
    required this.ayahText,
    required this.theme,
    required this.colors,
  });

  final String surahName;
  final int ayahNumber;
  final String ayahText;
  final ThemeData theme;
  final AppThemeColors colors;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$surahName • ${'quran.ayah_number'.tr()} $ayahNumber',
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: colors.cardSurface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: colors.softBorder),
          ),
          child: Text(
            ayahText,
            textDirection: ui.TextDirection.rtl,
            style: theme.textTheme.bodyLarge?.copyWith(height: 1.6),
          ),
        ),
      ],
    );
  }
}

class _SourceSelector extends StatelessWidget {
  const _SourceSelector({
    required this.selectedSourceId,
    required this.onChanged,
    required this.theme,
    required this.colors,
  });

  final String selectedSourceId;
  final ValueChanged<String> onChanged;
  final ThemeData theme;
  final AppThemeColors colors;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: TafsirSource.defaults.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final source = TafsirSource.defaults[index];
          final isSelected = source.id == selectedSourceId;

          return GestureDetector(
            onTap: () => onChanged(source.id),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF6C63FF) : colors.cardSurface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? const Color(0xFF6C63FF) : colors.softBorder,
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                source.name,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: isSelected ? Colors.white : theme.colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _TafsirBody extends StatelessWidget {
  const _TafsirBody({required this.scrollController});

  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = AppThemeColors.of(context);

    return BlocBuilder<AyahActionsCubit, AyahActionsState>(
      builder: (context, state) {
        if (state.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state.status == AyahActionStatus.tafsirError) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.cloud_off_rounded, size: 48, color: colors.mutedText),
                const SizedBox(height: 12),
                Text('quran.tafsir_load_failed'.tr(), style: theme.textTheme.bodyMedium),
                const SizedBox(height: 8),
                FilledButton.tonal(
                  onPressed: () {
                    final cubit = context.read<AyahActionsCubit>();
                    final currentSourceId = '';
                    cubit.loadTafsir(
                      surahNumber: 0,
                      ayahNumber: 0,
                      sourceId: currentSourceId,
                    );
                  },
                  child: Text('common.retry'.tr()),
                ),
              ],
            ),
          );
        }

        if (!state.hasTafsir) {
          return Center(
            child: Text(
              'quran.tafsir_empty'.tr(),
              style: theme.textTheme.bodyMedium?.copyWith(color: colors.mutedText),
            ),
          );
        }

        final entry = state.tafsirEntries.last;
        return SingleChildScrollView(
          controller: scrollController,
          child: SelectableText(
            entry.text,
            textDirection: entry.sourceLanguage == 'ar' ? ui.TextDirection.rtl : ui.TextDirection.ltr,
            style: theme.textTheme.bodyLarge?.copyWith(height: 1.8),
          ),
        );
      },
    );
  }
}
