import 'dart:async';
import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:photo_view/photo_view.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../services/quran_svg_page_service.dart';
import 'quran_mushaf_frame.dart';

class QuranMushafImagePage extends StatefulWidget {
  const QuranMushafImagePage({
    super.key,
    required this.pageNumber,
    required this.pageService,
    this.overlay,
    this.onTapUp,
    this.onLongPressUp,
  });

  final int pageNumber;
  final QuranSvgPageService pageService;
  final Widget? overlay;
  final void Function(
    TapUpDetails details,
    PhotoViewControllerValue controllerValue,
    Size viewportSize,
    Size displaySize,
    double fitScale,
  )?
  onTapUp;
  final void Function(
    LongPressStartDetails details,
    PhotoViewControllerValue controllerValue,
    Size viewportSize,
    Size displaySize,
    double fitScale,
  )?
  onLongPressUp;

  @override
  State<QuranMushafImagePage> createState() => _QuranMushafImagePageState();
}

class _QuranMushafImagePageState extends State<QuranMushafImagePage>
    with AutomaticKeepAliveClientMixin, TickerProviderStateMixin {
  static const Size _pageCanvasSize = Size(345, 550);

  late Future<Object> _future;
  final PhotoViewController _photoViewController = PhotoViewController();
  double _currentScale = 1.0;
  double _targetScale = 1.0;
  late AnimationController _zoomController;
  late Animation<double> _zoomAnimation;
  DateTime _lastTapTime = DateTime.now();
  bool _isDoubleTap = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _future = _loadPage(widget.pageNumber);
    _zoomController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _zoomAnimation = CurvedAnimation(
      parent: _zoomController,
      curve: Curves.easeOutCubic,
    );
    _zoomController.addListener(_onZoomAnimation);
  }

  @override
  void didUpdateWidget(covariant QuranMushafImagePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pageNumber != widget.pageNumber) {
      _resetZoom();
      _future = _loadPage(widget.pageNumber);
    }
  }

  void _resetZoom() {
    _currentScale = 1.0;
    _targetScale = 1.0;
    _zoomController.reset();
    _photoViewController.position = Offset.zero;
  }

  Future<Object> _loadPage(int pageNumber) async {
    final cache = widget.pageService.cache;
    final cachedBytes = cache.getBytes(pageNumber);
    if (cachedBytes != null) return cachedBytes;
    final file = await widget.pageService.getPageFile(pageNumber);
    unawaited(cache.set(pageNumber, file));
    return file;
  }

  void _retry() {
    setState(() {
      _future = _loadPage(widget.pageNumber);
    });
  }

  void _onZoomAnimation() {
    _currentScale = 1.0 + (_targetScale - 1.0) * _zoomAnimation.value;
  }

  void _handleDoubleTap(TapUpDetails details) {
    final now = DateTime.now();
    final diff = now.difference(_lastTapTime);

    if (diff.inMilliseconds < 300) {
      _isDoubleTap = true;
      HapticFeedback.lightImpact();

      if (_currentScale > 1.5) {
        _targetScale = 1.0;
        _photoViewController.position = Offset.zero;
      } else {
        _targetScale = 2.8;
      }
      _zoomController.forward(from: 0);
    }

    _lastTapTime = now;

    Future.delayed(const Duration(milliseconds: 350), () {
      _isDoubleTap = false;
    });
  }

  @override
  void dispose() {
    _zoomController.removeListener(_onZoomAnimation);
    _zoomController.dispose();
    _photoViewController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);
    final gold = theme.colorScheme.primary;

    return FutureBuilder<Object>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return QuranMushafFrame(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final fitScale = _pageFitScale(constraints.biggest);
                final displaySize = Size(
                  _pageCanvasSize.width * fitScale,
                  _pageCanvasSize.height * fitScale,
                );

                final zoomScale = _currentScale;

                return RepaintBoundary(
                  child: PhotoView.customChild(
                    controller: _photoViewController,
                    backgroundDecoration: const BoxDecoration(
                      color: Colors.transparent,
                    ),
                    initialScale: PhotoViewComputedScale.contained * zoomScale,
                    minScale: PhotoViewComputedScale.contained,
                    maxScale: PhotoViewComputedScale.contained * 4.0,
                    basePosition: Alignment.topCenter,
                    tightMode: true,
                    childSize: displaySize,
                    onTapUp: widget.onTapUp == null
                        ? null
                        : (context, details, controllerValue) {
                            if (_isDoubleTap) return;
                            _handleDoubleTap(details);
                            if (!_isDoubleTap) {
                              widget.onTapUp!(
                                details,
                                controllerValue,
                                constraints.biggest,
                                displaySize,
                                fitScale,
                              );
                            }
                          },
                    child: RepaintBoundary(
                      child: SizedBox(
                        width: displaySize.width,
                        height: displaySize.height,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            _SvgPageContent(
                              data: snapshot.data!,
                              width: displaySize.width,
                              height: displaySize.height,
                              pageNumber: widget.pageNumber,
                            ),
                            if (widget.overlay != null)
                              Positioned.fill(
                                child: IgnorePointer(
                                  child: widget.overlay!,
                                ),
                              ),
                            if (widget.onLongPressUp != null)
                              Positioned.fill(
                                child: GestureDetector(
                                  onLongPressStart: (details) {
                                    final controllerValue =
                                        _photoViewController.value;
                                    widget.onLongPressUp!(
                                      details,
                                      controllerValue,
                                      constraints.biggest,
                                      displaySize,
                                      fitScale,
                                    );
                                  },
                                  behavior: HitTestBehavior.translucent,
                                  child: Container(
                                    color: Colors.transparent,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        }

        if (snapshot.hasError) {
          return QuranMushafFrame(
            child: _MushafStatusContent(
              icon: Icon(Icons.cloud_off_rounded, color: gold, size: 36),
              message: 'quran.download_page_error'.tr(),
            messageStyle: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              fontWeight: FontWeight.w700,
            ),
              action: FilledButton.icon(
                onPressed: _retry,
                style: FilledButton.styleFrom(
                  minimumSize: const Size(96, 40),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                icon: const Icon(Icons.refresh_rounded),
                label: Text('common.retry'.tr()),
              ),
            ),
          );
        }

        return QuranMushafFrame(
          child: _MushafStatusContent(
            icon: SizedBox.square(
              dimension: 32,
              child: CircularProgressIndicator(
                color: gold,
                strokeWidth: 3,
              ),
            ),
            message: 'quran.preparing_pages_title'.tr(),
            messageStyle: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              fontWeight: FontWeight.w700,
            ),
          ),
        );
      },
    );
  }

  double _pageFitScale(Size viewportSize) {
    if (viewportSize.width <= 0 || viewportSize.height <= 0) {
      return 1;
    }
    final widthScale = viewportSize.width / _pageCanvasSize.width;
    final heightScale = viewportSize.height / _pageCanvasSize.height;
    return widthScale < heightScale ? widthScale : heightScale;
  }
}

class _SvgPageContent extends StatelessWidget {
  const _SvgPageContent({
    required this.data,
    required this.width,
    required this.height,
    required this.pageNumber,
  });

  final Object data;
  final double width;
  final double height;
  final int pageNumber;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    if (data is Uint8List) {
      return ColorFiltered(
        colorFilter: isDark
            ? const ColorFilter.matrix([
                0.2126, 0.7152, 0.0722, 0, 200,
                0.2126, 0.7152, 0.0722, 0, 200,
                0.2126, 0.7152, 0.0722, 0, 200,
                0, 0, 0, 1, 0,
              ])
            : const ColorFilter.mode(Colors.transparent, BlendMode.multiply),
        child: SvgPicture.memory(
          data as Uint8List,
          width: width,
          height: height,
          fit: BoxFit.fill,
          alignment: Alignment.topCenter,
        ),
      );
    }
    return ColorFiltered(
      colorFilter: isDark
          ? const ColorFilter.matrix([
              0.2126, 0.7152, 0.0722, 0, 200,
              0.2126, 0.7152, 0.0722, 0, 200,
              0.2126, 0.7152, 0.0722, 0, 200,
              0, 0, 0, 1, 0,
            ])
          : const ColorFilter.mode(Colors.transparent, BlendMode.multiply),
      child: SvgPicture.file(
        data as File,
        width: width,
        height: height,
        fit: BoxFit.fill,
        alignment: Alignment.topCenter,
      ),
    );
  }
}

class _MushafStatusContent extends StatelessWidget {
  const _MushafStatusContent({
    required this.icon,
    required this.message,
    required this.messageStyle,
    this.action,
  });

  final Widget icon;
  final String message;
  final TextStyle? messageStyle;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final minHeight =
            constraints.maxHeight.isFinite && constraints.maxHeight > 32
                ? constraints.maxHeight - 32
                : 0.0;

        return SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: minHeight),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  icon,
                  const SizedBox(height: 10),
                  Text(
                    message,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: messageStyle,
                  ),
                  if (action != null) ...[const SizedBox(height: 12), action!],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
