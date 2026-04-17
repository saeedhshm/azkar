import 'dart:async';
import 'dart:ui';

import 'package:adhan/adhan.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/time_formatter.dart';
import '../../data/models/city_entry.dart';
import '../../data/services/location_service.dart';
import '../../../settings/presentation/cubit/time_format_cubit.dart';
import '../cubit/prayer_times_cubit.dart';
import '../cubit/prayer_times_state.dart';
import '../widgets/next_prayer_hero_card.dart';
import '../widgets/prayer_times_grid.dart';

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
    final now = DateTime.now();
    final window = _buildPrayerWindow(times, state.nextPrayerTime);
    final currentLabel = _prayerLabel(
      state.currentPrayer ?? window.currentPrayer,
    );
    final nextPrayerLabel = _prayerLabel(state.nextPrayer);
    final nextTime = state.nextPrayerTime == null
        ? '--:--'
        : TimeFormatter.formatDateTime(
            state.nextPrayerTime!,
            use24h: use24h,
            locale: locale,
          );

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 104),
      children: [
        NextPrayerHeroCard(
          label: 'prayer_times.next_prayer'.tr(),
          prayerName: nextPrayerLabel,
          countdown: _formatCountdown(state.countdown),
          currentContext: 'prayer_times.current_context'.tr(
            namedArgs: {'prayer': currentLabel},
          ),
          nextPrayerTimeLine: 'prayer_times.next_at'.tr(
            namedArgs: {'prayer': nextPrayerLabel, 'time': nextTime},
          ),
          progressStartLabel: window.startLabel,
          progressEndLabel: window.endLabel,
          progress: window.progress,
          location: locationText,
          dateLine: [
            if (state.hijriDate != null && state.hijriDate!.isNotEmpty)
              state.hijriDate!,
            if (state.gregorianDate != null && state.gregorianDate!.isNotEmpty)
              state.gregorianDate!,
          ].join('  •  '),
          onLocationTap: () => _showLocationSheet(context, state),
        ),
        const SizedBox(height: 16),
        PrayerTimesGrid(
          items: items.map((item) {
            return PrayerTimeTileData(
              name: _prayerLabel(item.prayer),
              time: TimeFormatter.formatDateTime(
                item.time,
                use24h: use24h,
                locale: locale,
              ),
              icon: _prayerIcon(item.prayer),
              isCurrent: state.currentPrayer == item.prayer,
              isPast: item.time.isBefore(now),
            );
          }).toList(),
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

  IconData _prayerIcon(Prayer prayer) {
    return switch (prayer) {
      Prayer.fajr => Icons.nightlight_round,
      Prayer.sunrise => Icons.wb_twilight_rounded,
      Prayer.dhuhr => Icons.wb_sunny_rounded,
      Prayer.asr => Icons.light_mode_rounded,
      Prayer.maghrib => Icons.wb_twilight_rounded,
      Prayer.isha => Icons.dark_mode_rounded,
      _ => Icons.access_time_rounded,
    };
  }

  _PrayerWindow _buildPrayerWindow(PrayerTimes times, DateTime? nextTime) {
    final now = DateTime.now();
    final ordered = <_PrayerItem>[
      _PrayerItem(Prayer.fajr, times.fajr),
      _PrayerItem(Prayer.sunrise, times.sunrise),
      _PrayerItem(Prayer.dhuhr, times.dhuhr),
      _PrayerItem(Prayer.asr, times.asr),
      _PrayerItem(Prayer.maghrib, times.maghrib),
      _PrayerItem(Prayer.isha, times.isha),
    ];

    _PrayerItem? current;
    for (final item in ordered) {
      if (!item.time.isAfter(now)) {
        current = item;
      }
    }

    final nextPrayer = state.nextPrayer ?? Prayer.fajr;
    final startTime = current?.time;
    final endTime = nextTime;
    var progress = 0.0;
    if (startTime != null && endTime != null && endTime.isAfter(startTime)) {
      progress =
          now.difference(startTime).inSeconds /
          endTime.difference(startTime).inSeconds;
    }

    return _PrayerWindow(
      currentPrayer: current?.prayer,
      startLabel: current == null
          ? _prayerLabel(nextPrayer)
          : _prayerLabel(current.prayer),
      endLabel: _prayerLabel(nextPrayer),
      progress: progress,
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

class _PermissionCard extends StatelessWidget {
  const _PermissionCard({required this.state});

  final PrayerTimesState state;

  @override
  Widget build(BuildContext context) {
    final accentColor = Theme.of(context).colorScheme.primary;

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

class _BottomSheetContainer extends StatelessWidget {
  const _BottomSheetContainer({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = AppThemeColors.of(context);
    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      decoration: BoxDecoration(
        color: colors.cardSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(top: BorderSide(color: colors.softBorder)),
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
  const _GlassCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = AppThemeColors.of(context);
    final borderColor = colors.softBorder;
    final background = colors.cardSurface;

    return ClipRRect(
      borderRadius: BorderRadius.circular(colors.cardRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(colors.cardRadius),
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

class _PrayerWindow {
  const _PrayerWindow({
    required this.currentPrayer,
    required this.startLabel,
    required this.endLabel,
    required this.progress,
  });

  final Prayer? currentPrayer;
  final String startLabel;
  final String endLabel;
  final double progress;
}
