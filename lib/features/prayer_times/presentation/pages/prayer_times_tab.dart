import 'dart:math';
import 'dart:ui';

import 'package:adhan/adhan.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_qiblah/flutter_qiblah.dart';
import 'package:intl/intl.dart';

import '../../../../core/di/service_locator.dart';
import '../../data/services/location_service.dart';
import '../cubit/prayer_times_cubit.dart';
import '../cubit/prayer_times_state.dart';

class PrayerTimesTab extends StatelessWidget {
  const PrayerTimesTab({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<PrayerTimesCubit>(
      create: (_) => getIt<PrayerTimesCubit>()..load(),
      child: BlocBuilder<PrayerTimesCubit, PrayerTimesState>(
        builder: (context, state) {
          if (state.status == PrayerTimesStatus.loading ||
              state.status == PrayerTimesStatus.initial) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.status == PrayerTimesStatus.permissionDenied ||
              state.status == PrayerTimesStatus.permissionDeniedForever ||
              state.status == PrayerTimesStatus.serviceDisabled) {
            return _PermissionCard(state: state);
          }

          if (state.status == PrayerTimesStatus.failure) {
            return Center(
              child: Text(state.errorMessage ?? 'common.failed_load_adhkar'.tr()),
            );
          }

          return _PrayerTimesContent(state: state);
        },
      ),
    );
  }
}

class _PrayerTimesContent extends StatelessWidget {
  const _PrayerTimesContent({required this.state});

  final PrayerTimesState state;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accentColor =
        isDark ? const Color(0xFF6EE7E8) : const Color(0xFFD4A574);
    final warmGold = isDark ? const Color(0xFFF2C777) : const Color(0xFFC58B55);

    final times = state.prayerTimes;
    if (times == null) {
      return const SizedBox.shrink();
    }

    final items = <_PrayerItem>[
      _PrayerItem(Prayer.fajr, times.fajr),
      _PrayerItem(Prayer.dhuhr, times.dhuhr),
      _PrayerItem(Prayer.asr, times.asr),
      _PrayerItem(Prayer.maghrib, times.maghrib),
      _PrayerItem(Prayer.isha, times.isha),
    ];

    final rawLocation = state.locationLabel;
    final locationText =
        rawLocation == null || rawLocation.trim().isEmpty || rawLocation == 'GPS'
            ? 'prayer_times.current_location'.tr()
            : rawLocation;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        _HeroPrayerCard(
          isDark: isDark,
          accentColor: warmGold,
          dateLine: state.gregorianDate ?? '',
          hijriLine: state.hijriDate,
          nextPrayer: _prayerLabel(state.nextPrayer),
          countdown: _formatCountdown(state.countdown),
          time: state.nextPrayerTime == null
              ? null
              : DateFormat.Hm().format(state.nextPrayerTime!),
          locationLabel: locationText,
          onChangeLocation: () => _showLocationSheet(context, state),
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final tileWidth = (constraints.maxWidth - 12) / 2;
            final nightCard = _prayerCardStyle(
              isDark: isDark,
              accent: accentColor,
              type: _PrayerVisualType.night,
            );
            final sunsetCard = _prayerCardStyle(
              isDark: isDark,
              accent: warmGold,
              type: _PrayerVisualType.sunset,
            );
            final sunCard = _prayerCardStyle(
              isDark: isDark,
              accent: warmGold,
              type: _PrayerVisualType.sun,
            );

            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                SizedBox(
                  width: tileWidth,
                  child: _PrayerTile(
                    item: items[0],
                    isDark: isDark,
                    isCurrent: state.currentPrayer == Prayer.fajr,
                    style: nightCard,
                    label: _prayerLabel(Prayer.fajr),
                    accent: accentColor,
                  ),
                ),
                SizedBox(
                  width: tileWidth,
                  child: _PrayerTile(
                    item: items[1],
                    isDark: isDark,
                    isCurrent: state.currentPrayer == Prayer.dhuhr,
                    style: sunCard,
                    label: _prayerLabel(Prayer.dhuhr),
                    accent: warmGold,
                    isNext: state.nextPrayer == Prayer.dhuhr,
                  ),
                ),
                SizedBox(
                  width: tileWidth,
                  child: _PrayerTile(
                    item: items[2],
                    isDark: isDark,
                    isCurrent: state.currentPrayer == Prayer.asr,
                    style: sunCard,
                    label: _prayerLabel(Prayer.asr),
                    accent: warmGold,
                  ),
                ),
                SizedBox(
                  width: tileWidth,
                  child: _PrayerTile(
                    item: items[3],
                    isDark: isDark,
                    isCurrent: state.currentPrayer == Prayer.maghrib,
                    style: sunsetCard,
                    label: _prayerLabel(Prayer.maghrib),
                    accent: warmGold,
                  ),
                ),
                SizedBox(
                  width: constraints.maxWidth,
                  child: _PrayerTile(
                    item: items[4],
                    isDark: isDark,
                    isCurrent: state.currentPrayer == Prayer.isha,
                    style: nightCard,
                    label: _prayerLabel(Prayer.isha),
                    accent: accentColor,
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 16),
        _GlassCard(
          isDark: isDark,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'prayer_times.settings'.tr(),
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.tune),
                    color: accentColor,
                    onPressed: () => _openSettingsSheet(context, state),
                  ),
                ],
              ),
              Text(
                '${'prayer_times.method'.tr()}: ${_methodLabel(state.settings.method)}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 4),
              Text(
                '${'prayer_times.madhab_label'.tr()}: ${_madhabLabel(state.settings.madhab)}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _QiblaSection(isDark: isDark),
      ],
    );
  }

  String _formatCountdown(Duration? duration) {
    if (duration == null) {
      return '--:--:--';
    }
    final hours = duration.inHours.toString().padLeft(2, '0');
    final minutes = (duration.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }

  String _prayerLabel(Prayer? prayer) {
    return switch (prayer) {
      Prayer.fajr => 'prayer_times.prayers.fajr'.tr(),
      Prayer.dhuhr => 'prayer_times.prayers.dhuhr'.tr(),
      Prayer.asr => 'prayer_times.prayers.asr'.tr(),
      Prayer.maghrib => 'prayer_times.prayers.maghrib'.tr(),
      Prayer.isha => 'prayer_times.prayers.isha'.tr(),
      _ => 'prayer_times.prayers.fajr'.tr(),
    };
  }

  String _methodLabel(CalculationMethod method) {
    return switch (method) {
      CalculationMethod.muslim_world_league => 'prayer_times.methods.mwl'.tr(),
      CalculationMethod.egyptian => 'prayer_times.methods.egyptian'.tr(),
      CalculationMethod.karachi => 'prayer_times.methods.karachi'.tr(),
      CalculationMethod.umm_al_qura => 'prayer_times.methods.umm_al_qura'.tr(),
      CalculationMethod.dubai => 'prayer_times.methods.dubai'.tr(),
      CalculationMethod.qatar => 'prayer_times.methods.qatar'.tr(),
      CalculationMethod.kuwait => 'prayer_times.methods.kuwait'.tr(),
      CalculationMethod.moon_sighting_committee =>
        'prayer_times.methods.moonsighting'.tr(),
      CalculationMethod.singapore => 'prayer_times.methods.singapore'.tr(),
      CalculationMethod.turkey => 'prayer_times.methods.turkey'.tr(),
      CalculationMethod.tehran => 'prayer_times.methods.tehran'.tr(),
      CalculationMethod.north_america =>
        'prayer_times.methods.north_america'.tr(),
      CalculationMethod.other => 'prayer_times.methods.other'.tr(),
    };
  }

  String _madhabLabel(Madhab madhab) {
    return madhab == Madhab.hanafi
        ? 'prayer_times.madhab.hanafi'.tr()
        : 'prayer_times.madhab.shafi'.tr();
  }

  Future<void> _openSettingsSheet(
    BuildContext context,
    PrayerTimesState state,
  ) async {
    final cubit = context.read<PrayerTimesCubit>();
    final offsets = Map<Prayer, int>.from(state.settings.offsets);
    CalculationMethod method = state.settings.method;
    Madhab madhab = state.settings.madhab;
    final soundController = TextEditingController(
      text: state.settings.customAdhanSound ?? '',
    );

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return _BottomSheetContainer(
          child: StatefulBuilder(
            builder: (context, setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'prayer_times.settings'.tr(),
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 12),
                  _DropdownField<CalculationMethod>(
                    label: 'prayer_times.method'.tr(),
                    value: method,
                    items: _methodOptions
                        .map(
                          (value) => DropdownMenuItem<CalculationMethod>(
                            value: value,
                            child: Text(_methodLabel(value)),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => method = value);
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  _DropdownField<Madhab>(
                    label: 'prayer_times.madhab_label'.tr(),
                    value: madhab,
                    items: [
                      DropdownMenuItem(
                        value: Madhab.shafi,
                        child: Text('prayer_times.madhab.shafi'.tr()),
                      ),
                      DropdownMenuItem(
                        value: Madhab.hanafi,
                        child: Text('prayer_times.madhab.hanafi'.tr()),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => madhab = value);
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'prayer_times.offsets'.tr(),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _OffsetRow(
                    label: 'prayer_times.prayers.fajr'.tr(),
                    value: offsets[Prayer.fajr] ?? 0,
                    onChanged: (value) =>
                        setState(() => offsets[Prayer.fajr] = value),
                    isDark: isDark,
                  ),
                  _OffsetRow(
                    label: 'prayer_times.prayers.dhuhr'.tr(),
                    value: offsets[Prayer.dhuhr] ?? 0,
                    onChanged: (value) =>
                        setState(() => offsets[Prayer.dhuhr] = value),
                    isDark: isDark,
                  ),
                  _OffsetRow(
                    label: 'prayer_times.prayers.asr'.tr(),
                    value: offsets[Prayer.asr] ?? 0,
                    onChanged: (value) =>
                        setState(() => offsets[Prayer.asr] = value),
                    isDark: isDark,
                  ),
                  _OffsetRow(
                    label: 'prayer_times.prayers.maghrib'.tr(),
                    value: offsets[Prayer.maghrib] ?? 0,
                    onChanged: (value) =>
                        setState(() => offsets[Prayer.maghrib] = value),
                    isDark: isDark,
                  ),
                  _OffsetRow(
                    label: 'prayer_times.prayers.isha'.tr(),
                    value: offsets[Prayer.isha] ?? 0,
                    onChanged: (value) =>
                        setState(() => offsets[Prayer.isha] = value),
                    isDark: isDark,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: soundController,
                    decoration: InputDecoration(
                      labelText: 'prayer_times.adhan_sound'.tr(),
                      helperText: 'prayer_times.adhan_sound_hint'.tr(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        await cubit.updateSettings(
                              method: method,
                              madhab: madhab,
                              offsets: offsets,
                              customSound: soundController.text.trim().isEmpty
                                  ? null
                                  : soundController.text.trim(),
                              setCustomSound: true,
                            );
                        if (context.mounted) {
                          Navigator.pop(context);
                        }
                      },
                      child: Text('common.save'.tr()),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Future<void> _showLocationSheet(
    BuildContext context,
    PrayerTimesState state,
  ) async {
    final cubit = context.read<PrayerTimesCubit>();
    final labelController =
        TextEditingController(text: state.locationLabel ?? '');
    final latController = TextEditingController(
      text: state.latitude?.toStringAsFixed(6) ?? '',
    );
    final lngController = TextEditingController(
      text: state.longitude?.toStringAsFixed(6) ?? '',
    );

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return _BottomSheetContainer(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'prayer_times.location'.tr(),
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              _LocationActionButton(
                label: 'prayer_times.use_device_location'.tr(),
                icon: Icons.my_location,
                onTap: () async {
                  await cubit.useDeviceLocation();
                  if (context.mounted) {
                    Navigator.pop(context);
                  }
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: labelController,
                decoration: InputDecoration(
                  labelText: 'prayer_times.city_label'.tr(),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: latController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                        signed: true,
                      ),
                      decoration: InputDecoration(
                        labelText: 'prayer_times.latitude'.tr(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: lngController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                        signed: true,
                      ),
                      decoration: InputDecoration(
                        labelText: 'prayer_times.longitude'.tr(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    final lat = double.tryParse(latController.text.trim());
                    final lng = double.tryParse(lngController.text.trim());
                    if (lat == null || lng == null) {
                      return;
                    }
                    final label = labelController.text.trim().isEmpty
                        ? '${lat.toStringAsFixed(2)}, ${lng.toStringAsFixed(2)}'
                        : labelController.text.trim();

                    await context.read<PrayerTimesCubit>().setManualLocation(
                          latitude: lat,
                          longitude: lng,
                          label: label,
                        );
                    if (context.mounted) {
                      Navigator.pop(context);
                    }
                  },
                  child: Text('common.save'.tr()),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }
}

class _PrayerCard extends StatelessWidget {
  const _PrayerCard({
    required this.item,
    required this.isCurrent,
    required this.isDark,
  });

  final _PrayerItem item;
  final bool isCurrent;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final accentColor =
        isDark ? const Color(0xFF6EE7E8) : const Color(0xFFC58B55);
    final timeText = DateFormat.Hm().format(item.time);

    return _GlassCard(
      isDark: isDark,
      child: Row(
        children: [
          _PrayerBadge(
            label: _label(context),
            color: isCurrent ? accentColor : accentColor.withValues(alpha: 0.6),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _label(context),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
                  ),
            ),
          ),
          Text(
            timeText,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: isCurrent ? accentColor : null,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }

  String _label(BuildContext context) {
    return switch (item.prayer) {
      Prayer.fajr => 'prayer_times.prayers.fajr'.tr(),
      Prayer.dhuhr => 'prayer_times.prayers.dhuhr'.tr(),
      Prayer.asr => 'prayer_times.prayers.asr'.tr(),
      Prayer.maghrib => 'prayer_times.prayers.maghrib'.tr(),
      Prayer.isha => 'prayer_times.prayers.isha'.tr(),
      _ => 'prayer_times.prayers.fajr'.tr(),
    };
  }
}

class _HeroPrayerCard extends StatelessWidget {
  const _HeroPrayerCard({
    required this.isDark,
    required this.accentColor,
    required this.dateLine,
    required this.hijriLine,
    required this.nextPrayer,
    required this.countdown,
    required this.time,
    required this.locationLabel,
    required this.onChangeLocation,
  });

  final bool isDark;
  final Color accentColor;
  final String dateLine;
  final String? hijriLine;
  final String nextPrayer;
  final String countdown;
  final String? time;
  final String locationLabel;
  final VoidCallback onChangeLocation;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final gradient = isDark
        ? const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1B2A44), Color(0xFF223754), Color(0xFF0F2236)],
          )
        : const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFF7EBD6), Color(0xFFF1D7B0), Color(0xFFE7C38E)],
          );

    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: Container(
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: accentColor.withValues(alpha: isDark ? 0.35 : 0.5),
            width: 1.4,
          ),
          boxShadow: [
            BoxShadow(
              color: accentColor.withValues(alpha: isDark ? 0.35 : 0.2),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: _StarFieldPainter(isDark: isDark),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        dateLine,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color:
                              isDark ? Colors.white60 : const Color(0xFF6A4B2E),
                        ),
                      ),
                      if (hijriLine != null) ...[
                        const SizedBox(width: 8),
                        Text(
                          hijriLine!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: isDark
                                ? Colors.white60
                                : const Color(0xFF6A4B2E),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'prayer_times.next_prayer'.tr(),
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: isDark ? Colors.white70 : const Color(0xFF6A4B2E),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    nextPrayer,
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: accentColor,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    countdown,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: isDark ? Colors.white : const Color(0xFF4B321D),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (time != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      time!,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: isDark
                            ? Colors.white70
                            : const Color(0xFF6A4B2E),
                      ),
                    ),
                  ],
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(Icons.location_on_outlined, color: accentColor),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          locationLabel,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: isDark
                                ? Colors.white70
                                : const Color(0xFF6A4B2E),
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: onChangeLocation,
                        child: Text('prayer_times.change_location'.tr()),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum _PrayerVisualType { sun, sunset, night }

class _PrayerCardStyle {
  const _PrayerCardStyle({
    required this.gradient,
    required this.glow,
    required this.icon,
    required this.iconColor,
  });

  final Gradient gradient;
  final Color glow;
  final IconData icon;
  final Color iconColor;
}

_PrayerCardStyle _prayerCardStyle({
  required bool isDark,
  required Color accent,
  required _PrayerVisualType type,
}) {
  switch (type) {
    case _PrayerVisualType.sun:
      return _PrayerCardStyle(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF7A4E1A), const Color(0xFFB77B2C)]
              : [const Color(0xFFF3D6A3), const Color(0xFFD9A561)],
        ),
        glow: accent,
        icon: Icons.wb_sunny_rounded,
        iconColor: Colors.white70,
      );
    case _PrayerVisualType.sunset:
      return _PrayerCardStyle(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF5B2E1A), const Color(0xFF9B5C2B)]
              : [const Color(0xFFE5B37E), const Color(0xFFC98A4C)],
        ),
        glow: accent,
        icon: Icons.wb_sunny_outlined,
        iconColor: Colors.white70,
      );
    case _PrayerVisualType.night:
      return _PrayerCardStyle(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF1A2C45), const Color(0xFF2B3E5F)]
              : [const Color(0xFFF0E6DA), const Color(0xFFD8C9B7)],
        ),
        glow: accent,
        icon: Icons.nightlight_round,
        iconColor: Colors.white70,
      );
  }
}

class _PrayerTile extends StatelessWidget {
  const _PrayerTile({
    required this.item,
    required this.isDark,
    required this.isCurrent,
    required this.style,
    required this.label,
    required this.accent,
    this.isNext = false,
  });

  final _PrayerItem item;
  final bool isDark;
  final bool isCurrent;
  final _PrayerCardStyle style;
  final String label;
  final Color accent;
  final bool isNext;

  @override
  Widget build(BuildContext context) {
    final timeText = DateFormat.Hm().format(item.time);
    final titleStyle = Theme.of(context).textTheme.titleLarge?.copyWith(
          color: isDark ? Colors.white : const Color(0xFF4B321D),
          fontWeight: FontWeight.w700,
        );
    final timeStyle = Theme.of(context).textTheme.titleMedium?.copyWith(
          color: isDark ? Colors.white70 : const Color(0xFF4B321D),
          fontWeight: FontWeight.w600,
        );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: style.gradient,
        border: Border.all(
          color: isCurrent
              ? accent
              : accent.withValues(alpha: isDark ? 0.4 : 0.35),
          width: isCurrent ? 2 : 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: style.glow.withValues(alpha: isDark ? 0.35 : 0.25),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          Align(
            alignment: Alignment.topRight,
            child: Icon(style.icon, color: style.iconColor, size: 35),
          ),
          if (isNext)
            Align(
              alignment: Alignment.topRight,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'common.next'.tr(),
                  style: TextStyle(
                    color: isDark ? Colors.black : Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 6),
              Text(label, style: titleStyle, textAlign: TextAlign.center),
              const SizedBox(height: 6),
              Text(timeText, style: timeStyle, textAlign: TextAlign.center),
            ],
          ),
        ],
      ),
    );
  }
}

class _StarFieldPainter extends CustomPainter {
  _StarFieldPainter({required this.isDark});

  final bool isDark;

  @override
  void paint(Canvas canvas, Size size) {
    final random = Random(9);
    final count = isDark ? 70 : 40;
    for (var i = 0; i < count; i++) {
      final dx = random.nextDouble() * size.width;
      final dy = random.nextDouble() * size.height;
      final radius = random.nextDouble() * 1.6 + 0.4;
      final opacity = (random.nextDouble() * 0.5) + 0.2;
      final paint = Paint()
        ..color = (isDark ? Colors.white : const Color(0xFFD4A574))
            .withValues(alpha: opacity);
      canvas.drawCircle(Offset(dx, dy), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _PrayerBadge extends StatelessWidget {
  const _PrayerBadge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: color.withValues(alpha: 0.15),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _QiblaCompass extends StatelessWidget {
  const _QiblaCompass({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final accentColor =
        isDark ? const Color(0xFF6EE7E8) : const Color(0xFFC58B55);
    return SizedBox(
      height: 180,
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
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: isDark
                        ? const LinearGradient(
                            colors: [Color(0xFF1E3340), Color(0xFF0C1A28)],
                          )
                        : const LinearGradient(
                            colors: [Color(0xFFF3E2C4), Color(0xFFE6C89C)],
                          ),
                    border: Border.all(
                      color: accentColor.withValues(alpha: 0.6),
                      width: 2,
                    ),
                  ),
                ),
                Transform.rotate(
                  angle: angle,
                  child: Icon(
                    Icons.navigation,
                    size: 60,
                    color: accentColor,
                  ),
                ),
                Positioned(
                  bottom: 14,
                  child: Text(
                    '${direction.qiblah.toStringAsFixed(0)}°',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _QiblaSection extends StatelessWidget {
  const _QiblaSection({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool?>(
      future: FlutterQiblah.androidDeviceSensorSupport(),
      builder: (context, snapshot) {
        final supported = snapshot.data ?? false;
        if (!supported) {
          return const SizedBox.shrink();
        }

        return _GlassCard(
          isDark: isDark,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'prayer_times.qibla'.tr(),
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              _QiblaCompass(isDark: isDark),
            ],
          ),
        );
      },
    );
  }
}

class _PermissionCard extends StatelessWidget {
  const _PermissionCard({required this.state});

  final PrayerTimesState state;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accentColor =
        isDark ? const Color(0xFF6EE7E8) : const Color(0xFFC58B55);

    final message = switch (state.status) {
      PrayerTimesStatus.permissionDeniedForever =>
        'prayer_times.permission_denied_forever'.tr(),
      PrayerTimesStatus.serviceDisabled =>
        'prayer_times.location_services_disabled'.tr(),
      _ => 'prayer_times.permission_denied'.tr(),
    };

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: _GlassCard(
          isDark: isDark,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.location_off, color: accentColor, size: 40),
              const SizedBox(height: 12),
              Text(
                message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: () => context.read<PrayerTimesCubit>().refresh(),
                    child: Text('common.retry'.tr()),
                  ),
                  OutlinedButton(
                    onPressed: () =>
                        _showManualDialog(context, context.read<PrayerTimesCubit>()),
                    child: Text('prayer_times.manual_location'.tr()),
                  ),
                  TextButton(
                    onPressed: () => _openSettings(context),
                    child: Text('prayer_times.open_settings'.tr()),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openSettings(BuildContext context) async {
    final service = getIt<LocationService>();
    if (state.status == PrayerTimesStatus.serviceDisabled) {
      await service.openLocationSettings();
    } else {
      await service.openAppSettings();
    }
  }

  Future<void> _showManualDialog(
    BuildContext context,
    PrayerTimesCubit cubit,
  ) async {
    final labelController = TextEditingController();
    final latController = TextEditingController();
    final lngController = TextEditingController();

    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('prayer_times.manual_location'.tr()),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: labelController,
              decoration: InputDecoration(
                labelText: 'prayer_times.city_label'.tr(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: latController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
                signed: true,
              ),
              decoration: InputDecoration(
                labelText: 'prayer_times.latitude'.tr(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: lngController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
                signed: true,
              ),
              decoration: InputDecoration(
                labelText: 'prayer_times.longitude'.tr(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('common.cancel'.tr()),
          ),
          ElevatedButton(
            onPressed: () async {
              final lat = double.tryParse(latController.text.trim());
              final lng = double.tryParse(lngController.text.trim());
              if (lat == null || lng == null) {
                return;
              }
              final label = labelController.text.trim().isEmpty
                  ? '${lat.toStringAsFixed(2)}, ${lng.toStringAsFixed(2)}'
                  : labelController.text.trim();
              await cubit.setManualLocation(
                    latitude: lat,
                    longitude: lng,
                    label: label,
                  );
              if (context.mounted) {
                Navigator.pop(context);
              }
            },
            child: Text('common.save'.tr()),
          ),
        ],
      ),
    );
  }
}

class _OffsetRow extends StatelessWidget {
  const _OffsetRow({
    required this.label,
    required this.value,
    required this.onChanged,
    required this.isDark,
  });

  final String label;
  final int value;
  final ValueChanged<int> onChanged;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final accentColor =
        isDark ? const Color(0xFF6EE7E8) : const Color(0xFFC58B55);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          IconButton(
            icon: const Icon(Icons.remove),
            color: accentColor,
            onPressed: () => onChanged(value - 1),
          ),
          Text('$value'),
          IconButton(
            icon: const Icon(Icons.add),
            color: accentColor,
            onPressed: () => onChanged(value + 1),
          ),
          const SizedBox(width: 4),
          Text('prayer_times.minutes'.tr()),
        ],
      ),
    );
  }
}

class _DropdownField<T> extends StatelessWidget {
  const _DropdownField({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final String label;
  final T value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      value: value,
      items: items,
      onChanged: onChanged,
      decoration: InputDecoration(labelText: label),
    );
  }
}

class _BottomSheetContainer extends StatelessWidget {
  const _BottomSheetContainer({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F1C2E) : const Color(0xFFF3E7D2),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: child,
    );
  }
}

class _LocationActionButton extends StatelessWidget {
  const _LocationActionButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon),
        label: Text(label),
      ),
    );
  }
}

class _GlassCard extends StatelessWidget {
  const _GlassCard({required this.child, required this.isDark});

  final Widget child;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.15)
        : const Color(0xFFBFA272).withValues(alpha: 0.35);
    final background = isDark
        ? Colors.white.withValues(alpha: 0.06)
        : Colors.white.withValues(alpha: 0.55);

    return ClipRRect(
      borderRadius: BorderRadius.circular(26),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: borderColor, width: 1.2),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
            child: child,
          ),
        ),
      ),
    );
  }
}

class _PrayerItem {
  const _PrayerItem(this.prayer, this.time);

  final Prayer prayer;
  final DateTime time;
}

const _methodOptions = [
  CalculationMethod.egyptian,
  CalculationMethod.muslim_world_league,
  CalculationMethod.karachi,
  CalculationMethod.umm_al_qura,
  CalculationMethod.dubai,
  CalculationMethod.qatar,
  CalculationMethod.kuwait,
  CalculationMethod.moon_sighting_committee,
  CalculationMethod.singapore,
  CalculationMethod.turkey,
  CalculationMethod.tehran,
  CalculationMethod.north_america,
  CalculationMethod.other,
];
