import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'prayer_home_colors.dart';

class PrayerGridCard extends StatefulWidget {
  const PrayerGridCard({
    super.key,
    required this.name,
    required this.time,
    required this.icon,
    required this.isCurrent,
    required this.isNext,
    this.onTap,
  });

  final String name;
  final String time;
  final IconData icon;
  final bool isCurrent;
  final bool isNext;
  final VoidCallback? onTap;

  @override
  State<PrayerGridCard> createState() => _PrayerGridCardState();
}

class _PrayerGridCardState extends State<PrayerGridCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final colors = PrayerHomeColors.of(context);
    final textTheme = Theme.of(context).textTheme;

    return Semantics(
      button: widget.onTap != null,
      label: '${widget.name} ${widget.time}',
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapCancel: () => setState(() => _pressed = false),
        onTapUp: (_) => setState(() => _pressed = false),
        onTap: widget.onTap,
        child: AnimatedScale(
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut,
          scale: _pressed ? 0.97 : 1,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colors.cardSurface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: widget.isCurrent
                    ? colors.primaryButton
                    : colors.cardBorder,
                width: widget.isCurrent ? 1.8 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: colors.primaryButton.withValues(
                    alpha: widget.isCurrent ? 0.14 : 0.05,
                  ),
                  blurRadius: widget.isCurrent ? 18 : 10,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Stack(
              children: [
                if (widget.isNext)
                  Align(
                    alignment: AlignmentDirectional.topEnd,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: colors.primaryButton.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        'common.next'.tr(),
                        style: textTheme.labelSmall?.copyWith(
                          color: colors.primaryButton,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(widget.icon, size: 28, color: colors.prayerIcon),
                      const SizedBox(height: 8),
                      Text(
                        widget.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.time,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.titleSmall?.copyWith(
                          color: colors.mutedText,
                          fontWeight: FontWeight.w700,
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
