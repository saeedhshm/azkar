import 'dart:math';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_qiblah/flutter_qiblah.dart';

import '../../../../core/theme/app_theme.dart';

class QiblaCard extends StatelessWidget {
  const QiblaCard({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool?>(
      future: FlutterQiblah.androidDeviceSensorSupport(),
      builder: (context, snapshot) {
        final supported = snapshot.data ?? false;
        if (!supported) {
          return const SizedBox.shrink();
        }

        final colors = AppThemeColors.of(context);
        final theme = Theme.of(context);
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: colors.cardSurface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: colors.softBorder),
          ),
          child: Column(
            children: [
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: Text(
                  'prayer_times.qibla'.tr(),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                height: 200,
                child: StreamBuilder<QiblahDirection>(
                  stream: FlutterQiblah.qiblahStream,
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final direction = snapshot.data!;
                    final angle = direction.qiblah * (pi / 180) * -1;
                    return Center(
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 200,
                            height: 200,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: theme.colorScheme.primary.withValues(
                                    alpha: 0.18,
                                  ),
                                  blurRadius: 36,
                                ),
                              ],
                              border: Border.all(
                                color: theme.colorScheme.primary.withValues(
                                  alpha: 0.45,
                                ),
                                width: 1.6,
                              ),
                            ),
                          ),
                          Container(
                            width: 150,
                            height: 150,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: colors.softBorder),
                            ),
                          ),
                          Transform.rotate(
                            angle: angle,
                            child: Icon(
                              Icons.navigation_rounded,
                              color: theme.colorScheme.primary,
                              size: 58,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: colors.cardSurface,
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(color: colors.softBorder),
                            ),
                            child: Text(
                              '${direction.qiblah.toStringAsFixed(0)}°',
                              style: theme.textTheme.labelMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
