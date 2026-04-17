import 'dart:ui' as ui;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/datasources/quran_page_image_cache_service.dart';
import '../../domain/entities/quran_search_result.dart';
import '../../domain/entities/quran_surah.dart';
import '../cubit/quran_cubit.dart';
import '../cubit/quran_state.dart';
import '../widgets/quran_mushaf_image_page.dart';
import '../widgets/quran_search_bar.dart';
import '../widgets/quran_search_results.dart';
import '../widgets/quran_surah_sheet.dart';

class QuranScreen extends StatefulWidget {
  const QuranScreen({super.key});

  @override
  State<QuranScreen> createState() => _QuranScreenState();
}

class _QuranScreenState extends State<QuranScreen> {
  final _pageController = PageController();
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _pageController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<QuranCubit>()..load(),
      child: BlocConsumer<QuranCubit, QuranState>(
        listenWhen: (previous, current) => previous.query != current.query,
        listener: (context, state) {
          if (state.query.isEmpty && _searchController.text.isNotEmpty) {
            _searchController.clear();
          }
        },
        builder: (context, state) {
          return Scaffold(
            appBar: _QuranAppBar(
              state: state,
              onSurahIndexTap: state.status == QuranStatus.loaded
                  ? () => _showSurahSheet(context, state)
                  : null,
              onAyahJumpTap: state.status == QuranStatus.loaded
                  ? () => _showAyahJumpDialog(context, state)
                  : null,
            ),
            body: SafeArea(
              top: false,
              bottom: false,
              child: _QuranBody(
                state: state,
                pageController: _pageController,
                searchController: _searchController,
                onSearchChanged: context.read<QuranCubit>().search,
                onClearSearch: context.read<QuranCubit>().clearSearch,
                onResultTap: (result) => _jumpToResult(context, state, result),
                imageCacheService: getIt<QuranPageImageCacheService>(),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _showSurahSheet(BuildContext context, QuranState state) async {
    final cubit = context.read<QuranCubit>();
    final selection = await showModalBottomSheet<QuranSurahSelection>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => QuranSurahSheet(
        surahs: state.surahs,
        currentSurahNumber: state.selectedSurahNumber,
      ),
    );
    if (selection == null || !context.mounted) {
      return;
    }
    final pageNumber = _pageForSelection(state.surahs, selection);
    _searchController.clear();
    cubit.clearSearch();
    await _animateToPageNumber(pageNumber);
    cubit.selectSurah(selection.surahNumber, ayahNumber: selection.ayahNumber);
  }

  Future<void> _showAyahJumpDialog(
    BuildContext context,
    QuranState state,
  ) async {
    final selectedSurah = state.selectedSurah;
    if (selectedSurah == null) {
      return;
    }
    var ayahInput = '';
    final ayahNumber = await showDialog<int>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text('quran.jump_to_ayah'.tr()),
          content: TextField(
            autofocus: true,
            keyboardType: TextInputType.number,
            onChanged: (value) => ayahInput = value,
            decoration: InputDecoration(
              labelText: 'quran.ayah_number'.tr(),
              helperText: '1 - ${selectedSurah.ayahCount}',
            ),
            onSubmitted: (value) =>
                Navigator.pop(dialogContext, int.tryParse(value.trim())),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text('common.cancel'.tr()),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.pop(dialogContext, int.tryParse(ayahInput.trim())),
              child: Text('quran.jump'.tr()),
            ),
          ],
        );
      },
    );
    if (ayahNumber == null || !context.mounted) {
      return;
    }
    final safeAyah = ayahNumber.clamp(1, selectedSurah.ayahCount).toInt();
    int? pageNumber;
    for (final ayah in selectedSurah.ayahs) {
      if (ayah.numberInSurah == safeAyah) {
        pageNumber = ayah.page;
        break;
      }
    }
    if (pageNumber != null) {
      await _animateToPageNumber(pageNumber);
    }
    if (!context.mounted) {
      return;
    }
    context.read<QuranCubit>().selectAyah(safeAyah);
  }

  Future<void> _jumpToResult(
    BuildContext context,
    QuranState state,
    QuranSearchResult result,
  ) async {
    final cubit = context.read<QuranCubit>();
    _searchController.clear();
    cubit.clearSearch();
    await _animateToPageNumber(result.ayah.page);
    cubit.selectSurah(
      result.surah.number,
      ayahNumber: result.ayah.numberInSurah,
    );
  }

  int _pageForSelection(
    List<QuranSurah> surahs,
    QuranSurahSelection selection,
  ) {
    QuranSurah? selectedSurah;
    for (final surah in surahs) {
      if (surah.number == selection.surahNumber) {
        selectedSurah = surah;
        break;
      }
    }
    if (selectedSurah == null || selectedSurah.ayahs.isEmpty) {
      return QuranPageImageCacheService.firstPage;
    }
    final ayahNumber = selection.ayahNumber;
    if (ayahNumber == null) {
      return selectedSurah.ayahs.first.page;
    }
    for (final ayah in selectedSurah.ayahs) {
      if (ayah.numberInSurah == ayahNumber) {
        return ayah.page;
      }
    }
    return selectedSurah.ayahs.first.page;
  }

  Future<void> _animateToPageNumber(int pageNumber) async {
    final safePage = pageNumber
        .clamp(
          QuranPageImageCacheService.firstPage,
          QuranPageImageCacheService.lastPage,
        )
        .toInt();
    if (!_pageController.hasClients) {
      return;
    }
    await _pageController.animateToPage(
      safePage - 1,
      duration: const Duration(milliseconds: 520),
      curve: Curves.easeOutCubic,
    );
  }
}

class _QuranAppBar extends StatelessWidget implements PreferredSizeWidget {
  const _QuranAppBar({
    required this.state,
    required this.onSurahIndexTap,
    required this.onAyahJumpTap,
  });

  final QuranState state;
  final VoidCallback? onSurahIndexTap;
  final VoidCallback? onAyahJumpTap;

  @override
  Size get preferredSize => const Size.fromHeight(72);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = AppThemeColors.of(context);
    return AppBar(
      toolbarHeight: 72,
      titleSpacing: 16,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'quran.title'.tr(),
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          if (state.selectedSurah != null)
            Text(
              '${state.selectedSurah!.englishName} • ${state.selectedSurah!.name}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textDirection: ui.TextDirection.ltr,
              style: theme.textTheme.labelMedium?.copyWith(
                color: colors.mutedText,
                fontWeight: FontWeight.w700,
              ),
            ),
        ],
      ),
      actions: [
        IconButton(
          tooltip: 'quran.surah_index'.tr(),
          onPressed: onSurahIndexTap,
          icon: const Icon(Icons.format_list_bulleted_rounded),
        ),
        IconButton(
          tooltip: 'quran.jump_to_ayah'.tr(),
          onPressed: onAyahJumpTap,
          icon: const Icon(Icons.my_location_rounded),
        ),
        const SizedBox(width: 8),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Divider(
          height: 1,
          color: theme.colorScheme.onSurface.withValues(alpha: 0.08),
        ),
      ),
    );
  }
}

class _QuranBody extends StatelessWidget {
  const _QuranBody({
    required this.state,
    required this.pageController,
    required this.searchController,
    required this.onSearchChanged,
    required this.onClearSearch,
    required this.onResultTap,
    required this.imageCacheService,
  });

  final QuranState state;
  final PageController pageController;
  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onClearSearch;
  final ValueChanged<QuranSearchResult> onResultTap;
  final QuranPageImageCacheService imageCacheService;

  @override
  Widget build(BuildContext context) {
    switch (state.status) {
      case QuranStatus.initial:
      case QuranStatus.loading:
        return const Center(child: CircularProgressIndicator());
      case QuranStatus.failure:
        return _QuranError(message: state.errorMessage);
      case QuranStatus.loaded:
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
              child: QuranSearchBar(
                controller: searchController,
                onChanged: onSearchChanged,
                onClear: onClearSearch,
                hasQuery: state.isSearching,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 2, 16, 4),
              child: _ReadingHint(state: state),
            ),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 260),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                child: state.isSearching
                    ? QuranSearchResults(
                        key: const ValueKey('quran-search-results'),
                        results: state.searchResults,
                        onResultTap: onResultTap,
                      )
                    : _QuranPageView(
                        key: const ValueKey('quran-reader'),
                        state: state,
                        pageController: pageController,
                        imageCacheService: imageCacheService,
                      ),
              ),
            ),
          ],
        );
    }
  }
}

class _QuranPageView extends StatelessWidget {
  const _QuranPageView({
    super.key,
    required this.state,
    required this.pageController,
    required this.imageCacheService,
  });

  final QuranState state;
  final PageController pageController;
  final QuranPageImageCacheService imageCacheService;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<QuranCubit>();
    return PageView.builder(
      controller: pageController,
      physics: const BouncingScrollPhysics(),
      itemCount: QuranPageImageCacheService.lastPage,
      reverse: Directionality.of(context) == ui.TextDirection.rtl,
      onPageChanged: (index) {
        cubit.selectPage(index + 1);
      },
      itemBuilder: (context, index) {
        final pageNumber = index + 1;
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 104),
          child: QuranMushafImagePage(
            pageNumber: pageNumber,
            imageCacheService: imageCacheService,
          ),
        );
      },
    );
  }
}

class _ReadingHint extends StatelessWidget {
  const _ReadingHint({required this.state});

  final QuranState state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = AppThemeColors.of(context);
    return Row(
      children: [
        Icon(Icons.zoom_out_map_rounded, size: 16, color: colors.mutedText),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            '${'quran.image_reader_hint'.tr()} • ${'quran.page'.tr()} ${state.selectedPageNumber}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelMedium?.copyWith(
              color: colors.mutedText,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _QuranError extends StatelessWidget {
  const _QuranError({required this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = AppThemeColors.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 48,
              color: colors.countdownText,
            ),
            const SizedBox(height: 12),
            Text(
              message ?? 'common.failed_load_adhkar'.tr(),
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium,
            ),
          ],
        ),
      ),
    );
  }
}
