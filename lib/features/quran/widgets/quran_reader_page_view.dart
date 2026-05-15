import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';

import '../domain/entities/quran_selected_ayah.dart';
import '../services/quran_svg_page_service.dart';
import 'quran_interactive_mushaf_page.dart';

class QuranReaderPageView extends StatefulWidget {
  const QuranReaderPageView({
    super.key,
    required this.pageController,
    required this.pageService,
    required this.onPageChanged,
    this.onAyahLongPress,
    this.readingMode = false,
  });

  final PageController pageController;
  final QuranSvgPageService pageService;
  final ValueChanged<int> onPageChanged;
  final void Function(QuranSelectedAyah selectedAyah)? onAyahLongPress;
  final bool readingMode;

  @override
  State<QuranReaderPageView> createState() => _QuranReaderPageViewState();
}

class _QuranReaderPageViewState extends State<QuranReaderPageView>
    with TickerProviderStateMixin {
  late int _currentPage;
  late AnimationController _flipController;
  late Animation<double> _flipAnimation;
  late AnimationController _shadowController;
  late Animation<double> _shadowAnimation;
  bool _isTransitioning = false;

  @override
  void initState() {
    super.initState();
    _currentPage = widget.pageController.initialPage + 1;
    _prefetchWindow(_currentPage, radius: 3);
    _flipController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _flipAnimation = CurvedAnimation(
      parent: _flipController,
      curve: Curves.easeOutCubic,
    );
    _shadowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _shadowAnimation = CurvedAnimation(
      parent: _shadowController,
      curve: Curves.easeOutCubic,
    );
    widget.pageController.addListener(_onPageControllerUpdate);
  }

  void _prefetchWindow(int pageNumber, {int radius = 2}) {
    widget.pageService.preloadWindow(pageNumber, radius: radius);
  }

  void _onPageControllerUpdate() {
    if (!widget.pageController.hasClients) return;
    final page = widget.pageController.page ?? _currentPage.toDouble();
    final isNear = (page - (_currentPage - 1)).abs() > 0.25;
    if (isNear && !_isTransitioning) {
      setState(() => _isTransitioning = true);
      _flipController.forward(from: 0);
      _shadowController.forward(from: 0);
    } else if (!isNear && _isTransitioning) {
      _flipController.reverse();
      _shadowController.reverse();
      setState(() => _isTransitioning = false);
    }
  }

  @override
  void didUpdateWidget(covariant QuranReaderPageView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.readingMode != widget.readingMode) {
      SystemChrome.setEnabledSystemUIMode(
        widget.readingMode
            ? SystemUiMode.immersiveSticky
            : SystemUiMode.edgeToEdge,
      );
    }
  }

  @override
  void dispose() {
    widget.pageController.removeListener(_onPageControllerUpdate);
    _flipController.dispose();
    _shadowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PageView.builder(
      controller: widget.pageController,
      physics: widget.readingMode
          ? const ClampingScrollPhysics()
          : const PageScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
      allowImplicitScrolling: true,
      dragStartBehavior: DragStartBehavior.down,
      itemCount: QuranSvgPageService.lastPage,
      reverse: Directionality.of(context) == TextDirection.rtl,
      onPageChanged: (index) {
        final pageNumber = index + 1;
        _currentPage = pageNumber;
        widget.onPageChanged(pageNumber);
        _prefetchWindow(pageNumber, radius: 3);
        HapticFeedback.selectionClick();
      },
      pageSnapping: !widget.readingMode,
      itemBuilder: (context, index) {
        final pageNumber = index + 1;
        return AnimatedBuilder(
          animation: Listenable.merge([_flipAnimation, _shadowAnimation]),
          builder: (context, child) {
            final isCurrentPage = pageNumber == _currentPage;
            final isNextPage = pageNumber == _currentPage + 1;
            final isPrevPage = pageNumber == _currentPage - 1;
            final isAdjacent = isNextPage || isPrevPage;
            double scale = 1.0;
            double opacity = 1.0;
            double shadowOpacity = 0.0;
            Matrix4 transform = Matrix4.identity();

            if (_isTransitioning && (isCurrentPage || isAdjacent)) {
              final progress = _flipAnimation.value;
              final shadowProgress = _shadowAnimation.value;

              if (isCurrentPage) {
                scale = 1.0 - (progress * 0.015);
                opacity = 1.0;
                shadowOpacity = progress * 0.12;
                final direction = isNextPage ? 1.0 : (isPrevPage ? -1.0 : 0.0);
                transform = Matrix4.identity()
                  ..setEntry(3, 2, 0.001)
                  ..rotateY(progress * direction * 0.05);
              } else if (isAdjacent) {
                scale = 0.985 + (progress * 0.015);
                opacity = 0.85 + (progress * 0.15);
                shadowOpacity = (1.0 - shadowProgress) * 0.08;
              }
            }

            return RepaintBoundary(
              child: Stack(
                children: [
                  Transform(
                    alignment: Alignment.center,
                    transform: transform,
                    child: Transform.scale(
                      scale: scale,
                      child: Opacity(
                        opacity: opacity,
                        child: SizedBox.expand(
                          child: QuranInteractiveMushafPage(
                            key: ValueKey<int>(pageNumber),
                            pageNumber: pageNumber,
                            pageService: widget.pageService,
                            onAyahLongPress: widget.onAyahLongPress,
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (shadowOpacity > 0)
                    Positioned.fill(
                      child: IgnorePointer(
                        child: AnimatedOpacity(
                          opacity: shadowOpacity.clamp(0.0, 1.0),
                          duration: Duration.zero,
                          child: Container(
                            decoration: BoxDecoration(
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: shadowOpacity.clamp(0.0, 1.0)),
                                  blurRadius: 20,
                                  spreadRadius: 2,
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
          },
        );
      },
    );
  }
}
