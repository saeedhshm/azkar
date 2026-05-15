import 'dart:async';
import 'dart:ui' as ui;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/storage/local_storage_service.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/datasources/quran_recently_read_service.dart';
import '../../domain/entities/ayah_highlight.dart';
import '../../domain/entities/quran_search_result.dart';
import '../../domain/entities/quran_selected_ayah.dart';
import '../../domain/entities/quran_surah.dart';
import '../../domain/repositories/quran_last_read_repository.dart';
import '../../audio/domain/entities/reciter.dart';
import '../../presentation/cubit/quran_ayah_selection_cubit.dart';
import '../../presentation/cubit/quran_ayah_selection_state.dart';
import '../../audio/presentation/cubit/quran_audio_cubit.dart';
import '../../audio/presentation/cubit/quran_audio_state.dart';
import '../../audio/presentation/widgets/quran_playback_controls.dart';
import '../../presentation/cubit/quran_cubit.dart';
import '../../presentation/cubit/quran_highlight_cubit.dart';
import '../../presentation/cubit/quran_state.dart';
import '../../actions/presentation/widgets/ayah_actions_sheet.dart';
import '../../services/quran_juz_data.dart';
import '../../services/quran_svg_page_service.dart';
import '../../widgets/quran_bookmarks_sheet.dart';
import '../../widgets/quran_juz_sheet.dart';
import '../../widgets/quran_quick_nav_bar.dart';
import '../../widgets/quran_reader_page_indicator.dart';
import '../../widgets/quran_reader_page_view.dart';
import '../../widgets/quran_recently_read_sheet.dart';
import '../widgets/quran_search_bar.dart';
import '../widgets/quran_search_results.dart';
import '../widgets/quran_surah_sheet.dart';

class QuranReaderScreen extends StatefulWidget {
  const QuranReaderScreen({super.key, this.initialPageNumber});

  final int? initialPageNumber;

  @override
  State<QuranReaderScreen> createState() => _QuranReaderScreenState();
}

class _QuranReaderScreenState extends State<QuranReaderScreen>
    with WidgetsBindingObserver {
  final _searchController = TextEditingController();
  final _pageService = getIt<QuranSvgPageService>();
  final _recentlyRead = getIt<QuranRecentlyReadService>();
  final _lastReadRepo = getIt<QuranLastReadRepository>();
  Timer? _chromeTimer;
  late final int _resolvedInitialPage;
  late final PageController _pageController;
  bool _chromeVisible = true;
  bool _searchVisible = false;
  bool _isAyahSheetOpen = false;
  bool _readingMode = false;
  bool _fullscreen = false;
  bool _dimmed = false;
  double _dimIntensity = 0.35;
  double _warmthIntensity = 0.0;
  int _currentPage = 1;
  bool _showZoomHint = false;
  Timer? _zoomHintTimer;
  bool _continuousScroll = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _resolvedInitialPage = _pageService.clampPage(
      widget.initialPageNumber ??
          getIt<LocalStorageService>().getQuranLastPage() ??
          QuranSvgPageService.firstPage,
    );
    _currentPage = _resolvedInitialPage;
    _pageController = PageController(initialPage: _resolvedInitialPage - 1);
    _readingMode = getIt<LocalStorageService>().getRaw(
      AppConstants.quranReadingModeKey,
    ) as bool? ?? false;
    _dimmed = getIt<LocalStorageService>().getRaw(
      AppConstants.quranDimModeKey,
    ) as bool? ?? false;
    _dimIntensity = getIt<LocalStorageService>().getRaw(
      AppConstants.quranDimIntensityKey,
    ) as double? ?? 0.35;
    _continuousScroll = getIt<LocalStorageService>().getRaw(
      AppConstants.quranContinuousScrollKey,
    ) as bool? ?? false;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _pageService.preloadWindow(_resolvedInitialPage, radius: 3);
      _scheduleChromeHide();
      _showInitialZoomHint();
    });
  }

  void _showInitialZoomHint() {
    _showZoomHint = true;
    _zoomHintTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() => _showZoomHint = false);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _chromeTimer?.cancel();
    _zoomHintTimer?.cancel();
    _searchController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _lastReadRepo.saveLastPage(_currentPage);
    }
  }

  void _showChrome({bool scheduleHide = true}) {
    _chromeTimer?.cancel();
    if (mounted && !_chromeVisible && !_readingMode) {
      setState(() => _chromeVisible = true);
    }
    if (scheduleHide && !_readingMode) {
      _scheduleChromeHide();
    }
  }

  void _scheduleChromeHide() {
    _chromeTimer?.cancel();
    if (_searchVisible || _searchController.text.trim().isNotEmpty) {
      return;
    }
    _chromeTimer = Timer(const Duration(seconds: 4), () {
      if (mounted && !_searchVisible && !_readingMode) {
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

  void _toggleReadingMode() {
    setState(() {
      _readingMode = !_readingMode;
      if (_readingMode) {
        _chromeVisible = false;
        _searchVisible = false;
        _chromeTimer?.cancel();
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
        SystemChrome.setSystemUIOverlayStyle(
          const SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            systemNavigationBarColor: Colors.transparent,
          ),
        );
      } else {
        _chromeVisible = true;
        _restoreSystemUI();
        _scheduleChromeHide();
      }
    });
    getIt<LocalStorageService>().putRaw(
      AppConstants.quranReadingModeKey,
      _readingMode,
    );
  }

  void _toggleFullscreen() {
    setState(() {
      _fullscreen = !_fullscreen;
    });
    if (_fullscreen) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: Colors.transparent,
      ));
    } else {
      _restoreSystemUI();
    }
  }

  void _restoreSystemUI() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness:
          Theme.of(context).brightness == Brightness.dark
              ? Brightness.light
              : Brightness.dark,
    ));
  }

  void _toggleDimmed() {
    setState(() {
      _dimmed = !_dimmed;
    });
    getIt<LocalStorageService>().putRaw(
      AppConstants.quranDimModeKey,
      _dimmed,
    );
  }

  void _adjustDimIntensity(double value) {
    setState(() => _dimIntensity = value);
    getIt<LocalStorageService>().putRaw(
      AppConstants.quranDimIntensityKey,
      _dimIntensity,
    );
  }

  void _adjustWarmth(double value) {
    setState(() => _warmthIntensity = value);
  }

  void _toggleContinuousScroll() {
    setState(() => _continuousScroll = !_continuousScroll);
    getIt<LocalStorageService>().putRaw(
      AppConstants.quranContinuousScrollKey,
      _continuousScroll,
    );
  }

  void _onPageChanged(int pageNumber) {
    setState(() => _currentPage = pageNumber);
    context.read<QuranCubit>().selectPage(pageNumber);
  }

  Future<void> _showBookmarksSheet(BuildContext context) async {
    final cubit = context.read<QuranCubit>();
    await showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      showDragHandle: true,
      builder: (_) => QuranBookmarksSheet(
        onNavigate: (pageNumber, surahNumber, ayahNumber) {
          Navigator.pop(context);
          _animateToPageNumber(pageNumber).then((_) {
            cubit.selectSurah(surahNumber, ayahNumber: ayahNumber);
          });
        },
      ),
    );
  }

  void _showQuickSurahSheet(BuildContext context, QuranState state) {
    _showSurahSheet(context, state);
  }

  void _showJuzSheet(BuildContext context) {
    final currentJuz = QuranJuzData.juzForPage(_currentPage);
    showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => QuranJuzSheet(
        currentJuz: currentJuz,
        onJuzSelected: (juzNumber, pageNumber) {
          Navigator.pop(context);
          _animateToPageNumber(pageNumber);
        },
      ),
    );
  }

  void _showRecentlyReadSheet(BuildContext context, QuranState state) {
    final cubit = context.read<QuranCubit>();
    showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      showDragHandle: true,
      builder: (_) => QuranRecentlyReadSheet(
        surahs: state.surahs,
        onNavigate: (pageNumber, surahNumber, ayahNumber) {
          Navigator.pop(context);
          _animateToPageNumber(pageNumber).then((_) {
            cubit.selectSurah(surahNumber, ayahNumber: ayahNumber);
          });
        },
      ),
    );
  }

  void _handleAyahLongPress(QuranSelectedAyah selectedAyah) {
    HapticFeedback.heavyImpact();
    final quranCubit = context.read<QuranCubit>();
    final audioCubit = context.read<QuranAudioCubit>();
    final highlightCubit = context.read<QuranHighlightCubit>();
    _selectedAyahForText = selectedAyah;
    final quranState = quranCubit.state;
    final surahName = _surahNameForSelection(
      quranState.surahs,
      selectedAyah.surahNumber,
    );
    final ayahText = _lookupAyahText(quranState);
    final audioState = audioCubit.state;

    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      builder: (sheetContext) => AyahActionsSheet(
        selectedAyah: selectedAyah,
        surahName: surahName,
        ayahText: ayahText,
        isBookmarked: highlightCubit.isBookmarked(
          selectedAyah.surahNumber,
          selectedAyah.ayahNumber,
        ),
        isFavoriteReciter: audioCubit.isFavoriteReciter(
          audioState.reciter ?? audioCubit.getFavoriteReciter() ?? Reciter.defaults.first,
        ),
        onToggleBookmark: () {
          highlightCubit.toggleBookmarkHighlight(
            AyahHighlight(
              id: 'bookmark-${selectedAyah.surahNumber}:${selectedAyah.ayahNumber}',
              polygonId: selectedAyah.polygonId,
              pageNumber: selectedAyah.pageNumber,
              surahNumber: selectedAyah.surahNumber,
              ayahNumber: selectedAyah.ayahNumber,
              type: AyahHighlightType.bookmark,
            ),
          );
        },
        onPlayAyah: () {
          audioCubit.playWithFavoriteReciter(selectedAyah.surahNumber).then((_) {
            audioCubit.seekToAyah(selectedAyah.ayahNumber);
          });
        },
        onToggleFavoriteReciter: () {
          final currentReciter = audioState.reciter;
          if (currentReciter != null) {
            if (audioCubit.isFavoriteReciter(currentReciter)) {
              audioCubit.setReciter(currentReciter);
            } else {
              audioCubit.setFavoriteReciter(currentReciter);
            }
          }
        },
      ),
    );
  }

  void _trackRecentlyRead(int surahNumber, int ayahNumber) {
    _recentlyRead.addEntry(_currentPage, surahNumber, ayahNumber);
  }

  void _onSwipeUp() {
    if (_chromeVisible && !_readingMode) {
      setState(() => _chromeVisible = false);
    }
  }

  void _onSwipeDown() {
    if (!_chromeVisible && !_readingMode) {
      _showChrome();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) =>
              getIt<QuranCubit>()
                ..load(initialPageNumber: _resolvedInitialPage),
        ),
        BlocProvider(create: (_) => getIt<QuranAyahSelectionCubit>()),
        BlocProvider(create: (_) => getIt<QuranHighlightCubit>()),
        BlocProvider(create: (_) => getIt<QuranAudioCubit>()),
      ],
      child: MultiBlocListener(
        listeners: [
          BlocListener<QuranCubit, QuranState>(
            listenWhen: (previous, current) => previous.query != current.query,
            listener: (context, state) {
              if (state.query.isEmpty && _searchController.text.isNotEmpty) {
                _searchController.clear();
              }
            },
          ),
          BlocListener<QuranAyahSelectionCubit, QuranAyahSelectionState>(
            listenWhen: (previous, current) =>
                previous.selectedAyah != current.selectedAyah,
            listener: (context, state) {
              final selectedAyah = state.selectedAyah;
              if (selectedAyah == null || _isAyahSheetOpen) {
                return;
              }
              _trackRecentlyRead(
                selectedAyah.surahNumber,
                selectedAyah.ayahNumber,
              );
              unawaited(_showAyahBottomSheet(context, selectedAyah));
            },
          ),
          BlocListener<QuranCubit, QuranState>(
            listenWhen: (previous, current) =>
                previous.status != current.status,
            listener: (context, state) {
              if (state.status == QuranStatus.loaded) {
                context.read<QuranAudioCubit>().onPageNeeded = _animateToPageNumber;
                context.read<QuranAudioCubit>().setSurahs(state.surahs);
                _restoreFavoriteReciter();
              }
            },
          ),
          BlocListener<QuranCubit, QuranState>(
            listenWhen: (previous, current) =>
                previous.searchResults != current.searchResults,
            listener: (context, state) {
              final highlightCubit = context.read<QuranHighlightCubit>();
              if (state.query.isEmpty || state.searchResults.isEmpty) {
                highlightCubit.clearSearchHighlights();
                return;
              }
              final highlights = state.searchResults.map((result) {
                return AyahHighlight(
                  id: 'search-${result.ayah.globalNumber}',
                  polygonId: result.ayah.ayahKey,
                  pageNumber: result.ayah.page,
                  surahNumber: result.surah.number,
                  ayahNumber: result.ayah.numberInSurah,
                  type: AyahHighlightType.search,
                  searchQuery: state.query,
                );
              }).toList();
              highlightCubit.addSearchHighlights(highlights);
            },
          ),
          BlocListener<QuranAudioCubit, QuranAudioState>(
            listenWhen: (previous, current) =>
                previous.currentAyahNumber != current.currentAyahNumber &&
                current.currentAyahNumber > 0,
            listener: (context, state) {
              final highlightCubit = context.read<QuranHighlightCubit>();
              final quranState = context.read<QuranCubit>().state;

              int? pageNumber;
              for (final surah in quranState.surahs) {
                if (surah.number == state.currentSurahNumber) {
                  for (final ayah in surah.ayahs) {
                    if (ayah.numberInSurah == state.currentAyahNumber) {
                      pageNumber = ayah.page;
                      break;
                    }
                  }
                }
              }

              highlightCubit.setReadingHighlight(
                AyahHighlight(
                  id: 'reading-${state.currentSurahNumber}:${state.currentAyahNumber}',
                  polygonId: '${state.currentSurahNumber}:${state.currentAyahNumber}',
                  pageNumber: pageNumber ?? 0,
                  surahNumber: state.currentSurahNumber,
                  ayahNumber: state.currentAyahNumber,
                  type: AyahHighlightType.reading,
                ),
              );
            },
          ),
        ],
        child: Scaffold(
          extendBodyBehindAppBar: true,
          body: SizedBox.expand(
            child: Stack(
              children: [
                Positioned.fill(
                  child: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onTap: () => _showChrome(),
                    onVerticalDragEnd: (details) {
                      if (details.primaryVelocity != null) {
                        if (details.primaryVelocity! < -300) {
                          _onSwipeUp();
                        } else if (details.primaryVelocity! > 300) {
                          _onSwipeDown();
                        }
                      }
                    },
                    onHorizontalDragEnd: (details) {
                      if (!_readingMode && details.primaryVelocity != null) {
                        if (details.primaryVelocity! < -200) {
                          HapticFeedback.lightImpact();
                        } else if (details.primaryVelocity! > 200) {
                          HapticFeedback.lightImpact();
                        }
                      }
                    },
                    child: BlocBuilder<QuranCubit, QuranState>(
                      buildWhen: (previous, current) =>
                          previous.status != current.status,
                      builder: (context, state) {
                        switch (state.status) {
                          case QuranStatus.initial:
                          case QuranStatus.loading:
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          case QuranStatus.failure:
                            return _QuranError(
                              message: state.errorMessage,
                            );
                          case QuranStatus.loaded:
                            return QuranReaderPageView(
                              pageController: _pageController,
                              pageService: _pageService,
                              onPageChanged: _onPageChanged,
                              onAyahLongPress: _handleAyahLongPress,
                              readingMode: _readingMode && _continuousScroll,
                            );
                        }
                      },
                    ),
                  ),
                ),
                if (_dimmed)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: Container(
                        color: Colors.black.withValues(alpha: _dimIntensity),
                      ),
                    ),
                  ),
                if (_warmthIntensity > 0)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: Container(
                        color: Color.fromRGBO(
                          255,
                          180 - (_warmthIntensity * 80).toInt(),
                          120 - (_warmthIntensity * 120).toInt(),
                          _warmthIntensity * 0.3,
                        ),
                      ),
                    ),
                  ),
                if (_showZoomHint)
                  Positioned(
                    top: MediaQuery.paddingOf(context).top + 120,
                    left: 0,
                    right: 0,
                    child: IgnorePointer(
                      child: Center(
                        child: AnimatedOpacity(
                          opacity: _showZoomHint ? 1 : 0,
                          duration: const Duration(milliseconds: 500),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.pinch_rounded,
                                  color: Colors.white70,
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'quran.zoom_hint'.tr(),
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                BlocBuilder<QuranCubit, QuranState>(
                  buildWhen: (previous, current) =>
                      previous.query != current.query ||
                      previous.searchResults != current.searchResults,
                  builder: (context, state) {
                    if (!state.isSearching) {
                      return const SizedBox.shrink();
                    }
                    return Positioned.fill(
                      child: _SearchResultsOverlay(
                        state: state,
                        onResultTap: (result) =>
                            _jumpToResult(context, state, result),
                      ),
                    );
                  },
                ),
                BlocBuilder<QuranCubit, QuranState>(
                  buildWhen: (previous, current) =>
                      previous.status != current.status ||
                      previous.selectedPageNumber !=
                          current.selectedPageNumber ||
                      previous.selectedSurahNumber !=
                          current.selectedSurahNumber,
                  builder: (context, state) {
                    return _QuranChromeOverlay(
                      visible: (_chromeVisible || _searchVisible) &&
                          !_readingMode,
                      searchVisible: _searchVisible,
                      readingMode: _readingMode,
                      fullscreen: _fullscreen,
                      dimmed: _dimmed,
                      dimIntensity: _dimIntensity,
                      warmthIntensity: _warmthIntensity,
                      continuousScroll: _continuousScroll,
                      state: state,
                      searchController: _searchController,
                      onBack: () => context.pop(),
                      onTapChrome: () =>
                          _showChrome(scheduleHide: !_searchVisible),
                      onToggleSearch: () => _toggleSearch(context),
                      onSearchChanged: (query) {
                        _showChrome(scheduleHide: false);
                        context.read<QuranCubit>().search(query);
                      },
                      onClearSearch: () => _clearSearch(context),
                      onBookmarksTap: state.status == QuranStatus.loaded
                          ? () => _showBookmarksSheet(context)
                          : null,
                      onSurahIndexTap: state.status == QuranStatus.loaded
                          ? () => _showQuickSurahSheet(context, state)
                          : null,
                      onAyahJumpTap: state.status == QuranStatus.loaded
                          ? () => _showAyahJumpDialog(context, state)
                          : null,
                      onJuzTap: state.status == QuranStatus.loaded
                          ? () => _showJuzSheet(context)
                          : null,
                      onRecentlyReadTap: state.status == QuranStatus.loaded
                          ? () => _showRecentlyReadSheet(context, state)
                          : null,
                      onToggleReadingMode: _toggleReadingMode,
                      onToggleFullscreen: _toggleFullscreen,
                      onToggleDimmed: _toggleDimmed,
                      onDimIntensityChanged: _dimmed ? _adjustDimIntensity : null,
                      onWarmthChanged: _adjustWarmth,
                      onToggleContinuousScroll: _toggleContinuousScroll,
                    );
                  },
                ),
                Positioned(
                  bottom: MediaQuery.paddingOf(context).bottom + 60,
                  left: 12,
                  right: 12,
                  child: QuranPlaybackControls(),
                ),
                if (!_readingMode)
                  PositionedDirectional(
                    bottom: MediaQuery.paddingOf(context).bottom + 14,
                    end: 14,
                    child: BlocBuilder<QuranCubit, QuranState>(
                      buildWhen: (previous, current) =>
                          previous.status != current.status ||
                          previous.selectedPageNumber !=
                              current.selectedPageNumber,
                      builder: (context, state) {
                        if (state.status != QuranStatus.loaded) {
                          return const SizedBox.shrink();
                        }
                        return QuranReaderPageIndicator(
                          pageNumber: _currentPage,
                        );
                      },
                    ),
                  ),
                BlocBuilder<QuranCubit, QuranState>(
                  buildWhen: (previous, current) =>
                      previous.status != current.status ||
                      previous.selectedSurahNumber !=
                          current.selectedSurahNumber,
                  builder: (context, s) {
                    if (s.status != QuranStatus.loaded) {
                      return const SizedBox.shrink();
                    }
                    return PositionedDirectional(
                      bottom: MediaQuery.paddingOf(context).bottom + 14,
                      start: 14,
                      child: _QuickNavBar(
                        currentPage: _currentPage,
                        currentSurahName: s.selectedSurah?.name ?? '',
                        currentSurahNumber: s.selectedSurahNumber,
                        onSurahTap: () => _showQuickSurahSheet(context, s),
                        onJuzTap: () => _showJuzSheet(context),
                        onPageTap: () => _showAyahJumpDialog(context, s),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _restoreFavoriteReciter() {
    final storage = getIt<LocalStorageService>();
    final faveReciterId =
        storage.getRaw(AppConstants.quranFavoriteReciterKey) as String?;
    if (faveReciterId != null) {
      final reciter = Reciter.defaults.cast<Reciter?>().firstWhere(
        (r) => r!.id == faveReciterId,
        orElse: () => null,
      );
      if (reciter != null && mounted) {
        context.read<QuranAudioCubit>().setReciter(reciter);
      }
    }
  }

  Future<void> _showAyahBottomSheet(
    BuildContext context,
    QuranSelectedAyah selectedAyah,
  ) async {
    _isAyahSheetOpen = true;
    _selectedAyahForText = selectedAyah;
    final selectionCubit = context.read<QuranAyahSelectionCubit>();
    final highlightCubit = context.read<QuranHighlightCubit>();
    final audioCubit = context.read<QuranAudioCubit>();
    final quranCubit = context.read<QuranCubit>();
    final quranState = quranCubit.state;
    final surahName = _surahNameForSelection(
      quranState.surahs,
      selectedAyah.surahNumber,
    );
    final ayahText = _lookupAyahText(quranState);
    final audioState = audioCubit.state;

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      builder: (sheetContext) {
        return AyahActionsSheet(
          selectedAyah: selectedAyah,
          surahName: surahName,
          ayahText: ayahText,
          isBookmarked: highlightCubit.isBookmarked(
            selectedAyah.surahNumber,
            selectedAyah.ayahNumber,
          ),
          isFavoriteReciter: audioCubit.isFavoriteReciter(
            audioState.reciter ?? audioCubit.getFavoriteReciter() ?? Reciter.defaults.first,
          ),
          onToggleBookmark: () {
            highlightCubit.toggleBookmarkHighlight(
              AyahHighlight(
                id: 'bookmark-${selectedAyah.surahNumber}:${selectedAyah.ayahNumber}',
                polygonId: selectedAyah.polygonId,
                pageNumber: selectedAyah.pageNumber,
                surahNumber: selectedAyah.surahNumber,
                ayahNumber: selectedAyah.ayahNumber,
                type: AyahHighlightType.bookmark,
              ),
            );
          },
          onPlayAyah: () {
            audioCubit.playWithFavoriteReciter(selectedAyah.surahNumber).then((_) {
              audioCubit.seekToAyah(selectedAyah.ayahNumber);
            });
          },
          onToggleFavoriteReciter: () {
            final currentReciter = audioState.reciter;
            if (currentReciter != null) {
              if (audioCubit.isFavoriteReciter(currentReciter)) {
                audioCubit.setReciter(currentReciter);
              } else {
                audioCubit.setFavoriteReciter(currentReciter);
              }
            }
          },
        );
      },
    );

    _isAyahSheetOpen = false;
    selectionCubit.clearSelection();
    highlightCubit.clearTapHighlight();
  }

  String _surahNameForSelection(List<QuranSurah> surahs, int surahNumber) {
    for (final surah in surahs) {
      if (surah.number == surahNumber) {
        return surah.name;
      }
    }
    return 'quran.unknown_surah'.tr();
  }

  QuranSelectedAyah? _selectedAyahForText;

  String _lookupAyahText(QuranState quranState) {
    if (quranState.status != QuranStatus.loaded) return '...';
    final sNum = _selectedAyahForText?.surahNumber;
    final aNum = _selectedAyahForText?.ayahNumber;
    if (sNum == null || aNum == null) return '...';
    for (final surah in quranState.surahs) {
      if (surah.number == sNum) {
        for (final ayah in surah.ayahs) {
          if (ayah.numberInSurah == aNum) {
            return ayah.text;
          }
        }
      }
    }
    return 'quran.ayah_text_unavailable'.tr();
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
    _trackRecentlyRead(selection.surahNumber, selection.ayahNumber ?? 1);
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
      return QuranSvgPageService.firstPage;
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
    final safePage = _pageService.clampPage(pageNumber);
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
    required this.readingMode,
    required this.fullscreen,
    required this.dimmed,
    required this.dimIntensity,
    required this.warmthIntensity,
    required this.continuousScroll,
    required this.state,
    required this.searchController,
    required this.onBack,
    required this.onTapChrome,
    required this.onToggleSearch,
    required this.onSearchChanged,
    required this.onClearSearch,
    required this.onBookmarksTap,
    required this.onSurahIndexTap,
    required this.onAyahJumpTap,
    required this.onJuzTap,
    required this.onRecentlyReadTap,
    required this.onToggleReadingMode,
    required this.onToggleFullscreen,
    required this.onToggleDimmed,
    this.onDimIntensityChanged,
    this.onWarmthChanged,
    this.onToggleContinuousScroll,
  });

  final bool visible;
  final bool searchVisible;
  final bool readingMode;
  final bool fullscreen;
  final bool dimmed;
  final double dimIntensity;
  final double warmthIntensity;
  final bool continuousScroll;
  final QuranState state;
  final TextEditingController searchController;
  final VoidCallback onBack;
  final VoidCallback onTapChrome;
  final VoidCallback onToggleSearch;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onClearSearch;
  final VoidCallback? onBookmarksTap;
  final VoidCallback? onSurahIndexTap;
  final VoidCallback? onAyahJumpTap;
  final VoidCallback? onJuzTap;
  final VoidCallback? onRecentlyReadTap;
  final VoidCallback? onToggleReadingMode;
  final VoidCallback? onToggleFullscreen;
  final VoidCallback? onToggleDimmed;
  final ValueChanged<double>? onDimIntensityChanged;
  final ValueChanged<double>? onWarmthChanged;
  final VoidCallback? onToggleContinuousScroll;

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
                                  style:
                                      theme.textTheme.titleMedium?.copyWith(
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
                                  style:
                                      theme.textTheme.labelMedium?.copyWith(
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
                            tooltip: 'quran.bookmarks_title'.tr(),
                            onPressed: onBookmarksTap,
                            icon: const Icon(Icons.bookmark_rounded),
                          ),
                          IconButton(
                            tooltip: 'quran.surah_index'.tr(),
                            onPressed: onSurahIndexTap,
                            icon: const Icon(
                              Icons.format_list_bulleted_rounded,
                            ),
                          ),
                          PopupMenuButton<String>(
                            tooltip: 'common.more'.tr(),
                            icon: const Icon(Icons.more_vert_rounded),
                            onSelected: (value) {
                              switch (value) {
                                case 'juz':
                                  onJuzTap?.call();
                                case 'recent':
                                  onRecentlyReadTap?.call();
                                case 'reading_mode':
                                  onToggleReadingMode?.call();
                                case 'fullscreen':
                                  onToggleFullscreen?.call();
                                case 'dim':
                                  onToggleDimmed?.call();
                              }
                            },
                            itemBuilder: (context) => [
                              PopupMenuItem(
                                value: 'juz',
                                child: ListTile(
                                  dense: true,
                                  leading: const Icon(
                                    Icons.auto_stories_rounded,
                                  ),
                                  title: Text('quran.jump_to_juz'.tr()),
                                  contentPadding: EdgeInsets.zero,
                                ),
                              ),
                              PopupMenuItem(
                                value: 'recent',
                                child: ListTile(
                                  dense: true,
                                  leading: const Icon(
                                    Icons.history_rounded,
                                  ),
                                  title: Text('quran.recently_read'.tr()),
                                  contentPadding: EdgeInsets.zero,
                                ),
                              ),
                              PopupMenuItem(
                                value: 'reading_mode',
                                child: ListTile(
                                  dense: true,
                                  leading: Icon(
                                    readingMode
                                        ? Icons.touch_app_rounded
                                        : Icons.chrome_reader_mode_rounded,
                                  ),
                                  title: Text(
                                    readingMode
                                        ? 'quran.exit_reading_mode'.tr()
                                        : 'quran.reading_mode'.tr(),
                                  ),
                                  contentPadding: EdgeInsets.zero,
                                ),
                              ),
                              PopupMenuItem(
                                value: 'fullscreen',
                                child: ListTile(
                                  dense: true,
                                  leading: Icon(
                                    fullscreen
                                        ? Icons.fullscreen_exit_rounded
                                        : Icons.fullscreen_rounded,
                                  ),
                                  title: Text(
                                    fullscreen
                                        ? 'quran.exit_fullscreen'.tr()
                                        : 'quran.fullscreen'.tr(),
                                  ),
                                  contentPadding: EdgeInsets.zero,
                                ),
                              ),
                              PopupMenuItem(
                                value: 'dim',
                                child: ListTile(
                                  dense: true,
                                  leading: Icon(
                                    dimmed
                                        ? Icons.brightness_high_rounded
                                        : Icons.brightness_medium_rounded,
                                  ),
                                  title: Text(
                                    dimmed
                                        ? 'quran.dim_off'.tr()
                                        : 'quran.dim_on'.tr(),
                                  ),
                                  contentPadding: EdgeInsets.zero,
                                ),
                              ),
                            ],
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

class _QuickNavBar extends StatelessWidget {
  const _QuickNavBar({
    required this.currentPage,
    required this.currentSurahName,
    required this.currentSurahNumber,
    required this.onSurahTap,
    required this.onJuzTap,
    required this.onPageTap,
  });

  final int currentPage;
  final String currentSurahName;
  final int currentSurahNumber;
  final VoidCallback onSurahTap;
  final VoidCallback onJuzTap;
  final VoidCallback onPageTap;

  @override
  Widget build(BuildContext context) {
    return QuranQuickNavBar(
      currentPage: currentPage,
      currentSurahName: currentSurahName,
      currentSurahNumber: currentSurahNumber,
      onSurahTap: onSurahTap,
      onJuzTap: onJuzTap,
      onPageTap: onPageTap,
    );
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
