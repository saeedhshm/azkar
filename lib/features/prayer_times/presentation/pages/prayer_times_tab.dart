import 'dart:async';

import 'package:adhan/adhan.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/utils/time_formatter.dart';
import '../../../../core/widgets/app_bottom_sheet.dart';
import '../../../../core/widgets/app_empty_state.dart';
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
            return const _PrayerTimesLoadingSkeleton();
          }

          if (state.status == PrayerTimesStatus.permissionDenied ||
              state.status == PrayerTimesStatus.permissionDeniedForever ||
              state.status == PrayerTimesStatus.serviceDisabled) {
            return _PermissionCard(state: state);
          }

          if (state.status == PrayerTimesStatus.failure) {
            return AppErrorState(
              message: state.errorMessage ?? 'common.failed_load_adhkar'.tr(),
              onRetry: () => context.read<PrayerTimesCubit>().refresh(),
            );
          }

          return _PrayerTimesContent(state: state);
        },
      ),
    );
  }
}

// ─── Loading Skeleton ─────────────────────────────────────────────────────────

class _PrayerTimesLoadingSkeleton extends StatefulWidget {
  const _PrayerTimesLoadingSkeleton();

  @override
  State<_PrayerTimesLoadingSkeleton> createState() =>
      _PrayerTimesLoadingSkeletonState();
}

class _PrayerTimesLoadingSkeletonState
    extends State<_PrayerTimesLoadingSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
    _anim = Tween<double>(begin: -1, end: 2).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final shimmerBase = isDark ? const Color(0xFF303030) : const Color(0xFFE0E0E0);
    final shimmerHighlight = isDark ? const Color(0xFF424242) : const Color(0xFFF5F5F5);

    return AnimatedBuilder(
      animation: _anim,
      builder: (_, child) => ShaderMask(
        shaderCallback: (bounds) => LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            shimmerBase,
            shimmerHighlight,
            shimmerBase,
          ],
          stops: [
            (_anim.value - 0.3).clamp(0.0, 1.0),
            _anim.value.clamp(0.0, 1.0),
            (_anim.value + 0.3).clamp(0.0, 1.0),
          ],
        ).createShader(bounds),
        blendMode: BlendMode.srcATop,
        child: child,
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
        child: Column(
          children: [
            // Hero card skeleton
            Container(
              height: 190,
              decoration: BoxDecoration(
                color: shimmerBase,
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
            ),
            const SizedBox(height: 14),
            // Grid skeleton
            Expanded(
              child: GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                itemCount: 6,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 1.1,
                ),
                itemBuilder: (_, _) => Container(
                  decoration: BoxDecoration(
                    color: shimmerBase,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Content ──────────────────────────────────────────────────────────────────

class _PrayerTimesContent extends StatelessWidget {
  const _PrayerTimesContent({required this.state});

  final PrayerTimesState state;

  @override
  Widget build(BuildContext context) {
    final times = state.prayerTimes;
    if (times == null) return const SizedBox.shrink();

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
    final window = _buildPrayerWindow(times, state.nextPrayerTime,
        use24h: use24h, locale: locale);
    final currentLabel =
        _prayerLabel(state.currentPrayer ?? window.currentPrayer);
    final nextPrayerLabel = _prayerLabel(state.nextPrayer);
    final nextTime = state.nextPrayerTime == null
        ? '--:--'
        : TimeFormatter.formatDateTime(
            state.nextPrayerTime!,
            use24h: use24h,
            locale: locale,
          );

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Column(
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
            progressStartTime: window.startTime,
            progressEndTime: window.endTime,
            progress: window.progress,
            location: locationText,
            hijriDate: state.hijriDate ?? '',
            gregorianDate: state.gregorianDate ?? '',
            onLocationTap: () => _showLocationSheet(context, state),
          ),
          const SizedBox(height: 14),
          Expanded(
            child: PrayerTimesGrid(
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
                  isNext: state.nextPrayer == item.prayer,
                  isPast: item.time.isBefore(now),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  String _formatCountdown(Duration? duration) {
    if (duration == null) return '--:--:--';
    final h = duration.inHours.toString().padLeft(2, '0');
    final m = (duration.inMinutes % 60).toString().padLeft(2, '0');
    final s = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
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

  _PrayerWindow _buildPrayerWindow(
    PrayerTimes times,
    DateTime? nextTime, {
    required bool use24h,
    required String locale,
  }) {
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
      if (!item.time.isAfter(now)) current = item;
    }

    final nextPrayer = state.nextPrayer ?? Prayer.fajr;
    final startDateTime = current?.time;
    final endDateTime = nextTime;
    var progress = 0.0;
    if (startDateTime != null &&
        endDateTime != null &&
        endDateTime.isAfter(startDateTime)) {
      progress = now.difference(startDateTime).inSeconds /
          endDateTime.difference(startDateTime).inSeconds;
    }

    return _PrayerWindow(
      currentPrayer: current?.prayer,
      startLabel: current == null
          ? _prayerLabel(nextPrayer)
          : _prayerLabel(current.prayer),
      endLabel: _prayerLabel(nextPrayer),
      startTime: startDateTime == null
          ? ''
          : TimeFormatter.formatDateTime(startDateTime,
              use24h: use24h, locale: locale),
      endTime: endDateTime == null
          ? ''
          : TimeFormatter.formatDateTime(endDateTime,
              use24h: use24h, locale: locale),
      progress: progress,
    );
  }

  Future<void> _showLocationSheet(
    BuildContext context,
    PrayerTimesState state,
  ) async {
    final cubit = context.read<PrayerTimesCubit>();
    final labelController =
        TextEditingController(text: state.locationLabel ?? '');
    final latController =
        TextEditingController(text: state.latitude?.toStringAsFixed(6) ?? '');
    final lngController =
        TextEditingController(text: state.longitude?.toStringAsFixed(6) ?? '');

    await AppBottomSheet.show<void>(
      context: context,
      title: 'prayer_times.location'.tr(),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
            Text(
              'prayer_times.location_hint'.tr(),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
            ),
          const SizedBox(height: 16),
          AppSheetActionButton(
            label: 'prayer_times.use_device_location'.tr(),
            icon: Icons.my_location_rounded,
            onTap: () async {
              await cubit.useDeviceLocation();
              if (context.mounted) Navigator.pop(context);
            },
          ),
          const SizedBox(height: 10),
          AppSheetActionButton(
            label: 'prayer_times.select_city'.tr(),
            icon: Icons.location_city_rounded,
            onTap: () async {
              final selection = await _showCitySearchSheet(context, cubit);
              if (selection == null) return;
              await cubit.setManualLocation(
                latitude: selection.latitude,
                longitude: selection.longitude,
                label: selection.displayName,
              );
              if (context.mounted) Navigator.pop(context);
            },
          ),
          const SizedBox(height: 16),
          TextField(
            controller: labelController,
            decoration: InputDecoration(
              labelText: 'prayer_times.city_label'.tr(),
              prefixIcon: const Icon(Icons.label_outline_rounded, size: 20),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: latController,
                  keyboardType: const TextInputType.numberWithOptions(
                      decimal: true, signed: true),
                  decoration: InputDecoration(
                    labelText: 'prayer_times.latitude'.tr(),
                    prefixIcon: const Icon(Icons.north_rounded, size: 20),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: lngController,
                  keyboardType: const TextInputType.numberWithOptions(
                      decimal: true, signed: true),
                  decoration: InputDecoration(
                    labelText: 'prayer_times.longitude'.tr(),
                    prefixIcon: const Icon(Icons.east_rounded, size: 20),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () async {
                final lat = double.tryParse(latController.text.trim());
                final lng = double.tryParse(lngController.text.trim());
                if (lat == null || lng == null) return;
                final label = labelController.text.trim().isEmpty
                    ? '${lat.toStringAsFixed(2)}, ${lng.toStringAsFixed(2)}'
                    : labelController.text.trim();
                await context
                    .read<PrayerTimesCubit>()
                    .setManualLocation(latitude: lat, longitude: lng, label: label);
                if (context.mounted) Navigator.pop(context);
              },
              icon: const Icon(Icons.save_rounded, size: 18),
              label: Text('common.save'.tr()),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── City Search Sheet ────────────────────────────────────────────────────────

Future<CityEntry?> _showCitySearchSheet(
  BuildContext context,
  PrayerTimesCubit cubit,
) {
  return showModalBottomSheet<CityEntry>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) => AppBottomSheet(
      title: 'prayer_times.select_city'.tr(),
      child: _CitySearchSheet(cubit: cubit),
    ),
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
    if (!mounted) return;
    setState(() {
      _available = available;
      _isOnline = online;
      _loading = false;
    });
  }

  void _onQueryChanged() {
    final query = _controller.text.trim();
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () async {
      if (!mounted) return;
      if (query.length < 2) {
        setState(() {
          _results = [];
          _searching = false;
        });
        return;
      }
      setState(() => _searching = true);
      final results = await widget.cubit.searchCities(query);
      if (!mounted) return;
      setState(() {
        _results = results;
        _searching = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_loading) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: theme.colorScheme.primary),
            const SizedBox(height: 16),
            Text(
              'prayer_times.downloading_cities'.tr(),
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
            ),
          ],
        ),
      );
    }

    if (!_available) {
      final message = _isOnline
          ? 'prayer_times.city_download_failed'.tr()
          : 'prayer_times.city_unavailable_offline'.tr();
      return AppErrorState(
        message: message,
        onRetry: _prepare,
        retryLabel: 'common.retry'.tr(),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextField(
          controller: _controller,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'prayer_times.search_city_hint'.tr(),
            prefixIcon: const Icon(Icons.search_rounded, size: 20),
            suffixIcon: _controller.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear_rounded, size: 18),
                    onPressed: () {
                      _controller.clear();
                      setState(() => _results = []);
                    },
                  )
                : null,
          ),
        ),
        const SizedBox(height: 12),
        if (_searching)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: theme.colorScheme.primary,
            ),
          )
        else if (_results.isEmpty && _controller.text.trim().length >= 2)
          AppEmptyState(
            icon: Icons.location_off_rounded,
            title: 'prayer_times.no_city_results'.tr(),
          )
        else if (_results.isNotEmpty)
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 300),
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: _results.length,
              separatorBuilder: (_, _) => Divider(
                height: 1,
                color: theme.colorScheme.outlineVariant,
              ),
              itemBuilder: (context, index) {
                final city = _results[index];
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 4, vertical: 2),
                  leading: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.location_city_rounded,
                      size: 18,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  title: Text(
                    city.displayName,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    '${city.latitude.toStringAsFixed(2)}° N, '
                    '${city.longitude.toStringAsFixed(2)}° E',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
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

// ─── Permission Card ──────────────────────────────────────────────────────────

class _PermissionCard extends StatelessWidget {
  const _PermissionCard({required this.state});
  final PrayerTimesState state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accentColor = theme.colorScheme.primary;

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
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(AppRadius.xl),
            border: Border.all(color: theme.colorScheme.outlineVariant),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                  border:
                      Border.all(color: accentColor.withValues(alpha: 0.3)),
                ),
                child: Icon(Icons.location_off_rounded,
                    color: accentColor, size: 34),
              ),
              const SizedBox(height: 20),
              Text(
                message,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge?.copyWith(
                  height: 1.5,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 24),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                alignment: WrapAlignment.center,
                children: [
                  FilledButton.icon(
                    onPressed: () =>
                        context.read<PrayerTimesCubit>().refresh(),
                    icon: const Icon(Icons.refresh_rounded, size: 16),
                    label: Text('common.retry'.tr()),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => _showManualDialog(
                        context, context.read<PrayerTimesCubit>()),
                    icon: const Icon(Icons.edit_location_rounded, size: 16),
                    label: Text('prayer_times.manual_location'.tr()),
                  ),
                  TextButton.icon(
                    onPressed: () => _openSettings(context),
                    icon: const Icon(Icons.settings_rounded, size: 16),
                    label: Text('prayer_times.open_settings'.tr()),
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
      BuildContext context, PrayerTimesCubit cubit) async {
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
                prefixIcon: const Icon(Icons.label_outline_rounded, size: 20),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: latController,
              keyboardType: const TextInputType.numberWithOptions(
                  decimal: true, signed: true),
              decoration: InputDecoration(
                labelText: 'prayer_times.latitude'.tr(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: lngController,
              keyboardType: const TextInputType.numberWithOptions(
                  decimal: true, signed: true),
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
          FilledButton(
            onPressed: () async {
              final lat = double.tryParse(latController.text.trim());
              final lng = double.tryParse(lngController.text.trim());
              if (lat == null || lng == null) return;
              final label = labelController.text.trim().isEmpty
                  ? '${lat.toStringAsFixed(2)}, ${lng.toStringAsFixed(2)}'
                  : labelController.text.trim();
              await cubit.setManualLocation(
                  latitude: lat, longitude: lng, label: label);
              if (context.mounted) Navigator.pop(context);
            },
            child: Text('common.save'.tr()),
          ),
        ],
      ),
    );
  }
}

// ─── Internal helpers ─────────────────────────────────────────────────────────

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
    required this.startTime,
    required this.endTime,
    required this.progress,
  });
  final Prayer? currentPrayer;
  final String startLabel;
  final String endLabel;
  final String startTime;
  final String endTime;
  final double progress;
}
