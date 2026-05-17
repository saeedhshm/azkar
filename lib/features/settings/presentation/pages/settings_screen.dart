import 'package:adhan/adhan.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/storage/local_storage_service.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/time_formatter.dart';
import '../../../prayer_times/data/services/prayer_settings_provider.dart';
import '../../../prayer_times/domain/entities/prayer_settings.dart';
import '../cubit/notification_settings_cubit.dart';
import '../cubit/notification_settings_state.dart';
import '../cubit/theme_cubit.dart';
import '../cubit/time_format_cubit.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  static const List<String> _languageCodes = ['en', 'ar', 'tr', 'id'];

  Future<void> _pickTime(
    BuildContext context, {
    required TimeOfDay initial,
    required ValueChanged<TimeOfDay> onSelected,
  }) async {
    final result = await showTimePicker(context: context, initialTime: initial);
    if (result != null) onSelected(result);
  }

  Future<void> _changeLanguage(BuildContext context, String code) async {
    await context.setLocale(Locale(code));
    await getIt<LocalStorageService>().saveLocaleCode(code);
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<NotificationSettingsCubit>(
      create: (_) => getIt<NotificationSettingsCubit>()..load(),
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'common.settings'.tr(),
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
        ),
        body: BlocConsumer<NotificationSettingsCubit,
            NotificationSettingsState>(
          listener: (context, state) {
            if (state.saveStatus == NotificationSaveStatus.saved) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('settings.saved'.tr())),
              );
            }
          },
          builder: (context, state) {
            final themeMode = context.watch<ThemeCubit>().state;
            final use24h = context.watch<TimeFormatCubit>().state.use24h;
            final currentLanguage = context.locale.languageCode;

            return ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.xxl,
              ),
              children: [
                const _PrayerCalculationSection(),
                const SizedBox(height: AppSpacing.lg),
                _SettingsSection(
                  icon: Icons.palette_outlined,
                  title: 'settings.appearance'.tr(),
                  children: [
                    _ThemeModeSelector(
                      value: themeMode,
                      onChanged: context.read<ThemeCubit>().setMode,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _SettingsSwitchTile(
                      icon: Icons.schedule_rounded,
                      title: 'settings.use_24h'.tr(),
                      subtitle: use24h ? '24:00' : '12:00 AM/PM',
                      value: use24h,
                      onChanged: context.read<TimeFormatCubit>().setUse24h,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                _SettingsSection(
                  icon: Icons.language_rounded,
                  title: 'settings.language.title'.tr(),
                  children: [
                    _SettingsDropdownTile<String>(
                      icon: Icons.translate_rounded,
                      title: 'settings.language.label'.tr(),
                      value: _languageCodes.contains(currentLanguage)
                          ? currentLanguage
                          : 'en',
                      items: _languageCodes
                          .map(
                            (c) => DropdownMenuItem<String>(
                              value: c,
                              child: Text('settings.language.$c'.tr()),
                            ),
                          )
                          .toList(),
                      onChanged: (v) {
                        if (v != null) _changeLanguage(context, v);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                _SettingsSection(
                  icon: Icons.notifications_outlined,
                  title: 'settings.reminders'.tr(),
                  children: [
                    _SettingsSwitchTile(
                      icon: Icons.notifications_active_outlined,
                      title: 'settings.enable_notifications'.tr(),
                      subtitle: 'settings.reminders'.tr(),
                      value: state.enabled,
                      onChanged: context
                          .read<NotificationSettingsCubit>()
                          .setEnabled,
                    ),
                    ...[
                      (
                        'settings.morning_reminder'.tr(),
                        state.morning,
                        context
                            .read<NotificationSettingsCubit>()
                            .setMorning,
                      ),
                      (
                        'settings.evening_reminder'.tr(),
                        state.evening,
                        context
                            .read<NotificationSettingsCubit>()
                            .setEvening,
                      ),
                      (
                        'settings.sleep_reminder'.tr(),
                        state.sleep,
                        context.read<NotificationSettingsCubit>().setSleep,
                      ),
                      (
                        'settings.waking_reminder'.tr(),
                        state.waking,
                        context.read<NotificationSettingsCubit>().setWaking,
                      ),
                      (
                        'settings.friday_reminder'.tr(),
                        state.friday,
                        context.read<NotificationSettingsCubit>().setFriday,
                      ),
                    ].map(
                      (t) => _TimeTile(
                        title: t.$1,
                        time: t.$2,
                        use24h: use24h,
                        onTap: () => _pickTime(
                          context,
                          initial: t.$2,
                          onSelected: t.$3,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed:
                            state.saveStatus == NotificationSaveStatus.saving
                                ? null
                                : context
                                    .read<NotificationSettingsCubit>()
                                    .save,
                        icon: state.saveStatus ==
                                NotificationSaveStatus.saving
                            ? const SizedBox.square(
                                dimension: 16,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.save_rounded, size: 18),
                        label: Text('settings.save_notifications'.tr()),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xl),
                const _SettingsFooter(),
              ],
            );
          },
        ),
      ),
    );
  }
}

// ─── Prayer Calculation Section ───────────────────────────────────────────────

class _PrayerCalculationSection extends StatefulWidget {
  const _PrayerCalculationSection();

  @override
  State<_PrayerCalculationSection> createState() =>
      _PrayerCalculationSectionState();
}

class _PrayerCalculationSectionState
    extends State<_PrayerCalculationSection> {
  late final PrayerSettingsProvider _provider;
  late PrayerSettings _settings;

  @override
  void initState() {
    super.initState();
    _provider = getIt<PrayerSettingsProvider>();
    _settings = _provider.load();
  }

  Future<void> _save(PrayerSettings settings) async {
    setState(() => _settings = settings);
    await _provider.save(settings);
  }

  @override
  Widget build(BuildContext context) {
    return _SettingsSection(
      icon: Icons.mosque_outlined,
      title: 'settings.prayer_calculation'.tr(),
      children: [
        _SettingsDropdownTile<CalculationMethod>(
          icon: Icons.tune_rounded,
          title: 'prayer_times.method'.tr(),
          value: _settings.method,
          items: _methodOptions
              .map(
                (m) => DropdownMenuItem<CalculationMethod>(
                  value: m,
                  child: Text(_methodLabel(m)),
                ),
              )
              .toList(),
          onChanged: (v) {
            if (v != null) _save(_settings.copyWith(method: v));
          },
        ),
        _SettingsDropdownTile<Madhab>(
          icon: Icons.account_balance_outlined,
          title: 'prayer_times.madhab_label'.tr(),
          value: _settings.madhab,
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
          onChanged: (v) {
            if (v != null) _save(_settings.copyWith(madhab: v));
          },
        ),
      ],
    );
  }

  String _methodLabel(CalculationMethod method) {
    return switch (method) {
      CalculationMethod.muslim_world_league =>
        'prayer_times.methods.mwl'.tr(),
      CalculationMethod.egyptian => 'prayer_times.methods.egyptian'.tr(),
      CalculationMethod.karachi => 'prayer_times.methods.karachi'.tr(),
      CalculationMethod.umm_al_qura =>
        'prayer_times.methods.umm_al_qura'.tr(),
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
}

// ─── Theme Mode Selector ──────────────────────────────────────────────────────

class _ThemeModeSelector extends StatelessWidget {
  const _ThemeModeSelector({
    required this.value,
    required this.onChanged,
  });

  final ThemeMode value;
  final ValueChanged<ThemeMode> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;

    final options = [
      (ThemeMode.system, Icons.contrast_rounded, 'settings.theme_system'.tr()),
      (ThemeMode.light, Icons.light_mode_rounded, 'settings.theme_light'.tr()),
      (ThemeMode.dark, Icons.dark_mode_rounded, 'settings.theme_dark'.tr()),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.contrast_rounded,
                size: 18,
                color: onSurface.withValues(alpha: 0.5),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'settings.theme_mode'.tr(),
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          SegmentedButton<ThemeMode>(
            segments: options
                .map(
                  (opt) => ButtonSegment<ThemeMode>(
                    value: opt.$1,
                    icon: Icon(opt.$2, size: 18),
                    label: Text(opt.$3),
                  ),
                )
                .toList(),
            selected: {value},
            onSelectionChanged: (selected) {
              if (selected.isNotEmpty) onChanged(selected.first);
            },
            style: SegmentedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Settings Section ─────────────────────────────────────────────────────────

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({
    required this.icon,
    required this.title,
    required this.children,
  });

  final IconData icon;
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.sm,
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Icon(
                    icon,
                    size: 16,
                    color: primary,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ...children,
          const SizedBox(height: AppSpacing.xs),
        ],
      ),
    );
  }
}

// ─── Settings Row Types ───────────────────────────────────────────────────────

/// A settings row with a dropdown selector.
///
/// Uses a custom [Row] layout instead of [ListTile] to prevent
/// mid-word text wrapping when the title is long and the screen is narrow.
/// The title occupies all remaining space between the icon and dropdown,
/// with proper overflow handling (maxLines: 2, ellipsis).
class _SettingsDropdownTile<T> extends StatelessWidget {
  const _SettingsDropdownTile({
    required this.icon,
    required this.title,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final T value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Leading icon — fixed width
          SizedBox(
            width: 24,
            child: Icon(
              icon,
              size: 20,
              color: onSurface.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          // Title — takes all remaining space, wraps at word boundaries only
          Flexible(
            child: Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          // Dropdown — use isExpanded to fit available space
          Flexible(
            fit: FlexFit.loose,
            child: DropdownButtonHideUnderline(
              child: DropdownButton<T>(
                value: value,
                items: items,
                onChanged: onChanged,
                borderRadius: BorderRadius.circular(AppRadius.md),
                isDense: true,
                isExpanded: true,
                alignment: AlignmentDirectional.centerEnd,
                style: theme.textTheme.bodyMedium,
                menuMaxHeight: 300,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsSwitchTile extends StatelessWidget {
  const _SettingsSwitchTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      child: Row(
        children: [
          SizedBox(
            width: 24,
            child: Icon(
              icon,
              size: 20,
              color: onSurface.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (subtitle.isNotEmpty)
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: onSurface.withValues(alpha: 0.5),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _TimeTile extends StatelessWidget {
  const _TimeTile({
    required this.title,
    required this.time,
    required this.use24h,
    required this.onTap,
  });

  final String title;
  final TimeOfDay time;
  final bool use24h;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final onSurface = theme.colorScheme.onSurface;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Icon(Icons.alarm_rounded, color: primary, size: 18),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  TimeFormatter.formatTimeOfDay(
                    time,
                    use24h: use24h,
                    locale: context.locale.toString(),
                  ),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Icon(
              Icons.chevron_right_rounded,
              size: 16,
              color: onSurface.withValues(alpha: 0.4),
            ),
          ),
        ],
      ),
    ).inkWell(onTap: onTap);
  }
}

// ─── Footer ───────────────────────────────────────────────────────────────────

class _SettingsFooter extends StatelessWidget {
  const _SettingsFooter();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;

    return Column(
      children: [
        const Divider(),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'settings.footer.app_name'.tr(),
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall?.copyWith(
            color: onSurface.withValues(alpha: 0.5),
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'settings.footer.version'.tr(namedArgs: {'version': '1.0.0'}),
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall?.copyWith(
            color: onSurface.withValues(alpha: 0.3),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
      ],
    );
  }
}

// ─── Calculation Methods ──────────────────────────────────────────────────────

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

// ─── Extension for InkWell ────────────────────────────────────────────────────

extension _InkWellExtension on Widget {
  Widget inkWell({VoidCallback? onTap, BorderRadius? borderRadius}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: borderRadius ?? BorderRadius.circular(AppRadius.md),
        child: this,
      ),
    );
  }
}
