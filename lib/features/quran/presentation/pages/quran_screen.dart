import 'dart:async';
import 'dart:ui' as ui;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

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
  Timer? _chromeTimer;
  bool _chromeVisible = true;
  bool _searchVisible = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scheduleChromeHide());
  }

  @override
  void dispose() {
    _chromeTimer?.cancel();
    _pageController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _showChrome({bool scheduleHide = true}) {
    _chromeTimer?.cancel();
    if (mounted && !_chromeVisible) {
      setState(() => _chromeVisible = true);
    }
    if (scheduleHide) {
      _scheduleChromeHide();
    }
  }

  void _scheduleChromeHide() {
    _chromeTimer?.cancel();
    if (_searchVisible || _searchController.text.trim().isNotEmpty) {
      return;
    }
    _chromeTimer = Timer(const Duration(seconds: 4), () {
      if (mounted && !_searchVisible) {
        setState(() => _chromeVisible = false);
      }
    });
  }

  void _toggleSearch(BuildContext context) {
    _chromeTimer?.cancel();
    setState(() {
      _chromeVisible = true;
      _searchVisible = !_searchVisible;
    });
    if (!_searchVisible) {
      _searchController.clear();
      context.read<QuranCubit>().clearSearch();
      _scheduleChromeHide();
    }
  }

  void _clearSearch(BuildContext context) {
    _searchController.clear();
    context.read<QuranCubit>().clearSearch();
    setState(() => _searchVisible = false);
    _scheduleChromeHide();
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
          final imageCacheService = getIt<QuranPageImageCacheService>();
          return Scaffold(
            extendBodyBehindAppBar: true,
            body: SizedBox.expand(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onTap: () => _showChrome(),
                      child: _QuranBody(
                        state: state,
                        pageController: _pageController,
                        imageCacheService: imageCacheService,
                      ),
                    ),
                  ),
                  if (state.isSearching)
                    Positioned.fill(
                      child: _SearchResultsOverlay(
                        state: state,
                        onResultTap: (result) =>
                            _jumpToResult(context, state, result),
                      ),
                    ),
                  _QuranChromeOverlay(
                    visible: _chromeVisible || _searchVisible,
                    searchVisible: _searchVisible,
                    state: state,
                    searchController: _searchController,
                    onBack: () => context.pop(),
                    onTapChrome: () => _showChrome(scheduleHide: !_searchVisible),
                    onToggleSearch: () => _toggleSearch(context),
                    onSearchChanged: (query) {
                      _showChrome(scheduleHide: false);
                      context.read<QuranCubit>().search(query);
                    },
                    onClearSearch: () => _clearSearch(context),
                    onSurahIndexTap: state.status == QuranStatus.loaded
                        ? () => _showSurahSheet(context, state)
                        : null,
                    onAyahJumpTap: state.status == QuranStatus.loaded
                        ? () => _showAyahJumpDialog(context, state)
                        : null,
                  ),
                  _QuranPageIndicator(state: state),
                ],
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
    setState(() => _searchVisible = false);
    await _animateToPageNumber(pageNumber);
    cubit.selectSurah(selection.surahNumber, ayahNumber: selection.ayahNumber);
    _scheduleChromeHide();
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
    setState(() => _searchVisible = false);
    await _animateToPageNumber(result.ayah.page);
    cubit.selectSurah(
      result.surah.number,
      ayahNumber: result.ayah.numberInSurah,
    );
    _scheduleChromeHide();
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

class _QuranChromeOverlay extends StatelessWidget {
  const _QuranChromeOverlay({
    required this.visible,
    required this.searchVisible,
    required this.state,
    required this.searchController,
    required this.onBack,
    required this.onTapChrome,
    required this.onToggleSearch,
    required this.onSearchChanged,
    required this.onClearSearch,
    required this.onSurahIndexTap,
    required this.onAyahJumpTap,
  });

  final bool visible;
  final bool searchVisible;
  final QuranState state;
  final TextEditingController searchController;
  final VoidCallback onBack;
  final VoidCallback onTapChrome;
  final VoidCallback onToggleSearch;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onClearSearch;
  final VoidCallback? onSurahIndexTap;
  final VoidCallback? onAyahJumpTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = AppThemeColors.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AnimatedSlide(
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
      offset: visible ? Offset.zero : const Offset(0, -1.15),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 260),
        opacity: visible ? 1 : 0,
        child: SafeArea(
          bottom: false,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onTapChrome,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: colors.cardSurface.withValues(
                    alpha: isDark ? 0.92 : 0.96,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: colors.softBorder),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(
                        alpha: isDark ? 0.34 : 0.1,
                      ),
                      blurRadius: 22,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(6, 8, 6, 8),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          IconButton(
                            tooltip: MaterialLocalizations.of(
                              context,
                            ).backButtonTooltip,
                            onPressed: onBack,
                            icon: const Icon(Icons.arrow_back_rounded),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'quran.title'.tr(),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                Text(
                                  state.selectedSurah == null
                                      ? '${'quran.page'.tr()} ${state.selectedPageNumber}'
                                      : '${state.selectedSurah!.name} • ${'quran.page'.tr()} ${state.selectedPageNumber}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textDirection: ui.TextDirection.rtl,
                                  style: theme.textTheme.labelMedium?.copyWith(
                                    color: colors.mutedText,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            tooltip: 'quran.search'.tr(),
                            onPressed: onToggleSearch,
                            icon: Icon(
                              searchVisible
                                  ? Icons.close_rounded
                                  : Icons.search_rounded,
                            ),
                          ),
                          IconButton(
                            tooltip: 'quran.surah_index'.tr(),
                            onPressed: onSurahIndexTap,
                            icon: const Icon(
                              Icons.format_list_bulleted_rounded,
                            ),
                          ),
                          IconButton(
                            tooltip: 'quran.jump_to_ayah'.tr(),
                            onPressed: onAyahJumpTap,
                            icon: const Icon(Icons.my_location_rounded),
                          ),
                        ],
                      ),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 220),
                        child: searchVisible
                            ? Padding(
                                key: const ValueKey('quran-search-field'),
                                padding: const EdgeInsets.fromLTRB(
                                  10,
                                  2,
                                  10,
                                  8,
                                ),
                                child: QuranSearchBar(
                                  controller: searchController,
                                  autofocus: true,
                                  onChanged: onSearchChanged,
                                  onClear: onClearSearch,
                                  hasQuery: state.isSearching,
                                ),
                              )
                            : const SizedBox.shrink(
                                key: ValueKey('quran-search-hidden'),
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _QuranBody extends StatelessWidget {
  const _QuranBody({
    required this.state,
    required this.pageController,
    required this.imageCacheService,
  });

  final QuranState state;
  final PageController pageController;
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
        return _QuranPageView(
          state: state,
          pageController: pageController,
          imageCacheService: imageCacheService,
        );
    }
  }
}

class _SearchResultsOverlay extends StatelessWidget {
  const _SearchResultsOverlay({required this.state, required this.onResultTap});

  final QuranState state;
  final ValueChanged<QuranSearchResult> onResultTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final top = MediaQuery.paddingOf(context).top + 116;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor.withValues(alpha: 0.94),
      ),
      child: Padding(
        padding: EdgeInsets.only(top: top),
        child: QuranSearchResults(
          results: state.searchResults,
          onResultTap: onResultTap,
        ),
      ),
    );
  }
}

class _QuranPageView extends StatelessWidget {
  const _QuranPageView({
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
          padding: EdgeInsets.fromLTRB(
            8,
            MediaQuery.paddingOf(context).top + 8,
            8,
            MediaQuery.paddingOf(context).bottom + 8,
          ),
          child: SizedBox.expand(
            child: QuranMushafImagePage(
              pageNumber: pageNumber,
              imageCacheService: imageCacheService,
            ),
          ),
        );
      },
    );
  }
}

class _QuranPageIndicator extends StatelessWidget {
  const _QuranPageIndicator({required this.state});

  final QuranState state;

  @override
  Widget build(BuildContext context) {
    final colors = AppThemeColors.of(context);
    final theme = Theme.of(context);
    return PositionedDirectional(
      bottom: MediaQuery.paddingOf(context).bottom + 14,
      end: 14,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.cardSurface.withValues(alpha: 0.78),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: colors.softBorder),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          child: Text(
            '${'quran.page'.tr()} ${state.selectedPageNumber}',
            style: theme.textTheme.labelMedium?.copyWith(
              color: colors.secondaryText,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
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
