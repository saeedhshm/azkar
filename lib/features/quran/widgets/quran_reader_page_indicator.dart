import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_theme.dart';
import '../presentation/cubit/quran_highlight_cubit.dart';
import '../presentation/cubit/quran_highlight_state.dart';

class QuranReaderPageIndicator extends StatelessWidget {
  const QuranReaderPageIndicator({super.key, required this.pageNumber});

  final int pageNumber;

  @override
  Widget build(BuildContext context) {
    final colors = AppThemeColors.of(context);
    final theme = Theme.of(context);

    return BlocBuilder<QuranHighlightCubit, QuranHighlightState>(
      buildWhen: (previous, current) {
        final prevCount = previous.bookmarksForPage(pageNumber).length;
        final currCount = current.bookmarksForPage(pageNumber).length;
        return prevCount != currCount;
      },
      builder: (context, state) {
        final bookmarkCount = state.bookmarksForPage(pageNumber).length;

        return DecoratedBox(
          decoration: BoxDecoration(
            color: colors.cardSurface.withValues(alpha: 0.78),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: colors.softBorder),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${'quran.page'.tr()} $pageNumber',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: colors.secondaryText,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                if (bookmarkCount > 0) ...[
                  const SizedBox(width: 6),
                  Icon(Icons.bookmark_rounded, size: 14, color: const Color(0xFF28A745)),
                  const SizedBox(width: 2),
                  Text(
                    '$bookmarkCount',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: const Color(0xFF28A745),
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
