import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'prayer_home_colors.dart';

class NextPrayerCard extends StatelessWidget {
  const NextPrayerCard({
    super.key,
    required this.hijriDate,
    required this.gregorianDate,
    required this.location,
    required this.prayerName,
    required this.countdown,
    required this.prayerTime,
    required this.onChangeLocation,
  });

  final String? hijriDate;
  final String gregorianDate;
  final String location;
  final String prayerName;
  final String countdown;
  final String? prayerTime;
  final VoidCallback onChangeLocation;

  @override
  Widget build(BuildContext context) {
    final colors = PrayerHomeColors.of(context);
    final textTheme = Theme.of(context).textTheme;

    return Semantics(
      label: '${'prayer_times.next_prayer'.tr()} $prayerName $countdown',
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: colors.nextPrayerCard,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: colors.countdown.withValues(alpha: 0.12),
              blurRadius: 26,
              offset: const Offset(0, 16),
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned(
              top: 72,
              child: Container(
                width: 210,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      colors.countdown.withValues(alpha: 0.22),
                      colors.countdown.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),
            Column(
              children: [
                _MetaRow(
                  hijriDate: hijriDate,
                  location: location,
                  gregorianDate: gregorianDate,
                  color: colors.mutedText,
                ),
                const SizedBox(height: 22),
                Text(
                  'prayer_times.next_prayer'.tr(),
                  style: textTheme.labelLarge?.copyWith(
                    color: colors.mutedText,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 6),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder: (child, animation) {
                    return FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, 0.12),
                          end: Offset.zero,
                        ).animate(animation),
                        child: child,
                      ),
                    );
                  },
                  child: Text(
                    prayerName,
                    key: ValueKey(prayerName),
                    style: textTheme.headlineMedium?.copyWith(
                      color: colors.primaryButton,
                      fontWeight: FontWeight.w800,
                      fontSize: 32,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  child: Text(
                    countdown,
                    key: ValueKey(countdown),
                    style: textTheme.displaySmall?.copyWith(
                      color: colors.countdown,
                      fontWeight: FontWeight.w800,
                      fontSize: 38,
                      height: 1.05,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
                if (prayerTime != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    prayerTime!,
                    style: textTheme.titleMedium?.copyWith(
                      color: colors.mutedText.withValues(alpha: 0.9),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                const SizedBox(height: 18),
                SizedBox(
                  height: 44,
                  child: FilledButton(
                    onPressed: onChangeLocation,
                    style: FilledButton.styleFrom(
                      backgroundColor: colors.primaryButton,
                      foregroundColor: Colors.white,
                      shape: const StadiumBorder(),
                      padding: const EdgeInsets.symmetric(horizontal: 22),
                    ),
                    child: Text('prayer_times.change_location'.tr()),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({
    required this.hijriDate,
    required this.location,
    required this.gregorianDate,
    required this.color,
  });

  final String? hijriDate;
  final String location;
  final String gregorianDate;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodySmall?.copyWith(
      color: color.withValues(alpha: 0.9),
      fontWeight: FontWeight.w600,
      fontSize: 12,
    );

    return Row(
      children: [
        Expanded(
          child: Text(
            hijriDate ?? '',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: style,
          ),
        ),
        const SizedBox(width: 8),
        Icon(Icons.location_on_rounded, color: color, size: 16),
        Flexible(
          child: Text(
            location,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: style,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            gregorianDate,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.end,
            style: style,
          ),
        ),
      ],
    );
  }
}
