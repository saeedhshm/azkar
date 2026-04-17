import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'prayer_home_colors.dart';

class QuickSettingsCard extends StatelessWidget {
  const QuickSettingsCard({
    super.key,
    required this.calculationMethod,
    required this.madhab,
    required this.timeFormat,
    required this.onTap,
  });

  final String calculationMethod;
  final String madhab;
  final String timeFormat;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = PrayerHomeColors.of(context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.cardSurface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'prayer_times.settings'.tr(),
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 14),
          _QuickSettingsRow(
            icon: Icons.calculate_outlined,
            title: 'prayer_times.method'.tr(),
            value: calculationMethod,
            onTap: onTap,
          ),
          const SizedBox(height: 8),
          _QuickSettingsRow(
            icon: Icons.school_outlined,
            title: 'prayer_times.madhab_label'.tr(),
            value: madhab,
            onTap: onTap,
          ),
          const SizedBox(height: 8),
          _QuickSettingsRow(
            icon: Icons.schedule_rounded,
            title: 'settings.use_24h'.tr(),
            value: timeFormat,
            onTap: onTap,
          ),
        ],
      ),
    );
  }
}

class _QuickSettingsRow extends StatelessWidget {
  const _QuickSettingsRow({
    required this.icon,
    required this.title,
    required this.value,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = PrayerHomeColors.of(context);
    final textTheme = Theme.of(context).textTheme;

    return Semantics(
      button: true,
      label: '$title $value',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: colors.background.withValues(alpha: 0.72),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colors.cardBorder),
          ),
          child: Row(
            children: [
              Icon(icon, color: colors.primaryButton, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.end,
                  style: textTheme.bodySmall?.copyWith(
                    color: colors.mutedText,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.chevron_right_rounded, color: colors.mutedText),
            ],
          ),
        ),
      ),
    );
  }
}
