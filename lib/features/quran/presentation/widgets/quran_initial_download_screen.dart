import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../data/datasources/quran_page_image_cache_service.dart';

class QuranInitialDownloadScreen extends StatelessWidget {
  const QuranInitialDownloadScreen({
    super.key,
    required this.progress,
    this.errorMessage,
    this.onRetry,
  });

  final QuranPagesDownloadProgress progress;
  final String? errorMessage;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = AppThemeColors.of(context);
    final accent = colors.accentColor ?? theme.colorScheme.primary;
    final hasError = errorMessage != null;

    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [theme.scaffoldBackgroundColor, colors.cardSurface],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: colors.cardSurface.withValues(alpha: 0.96),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: colors.softBorder),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 24,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          hasError
                              ? Icons.cloud_off_rounded
                              : Icons.menu_book_rounded,
                          size: 42,
                          color: accent,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'quran.preparing_pages_title'.tr(),
                          textAlign: TextAlign.center,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          hasError
                              ? 'quran.download_pages_error'.tr()
                              : 'quran.preparing_pages_once'.tr(),
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colors.secondaryText,
                            height: 1.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (hasError && errorMessage != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            errorMessage!,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colors.mutedText,
                              height: 1.4,
                            ),
                          ),
                        ],
                        const SizedBox(height: 20),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(999),
                          child: LinearProgressIndicator(
                            minHeight: 10,
                            value: progress.ratio,
                            color: accent,
                            backgroundColor: colors.softBorder,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          hasError
                              ? 'quran.download_pages_error'.tr()
                              : 'quran.preparing_pages_progress'.tr(
                                  namedArgs: {
                                    'current': progress.downloadedCount
                                        .toString(),
                                    'total': progress.totalCount.toString(),
                                  },
                                ),
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colors.secondaryText,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'quran.preparing_pages_percent'.tr(
                            namedArgs: {
                              'percent': progress.percentage.toString(),
                            },
                          ),
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: accent,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        if (hasError && onRetry != null) ...[
                          const SizedBox(height: 20),
                          FilledButton.icon(
                            onPressed: onRetry,
                            icon: const Icon(Icons.refresh_rounded),
                            label: Text('common.retry'.tr()),
                          ),
                        ],
                      ],
                    ),
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
