import 'dart:ui' as ui;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../actions/presentation/cubit/ayah_actions_cubit.dart';
import '../../../actions/presentation/cubit/ayah_actions_state.dart';
import '../../../tafsir/domain/entities/tafsir_source.dart';
import '../utils/default_tafsir_source.dart';

/// Displays the tafsir of a single ayah in a bottom sheet.
///
/// Callers must provide an [AyahActionsCubit] above this widget (e.g. via
/// [BlocProvider.value] when opening a new route), because a modal route
/// cannot see the providers of the route that opened it.
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
    return _TafsirReaderSheetBody(
      surahNumber: surahNumber,
      ayahNumber: ayahNumber,
      surahName: surahName,
      ayahText: ayahText,
      initialSourceId: initialSourceId,
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
  List<TafsirSource> _visibleSources = TafsirSource.defaults;
  bool _initializedSource = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // The locale (an inherited widget) is unavailable in initState, so the
    // language-matched sources and default are resolved here, exactly once.
    if (!_initializedSource) {
      _initializedSource = true;
      final languageCode = tafsirLanguageCode(context);
      _visibleSources = TafsirSource.sourcesForLanguage(languageCode);
      final initial = widget.initialSourceId;
      _selectedSourceId =
          initial != null && _visibleSources.any((s) => s.id == initial)
          ? initial
          : TafsirSource.defaultForLanguage(languageCode);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadTafsirIfNeeded();
      });
    }
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
              ),
              const SizedBox(height: 12),
              // A single matching source needs no selector.
              if (_visibleSources.length > 1) ...[
                _SourceSelector(
                  sources: _visibleSources,
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
                ),
                const SizedBox(height: 12),
              ],
              Expanded(
                child: _TafsirBody(
                  scrollController: scrollController,
                  surahNumber: widget.surahNumber,
                  ayahNumber: widget.ayahNumber,
                  selectedSourceId: _selectedSourceId,
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
  });

  final String surahName;
  final int ayahNumber;
  final String ayahText;
  final ThemeData theme;

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
            color: theme.colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: theme.colorScheme.outlineVariant),
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
    required this.sources,
    required this.selectedSourceId,
    required this.onChanged,
    required this.theme,
  });

  final List<TafsirSource> sources;
  final String selectedSourceId;
  final ValueChanged<String> onChanged;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: sources.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final source = sources[index];
          final isSelected = source.id == selectedSourceId;

          return GestureDetector(
            onTap: () => onChanged(source.id),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF6C63FF) : theme.colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? const Color(0xFF6C63FF) : theme.colorScheme.outlineVariant,
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
  const _TafsirBody({
    required this.scrollController,
    required this.surahNumber,
    required this.ayahNumber,
    required this.selectedSourceId,
  });

  final ScrollController scrollController;
  final int surahNumber;
  final int ayahNumber;
  final String selectedSourceId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
                Icon(Icons.cloud_off_rounded, size: 48, color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
                const SizedBox(height: 12),
                Text('quran.tafsir_load_failed'.tr(), style: theme.textTheme.bodyMedium),
                const SizedBox(height: 8),
                FilledButton.tonal(
                  onPressed: () {
                    // Retry the ayah and source that are actually on screen.
                    context.read<AyahActionsCubit>().loadTafsir(
                      surahNumber: surahNumber,
                      ayahNumber: ayahNumber,
                      sourceId: selectedSourceId,
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
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
            ),
          );
        }

        // Never show `entries.last`: it may belong to a previously selected
        // source. Fall back to it only when the selected one is missing.
        final entry =
            state.entryForSource(selectedSourceId) ?? state.tafsirEntries.last;
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
