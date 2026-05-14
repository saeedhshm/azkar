import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../core/theme/app_theme.dart';
import '../../data/datasources/quran_page_image_cache_service.dart';

class QuranMushafImagePage extends StatefulWidget {
  const QuranMushafImagePage({
    super.key,
    required this.pageNumber,
    required this.imageCacheService,
  });

  final int pageNumber;
  final QuranPageImageCacheService imageCacheService;

  @override
  State<QuranMushafImagePage> createState() => _QuranMushafImagePageState();
}

class _QuranMushafImagePageState extends State<QuranMushafImagePage>
    with AutomaticKeepAliveClientMixin {
  late Future<File> _future;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _future = widget.imageCacheService.getPageFile(widget.pageNumber);
  }

  @override
  void didUpdateWidget(covariant QuranMushafImagePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pageNumber != widget.pageNumber) {
      _future = widget.imageCacheService.getPageFile(widget.pageNumber);
    }
  }

  void _retry() {
    setState(() {
      _future = widget.imageCacheService.getPageFile(widget.pageNumber);
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);
    final colors = AppThemeColors.of(context);
    final gold = colors.accentColor ?? colors.countdownText;

    return FutureBuilder<File>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return _MushafImageShell(
            child: SafeArea(
              top: true,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return InteractiveViewer(
                    minScale: 1,
                    maxScale: 4,
                    clipBehavior: Clip.none,
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: SizedBox(
                        width: constraints.maxWidth,
                        height: constraints.maxHeight,
                        child: SvgPicture.file(
                          snapshot.data!,
                          width: constraints.maxWidth,
                          height: constraints.maxHeight,
                          fit: BoxFit.fitWidth,
                          alignment: Alignment.center,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          );
        }

        if (snapshot.hasError) {
          return _MushafImageShell(
            child: _MushafStatusContent(
              icon: Icon(Icons.cloud_off_rounded, color: gold, size: 36),
              message: 'quran.download_page_error'.tr(),
              messageStyle: theme.textTheme.bodyMedium?.copyWith(
                color: colors.secondaryText,
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

        return _MushafImageShell(
          child: _MushafStatusContent(
            icon: SizedBox.square(
              dimension: 32,
              child: CircularProgressIndicator(color: gold, strokeWidth: 3),
            ),
            message: 'quran.preparing_pages_title'.tr(),
            messageStyle: theme.textTheme.bodyMedium?.copyWith(
              color: colors.mutedText,
              fontWeight: FontWeight.w700,
            ),
          ),
        );
      },
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

class _MushafImageShell extends StatelessWidget {
  const _MushafImageShell({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(child: child);
  }
}
