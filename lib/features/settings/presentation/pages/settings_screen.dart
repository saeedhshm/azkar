import 'package:adhan/adhan.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/storage/local_storage_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_radius.dart';
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
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          toolbarHeight: 64,
          title: Text(
            'common.settings'.tr(),
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
          ),
        ),
        body: SafeArea(
          top: false,
          child: BlocConsumer<NotificationSettingsCubit,
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
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                children: [
                  // ── Prayer Calculation ──────────────────
                  const _PrayerCalculationSection(),
                  const SizedBox(height: 16),

                  // ── Appearance ──────────────────────────
                  _SettingsSection(
                    icon: Icons.palette_outlined,
                    title: 'settings.appearance'.tr(),
                    children: [
                      // Theme mode segmented control
                      _ThemeModeSelector(
                        value: themeMode,
                        onChanged: context.read<ThemeCubit>().setMode,
                      ),
                      const SizedBox(height: 12),
                      _SettingsSwitchTile(
                        icon: Icons.schedule_rounded,
                        title: 'settings.use_24h'.tr(),
                        subtitle: use24h ? '24:00' : '12:00 AM/PM',
                        value: use24h,
                        onChanged: context.read<TimeFormatCubit>().setUse24h,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // ── Language ────────────────────────────
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
                  const SizedBox(height: 16),

                  // ── Reminders ───────────────────────────
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
                      const SizedBox(height: 12),
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

                  // ── Footer ──────────────────────────────
                  const SizedBox(height: 24),
                  _SettingsFooter(),
                ],
              );
            },
          ),
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
  const _ThemeModeSelector(
      {required this.value, required this.onChanged});

  final ThemeMode value;
  final ValueChanged<ThemeMode> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = AppThemeColors.of(context);
    final accent = colors.accentColor ?? theme.colorScheme.primary;

    final options = [
      (ThemeMode.system, Icons.contrast_rounded, 'settings.theme_system'.tr()),
      (ThemeMode.light, Icons.light_mode_rounded, 'settings.theme_light'.tr()),
      (ThemeMode.dark, Icons.dark_mode_rounded, 'settings.theme_dark'.tr()),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.contrast_rounded, size: 18, color: colors.prayerIcon),
              const SizedBox(width: 10),
              Text(
                'settings.theme_mode'.tr(),
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: options.map((opt) {
              final (mode, icon, label) = opt;
              final selected = value == mode;
              return Expanded(
                child: GestureDetector(
                  onTap: () => onChanged(mode),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    margin: const EdgeInsets.only(right: 6),
                    padding: const EdgeInsets.symmetric(
                        vertical: 10, horizontal: 8),
                    decoration: BoxDecoration(
                      color: selected
                          ? accent.withValues(alpha: 0.14)
                          : colors.pillBg,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: Border.all(
                        color: selected
                            ? accent.withValues(alpha: 0.5)
                            : colors.softBorder,
                        width: selected ? 1.5 : 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(icon,
                            size: 18,
                            color: selected ? accent : colors.mutedText),
                        const SizedBox(height: 4),
                        Text(
                          label,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: selected ? accent : colors.mutedText,
                            fontWeight: selected
                                ? FontWeight.w800
                                : FontWeight.w500,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
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
    final colors = AppThemeColors.of(context);

    return Container(
      decoration: BoxDecoration(
        color: colors.cardSurface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: colors.softBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
                alpha: theme.brightness == Brightness.dark ? 0.12 : 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: (colors.accentColor ?? theme.colorScheme.primary)
                        .withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon,
                      size: 16,
                      color:
                          colors.accentColor ?? theme.colorScheme.primary),
                ),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          // Divider
          Divider(height: 1, color: colors.softBorder),
          // Content
          ...children,
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}

// ─── Settings Row Types ───────────────────────────────────────────────────────

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
    final colors = AppThemeColors.of(context);

    return ListTile(
      minVerticalPadding: 12,
      leading: Icon(icon, color: colors.prayerIcon, size: 20),
      title: Text(title),
      trailing: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          items: items,
          onChanged: onChanged,
          borderRadius: BorderRadius.circular(AppRadius.md),
          isDense: true,
        ),
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
    final colors = AppThemeColors.of(context);

    return SwitchListTile.adaptive(
      secondary: Icon(icon, color: colors.prayerIcon, size: 20),
      title: Text(title),
      subtitle: Text(subtitle),
      value: value,
      onChanged: onChanged,
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
    final colors = AppThemeColors.of(context);
    final theme = Theme.of(context);
    final accent = colors.accentColor ?? theme.colorScheme.primary;

    return ListTile(
      minVerticalPadding: 12,
      leading: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: accent.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(Icons.alarm_rounded, color: accent, size: 18),
      ),
      title: Text(title),
      subtitle: Text(
        TimeFormatter.formatTimeOfDay(
          time,
          use24h: use24h,
          locale: context.locale.toString(),
        ),
        style: theme.textTheme.bodySmall?.copyWith(
          color: accent,
          fontWeight: FontWeight.w700,
        ),
      ),
      trailing: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: colors.pillBg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: colors.softBorder),
        ),
        child: Icon(Icons.chevron_right_rounded, size: 16,
            color: colors.mutedText),
      ),
      onTap: onTap,
    );
  }
}

// ─── Footer ───────────────────────────────────────────────────────────────────

class _SettingsFooter extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colors = AppThemeColors.of(context);

    return Column(
      children: [
        Divider(color: colors.softBorder),
        const SizedBox(height: 12),
        Text(
          'settings.footer.app_name'.tr(),
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colors.mutedText,
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          'settings.footer.version'.tr(namedArgs: {'version': '1.0.0'}),
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colors.mutedText.withValues(alpha: 0.6),
              ),
        ),
        const SizedBox(height: 20),
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
