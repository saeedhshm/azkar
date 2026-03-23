import 'dart:async';
import 'dart:math';
import 'dart:ui';

import 'package:adhan/adhan.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_qiblah/flutter_qiblah.dart';
import 'package:intl/intl.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/utils/time_formatter.dart';
import '../../data/models/city_entry.dart';
import '../../data/services/location_service.dart';
import '../../../settings/presentation/cubit/time_format_cubit.dart';
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
              child: Text(
                state.errorMessage ?? 'common.failed_load_adhkar'.tr(),
              ),
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
    final accentColor = isDark
        ? const Color(0xFF6EE7E8)
        : const Color(0xFFD4A574);
    final warmGold = isDark ? const Color(0xFFF2C777) : const Color(0xFFC58B55);

    final times = state.prayerTimes;
    if (times == null) {
      return const SizedBox.shrink();
    }

    final items = <_PrayerItem>[
      _PrayerItem(Prayer.fajr, times.fajr),
      _PrayerItem(Prayer.sunrise, times.sunrise),
      _PrayerItem(Prayer.dhuhr, times.dhuhr),
      _PrayerItem(Prayer.asr, times.asr),
      _PrayerItem(Prayer.maghrib, times.maghrib),
      _PrayerItem(Prayer.isha, times.isha),
    ];

    final rawLocation = state.locationLabel;
    final locationText =
        rawLocation == null ||
            rawLocation.trim().isEmpty ||
            rawLocation == 'GPS'
        ? 'prayer_times.current_location'.tr()
        : rawLocation;
    final use24h = context.watch<TimeFormatCubit>().state.use24h;
    final locale = context.locale.toString();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 140),
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
              : TimeFormatter.formatDateTime(
                  state.nextPrayerTime!,
                  use24h: use24h,
                  locale: locale,
                ),
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
                    isNext: state.nextPrayer == Prayer.fajr,
                    use24h: use24h,
                    locale: locale,
                  ),
                ),
                SizedBox(
                  width: tileWidth,
                  child: _PrayerTile(
                    item: items[1],
                    isDark: isDark,
                    isCurrent: state.currentPrayer == Prayer.sunrise,
                    style: sunCard,
                    label: _prayerLabel(Prayer.sunrise),
                    accent: warmGold,
                    isNext: state.nextPrayer == Prayer.sunrise,
                    use24h: use24h,
                    locale: locale,
                  ),
                ),
                SizedBox(
                  width: tileWidth,
                  child: _PrayerTile(
                    item: items[2],
                    isDark: isDark,
                    isCurrent: state.currentPrayer == Prayer.dhuhr,
                    style: sunCard,
                    label: _prayerLabel(Prayer.dhuhr),
                    accent: warmGold,
                    isNext: state.nextPrayer == Prayer.dhuhr,
                    use24h: use24h,
                    locale: locale,
                  ),
                ),
                SizedBox(
                  width: tileWidth,
                  child: _PrayerTile(
                    item: items[3],
                    isDark: isDark,
                    isCurrent: state.currentPrayer == Prayer.asr,
                    style: sunCard,
                    label: _prayerLabel(Prayer.asr),
                    accent: warmGold,
                    isNext: state.nextPrayer == Prayer.asr,
                    use24h: use24h,
                    locale: locale,
                  ),
                ),
                SizedBox(
                  width: tileWidth,
                  child: _PrayerTile(
                    item: items[4],
                    isDark: isDark,
                    isCurrent: state.currentPrayer == Prayer.maghrib,
                    style: sunsetCard,
                    label: _prayerLabel(Prayer.maghrib),
                    accent: warmGold,
                    isNext: state.nextPrayer == Prayer.maghrib,
                    use24h: use24h,
                    locale: locale,
                  ),
                ),
                SizedBox(
                  width: tileWidth,
                  child: _PrayerTile(
                    item: items[5],
                    isDark: isDark,
                    isCurrent: state.currentPrayer == Prayer.isha,
                    style: nightCard,
                    label: _prayerLabel(Prayer.isha),
                    accent: accentColor,
                    isNext: state.nextPrayer == Prayer.isha,
                    use24h: use24h,
                    locale: locale,
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 14),
        _QiblaSection(isDark: isDark),
        const SizedBox(height: 14),
        _GlassCard(
          isDark: isDark,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'prayer_times.settings'.tr(),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              _SettingsRow(
                label: 'prayer_times.method'.tr(),
                value: _methodLabel(state.settings.method),
                onTap: () => _openSettingsSheet(context, state),
              ),
              const SizedBox(height: 8),
              _SettingsRow(
                label: 'prayer_times.madhab_label'.tr(),
                value: _madhabLabel(state.settings.madhab),
                onTap: () => _openSettingsSheet(context, state),
              ),
              const SizedBox(height: 8),
              _SettingsRow(
                label: 'settings.use_24h'.tr(),
                value: use24h ? '24h' : 'AM/PM',
                onTap: () => _openSettingsSheet(context, state),
              ),
            ],
          ),
        ),
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
      Prayer.sunrise => 'prayer_times.prayers.sunrise'.tr(),
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
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
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
    final labelController = TextEditingController(
      text: state.locationLabel ?? '',
    );
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
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              Text(
                'prayer_times.location_hint'.tr(),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
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
              _LocationActionButton(
                label: 'prayer_times.select_city'.tr(),
                icon: Icons.location_city,
                onTap: () async {
                  final selection = await _showCitySearchSheet(context, cubit);
                  if (selection == null) {
                    return;
                  }
                  await cubit.setManualLocation(
                    latitude: selection.latitude,
                    longitude: selection.longitude,
                    label: selection.displayName,
                  );
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
    final accentColor = isDark
        ? const Color(0xFF6EE7E8)
        : const Color(0xFFC58B55);
    final use24h = context.watch<TimeFormatCubit>().state.use24h;
    final timeText = TimeFormatter.formatDateTime(
      item.time,
      use24h: use24h,
      locale: context.locale.toString(),
    );

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
      Prayer.sunrise => 'prayer_times.prayers.sunrise'.tr(),
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
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF162336), Color(0xFF1B2A3F)],
          )
        : const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF8EEDC), Color(0xFFF2DEBF)],
          );
    final secondaryText =
        isDark ? Colors.white70 : const Color(0xFF6A4B2E);
    final primaryText = isDark ? Colors.white : const Color(0xFF4B321D);

    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: Container(
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: accentColor.withValues(alpha: isDark ? 0.28 : 0.35),
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
              child: CustomPaint(painter: _StarFieldPainter(isDark: isDark)),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          hijriLine ?? dateLine,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: secondaryText,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(Icons.location_on_outlined,
                          color: accentColor, size: 16),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          locationLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: secondaryText,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (hijriLine != null && dateLine.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      dateLine,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: secondaryText,
                      ),
                    ),
                  ],
                  const SizedBox(height: 10),
                  Text(
                    'prayer_times.next_prayer'.tr(),
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: secondaryText,
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
                      color: primaryText,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (time != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      time!,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: secondaryText,
                      ),
                    ),
                  ],
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: onChangeLocation,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: isDark ? 0.2 : 0.25),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: accentColor.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Text(
                        'prayer_times.change_location'.tr(),
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: accentColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
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

Future<CityEntry?> _showCitySearchSheet(
  BuildContext context,
  PrayerTimesCubit cubit,
) {
  return showModalBottomSheet<CityEntry>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) {
      return _BottomSheetContainer(child: _CitySearchSheet(cubit: cubit));
    },
  );
}

class _CitySearchSheet extends StatefulWidget {
  const _CitySearchSheet({required this.cubit});

  final PrayerTimesCubit cubit;

  @override
  State<_CitySearchSheet> createState() => _CitySearchSheetState();
}

class _CitySearchSheetState extends State<_CitySearchSheet> {
  final _controller = TextEditingController();
  Timer? _debounce;
  bool _loading = true;
  bool _available = false;
  bool _isOnline = false;
  String? _error;
  bool _searching = false;
  List<CityEntry> _results = [];

  @override
  void initState() {
    super.initState();
    _prepare();
    _controller.addListener(_onQueryChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _prepare() async {
    setState(() => _loading = true);
    final online = await widget.cubit.isOnline();
    final available = await widget.cubit.ensureCityDatabaseAvailable();
    if (!mounted) {
      return;
    }
    setState(() {
      _available = available;
      _isOnline = online;
      _error = widget.cubit.getCityDownloadError();
      _loading = false;
    });
  }

  void _onQueryChanged() {
    final query = _controller.text.trim();
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () async {
      if (!mounted) {
        return;
      }
      if (query.length < 2) {
        setState(() {
          _results = [];
          _searching = false;
        });
        return;
      }

      setState(() => _searching = true);
      final results = await widget.cubit.searchCities(query);
      if (!mounted) {
        return;
      }
      setState(() {
        _results = results;
        _searching = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          const CircularProgressIndicator(),
          const SizedBox(height: 12),
          Text('prayer_times.downloading_cities'.tr()),
        ],
      );
    }

    if (!_available) {
      final message = _isOnline
          ? 'prayer_times.city_download_failed'.tr()
          : 'prayer_times.city_unavailable_offline'.tr();
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message, textAlign: TextAlign.center),
          if (_error != null && _error!.trim().isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              '${'prayer_times.city_download_error_label'.tr()}: ${_error!}',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
          const SizedBox(height: 12),
          ElevatedButton(onPressed: _prepare, child: Text('common.retry'.tr())),
        ],
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'prayer_times.select_city'.tr(),
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _controller,
          decoration: InputDecoration(
            hintText: 'prayer_times.search_city_hint'.tr(),
            prefixIcon: const Icon(Icons.search),
          ),
        ),
        const SizedBox(height: 12),
        if (_searching)
          const Padding(
            padding: EdgeInsets.all(12),
            child: CircularProgressIndicator(),
          )
        else if (_results.isEmpty && _controller.text.trim().length >= 2)
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text('prayer_times.no_city_results'.tr()),
          )
        else if (_results.isNotEmpty)
          SizedBox(
            height: 320,
            child: ListView.separated(
              itemCount: _results.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final city = _results[index];
                return ListTile(
                  title: Text(city.displayName),
                  subtitle: Text(
                    '${city.latitude.toStringAsFixed(2)}, ${city.longitude.toStringAsFixed(2)}',
                  ),
                  onTap: () => Navigator.pop(context, city),
                );
              },
            ),
          ),
      ],
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
              ? [const Color(0xFF16263A), const Color(0xFF1A2B40)]
              : [const Color(0xFFF7EBD6), const Color(0xFFF0D9B7)],
        ),
        glow: accent,
        icon: Icons.wb_sunny_rounded,
        iconColor: accent,
      );
    case _PrayerVisualType.sunset:
      return _PrayerCardStyle(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF16263A), const Color(0xFF1A2B40)]
              : [const Color(0xFFF7EBD6), const Color(0xFFF0D9B7)],
        ),
        glow: accent,
        icon: Icons.wb_twilight_rounded,
        iconColor: accent,
      );
    case _PrayerVisualType.night:
      return _PrayerCardStyle(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF16263A), const Color(0xFF1A2B40)]
              : [const Color(0xFFF7EBD6), const Color(0xFFF0D9B7)],
        ),
        glow: accent,
        icon: Icons.nightlight_round,
        iconColor: accent,
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
    required this.use24h,
    required this.locale,
    this.isNext = false,
  });

  final _PrayerItem item;
  final bool isDark;
  final bool isCurrent;
  final _PrayerCardStyle style;
  final String label;
  final Color accent;
  final bool use24h;
  final String locale;
  final bool isNext;

  @override
  Widget build(BuildContext context) {
    final timeText = TimeFormatter.formatDateTime(
      item.time,
      use24h: use24h,
      locale: locale,
    );
    final titleStyle = Theme.of(context).textTheme.titleMedium?.copyWith(
          color: isDark ? Colors.white : const Color(0xFF4B321D),
          fontWeight: FontWeight.w700,
        );
    final timeStyle = Theme.of(context).textTheme.bodyLarge?.copyWith(
          color: isDark ? Colors.white70 : const Color(0xFF4B321D),
          fontWeight: FontWeight.w600,
        );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: style.gradient,
        border: Border.all(
          color: isCurrent
              ? accent
              : accent.withValues(alpha: isDark ? 0.2 : 0.25),
          width: isCurrent ? 2 : 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: style.glow.withValues(alpha: isDark ? 0.25 : 0.18),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        children: [
          if (isNext)
            Positioned(
              top: 0,
              left: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'common.next'.tr(),
                  style: TextStyle(
                    color: isDark ? Colors.black : Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                  ),
                ),
              ),
            ),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(style.icon, color: style.iconColor, size: 28),
                const SizedBox(height: 8),
                Text(label, style: titleStyle),
                const SizedBox(height: 6),
                Text(timeText, style: timeStyle),
              ],
            ),
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
        ..color = (isDark ? Colors.white : const Color(0xFFD4A574)).withValues(
          alpha: opacity,
        );
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
        style: TextStyle(color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _QiblaCompass extends StatelessWidget {
  const _QiblaCompass({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final accentColor = isDark
        ? const Color(0xFFF2C777)
        : const Color(0xFFC58B55);
    return SizedBox(
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
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: isDark
                        ? const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFF1A2A3E), Color(0xFF101B2B)],
                          )
                        : const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFFF6E5C9), Color(0xFFEBCFA4)],
                          ),
                    border: Border.all(
                      color: accentColor.withValues(alpha: 0.5),
                      width: 2,
                    ),
                  ),
                ),
                Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: accentColor.withValues(alpha: 0.25),
                      width: 1,
                    ),
                  ),
                ),
                Transform.rotate(
                  angle: angle,
                  child: Icon(Icons.navigation, size: 56, color: accentColor),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: accentColor.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Text(
                    '${direction.qiblah.toStringAsFixed(0)}°',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: accentColor,
                        ),
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
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'prayer_times.qibla'.tr(),
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
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

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? const Color(0xFFF2C777) : const Color(0xFFC58B55);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.04)
              : Colors.white.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: accent.withValues(alpha: isDark ? 0.18 : 0.3),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: isDark ? Colors.white70 : const Color(0xFF6A4B2E),
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: accent),
          ],
        ),
      ),
    );
  }
}

class _PermissionCard extends StatelessWidget {
  const _PermissionCard({required this.state});

  final PrayerTimesState state;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accentColor = isDark
        ? const Color(0xFF6EE7E8)
        : const Color(0xFFC58B55);

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
                    onPressed: () => _showManualDialog(
                      context,
                      context.read<PrayerTimesCubit>(),
                    ),
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
    final accentColor = isDark
        ? const Color(0xFF6EE7E8)
        : const Color(0xFFC58B55);

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
      initialValue: value,
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
        ? Colors.white.withValues(alpha: 0.12)
        : const Color(0xFFBFA272).withValues(alpha: 0.28);
    final background = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.white.withValues(alpha: 0.65);

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
