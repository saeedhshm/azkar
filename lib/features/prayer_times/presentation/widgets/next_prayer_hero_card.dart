import 'dart:ui' as ui;
import 'package:flutter/material.dart';

import '../../../../core/widgets/mosque_illustration.dart';
import 'progress_prayer_bar.dart';

class NextPrayerHeroCard extends StatelessWidget {
  const NextPrayerHeroCard({
    super.key,
    required this.label,
    required this.prayerName,
    required this.countdown,
    required this.currentContext,
    required this.nextPrayerTimeLine,
    required this.progressStartLabel,
    required this.progressEndLabel,
    required this.progressStartTime,
    required this.progressEndTime,
    required this.progress,
    required this.location,
    required this.hijriDate,
    required this.gregorianDate,
    this.onLocationTap,
  });

  final String label;
  final String prayerName;
  final String countdown;
  final String currentContext;
  final String nextPrayerTimeLine;
  final String progressStartLabel;
  final String progressEndLabel;
  final String progressStartTime;
  final String progressEndTime;
  final double progress;
  final String location;
  final String hijriDate;
  final String gregorianDate;
  final VoidCallback? onLocationTap;

  @override
  Widget build(BuildContext context) {
    final baseTheme = Theme.of(context);
    final heroTheme = baseTheme.copyWith(
      colorScheme: baseTheme.colorScheme.copyWith(
        primary: const Color(0xFFE6C894),
        onSurface: const Color(0xFFF7FAF7),
      ),
    );
    return Theme(
      data: heroTheme,
      child: Semantics(
        label: '$label $prayerName $countdown. $currentContext.',
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(32),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF344C3F), Color(0xFF172F27)],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0A332D).withValues(alpha: 0.18),
                blurRadius: 28,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(32),
            child: Stack(
              children: [
                if (MediaQuery.sizeOf(context).width >= 350 &&
                    MediaQuery.textScalerOf(context).scale(1) < 1.4)
                  const PositionedDirectional(
                    top: 65,
                    end: 12,
                    width: 115,
                    height: 170,
                    child: MosqueIllustration(),
                  ),
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              hijriDate.isEmpty ? gregorianDate : hijriDate,
                              style: heroTheme.textTheme.labelMedium?.copyWith(
                                color: const Color(0xFFD4E4DC),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Flexible(
                            child: InkWell(
                              onTap: onLocationTap,
                              borderRadius: BorderRadius.circular(20),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 6,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.location_on_outlined,
                                      color: Color(0xFFE6C894),
                                      size: 16,
                                    ),
                                    const SizedBox(width: 4),
                                    Flexible(
                                      child: Text(
                                        location,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: heroTheme.textTheme.labelSmall
                                            ?.copyWith(color: Colors.white),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      // Leave space for the illustration on typical phones;
                      // at large text scales readability takes priority.
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final showArt =
                              constraints.maxWidth >= 270 &&
                              MediaQuery.textScalerOf(context).scale(1) < 1.4;
                          return Padding(
                            padding: EdgeInsetsDirectional.only(
                              end: showArt ? 100 : 0,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  label,
                                  style: heroTheme.textTheme.bodySmall
                                      ?.copyWith(
                                        color: const Color(0xFFC1D8CC),
                                      ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  prayerName,
                                  style: heroTheme.textTheme.headlineMedium
                                      ?.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w800,
                                        height: 1.3,
                                      ),
                                ),
                                const SizedBox(height: 14),
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: AlignmentDirectional.centerStart,
                                  child: Text(
                                    countdown,
                                    textDirection: ui.TextDirection.ltr,
                                    style: heroTheme.textTheme.displaySmall
                                        ?.copyWith(
                                          color: const Color(0xFFE6C894),
                                          fontSize: 38,
                                          fontWeight: FontWeight.w500,
                                          letterSpacing: 1,
                                          fontFeatures: const [
                                            ui.FontFeature.tabularFigures(),
                                          ],
                                        ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  nextPrayerTimeLine,
                                  style: heroTheme.textTheme.bodySmall
                                      ?.copyWith(
                                        color: const Color(0xFFD4E4DC),
                                      ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 22),
                      Container(
                        padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.055),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.08),
                          ),
                        ),
                        child: ProgressPrayerBar(
                          startLabel: progressStartLabel,
                          endLabel: progressEndLabel,
                          startTime: progressStartTime,
                          endTime: progressEndTime,
                          progress: progress,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
