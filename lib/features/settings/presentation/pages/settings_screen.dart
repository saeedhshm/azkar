import 'package:adhan/adhan.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/storage/local_storage_service.dart';
import '../../../../core/theme/app_theme.dart';
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

    if (result != null) {
      onSelected(result);
    }
  }

  Future<void> _changeLanguage(
    BuildContext context,
    String languageCode,
  ) async {
    await context.setLocale(Locale(languageCode));
    await getIt<LocalStorageService>().saveLocaleCode(languageCode);
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<NotificationSettingsCubit>(
      create: (_) => getIt<NotificationSettingsCubit>()..load(),
      child: Scaffold(
        appBar: AppBar(
          toolbarHeight: 68,
          title: Text(
            'common.settings'.tr(),
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
        ),
        body: SafeArea(
          top: false,
          child:
              BlocConsumer<
                NotificationSettingsCubit,
                NotificationSettingsState
              >(
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
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                    children: [
                      const _PrayerCalculationSection(),
                      const SizedBox(height: 14),
                      _SettingsSection(
                        title: 'settings.appearance'.tr(),
                        children: [
                          _ThemeModeTile(
                            value: themeMode,
                            onChanged: context.read<ThemeCubit>().setMode,
                          ),
                          _SettingsSwitchTile(
                            icon: Icons.schedule_rounded,
                            title: 'settings.use_24h'.tr(),
                            subtitle: use24h ? '24h' : 'AM/PM',
                            value: use24h,
                            onChanged: context
                                .read<TimeFormatCubit>()
                                .setUse24h,
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      _SettingsSection(
                        title: 'settings.language.title'.tr(),
                        children: [
                          _SettingsDropdownTile<String>(
                            icon: Icons.language_rounded,
                            title: 'settings.language.label'.tr(),
                            value: _languageCodes.contains(currentLanguage)
                                ? currentLanguage
                                : 'en',
                            items: _languageCodes
                                .map(
                                  (code) => DropdownMenuItem<String>(
                                    value: code,
                                    child: Text('settings.language.$code'.tr()),
                                  ),
                                )
                                .toList(growable: false),
                            onChanged: (value) {
                              if (value != null) {
                                _changeLanguage(context, value);
                              }
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      _SettingsSection(
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
                          _TimeTile(
                            title: 'settings.morning_reminder'.tr(),
                            time: state.morning,
                            use24h: use24h,
                            onTap: () => _pickTime(
                              context,
                              initial: state.morning,
                              onSelected: context
                                  .read<NotificationSettingsCubit>()
                                  .setMorning,
                            ),
                          ),
                          _TimeTile(
                            title: 'settings.evening_reminder'.tr(),
                            time: state.evening,
                            use24h: use24h,
                            onTap: () => _pickTime(
                              context,
                              initial: state.evening,
                              onSelected: context
                                  .read<NotificationSettingsCubit>()
                                  .setEvening,
                            ),
                          ),
                          _TimeTile(
                            title: 'settings.sleep_reminder'.tr(),
                            time: state.sleep,
                            use24h: use24h,
                            onTap: () => _pickTime(
                              context,
                              initial: state.sleep,
                              onSelected: context
                                  .read<NotificationSettingsCubit>()
                                  .setSleep,
                            ),
                          ),
                          _TimeTile(
                            title: 'settings.waking_reminder'.tr(),
                            time: state.waking,
                            use24h: use24h,
                            onTap: () => _pickTime(
                              context,
                              initial: state.waking,
                              onSelected: context
                                  .read<NotificationSettingsCubit>()
                                  .setWaking,
                            ),
                          ),
                          _TimeTile(
                            title: 'settings.friday_reminder'.tr(),
                            time: state.friday,
                            use24h: use24h,
                            onTap: () => _pickTime(
                              context,
                              initial: state.friday,
                              onSelected: context
                                  .read<NotificationSettingsCubit>()
                                  .setFriday,
                            ),
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton(
                              onPressed:
                                  state.saveStatus ==
                                      NotificationSaveStatus.saving
                                  ? null
                                  : context
                                        .read<NotificationSettingsCubit>()
                                        .save,
                              child:
                                  state.saveStatus ==
                                      NotificationSaveStatus.saving
                                  ? const SizedBox.square(
                                      dimension: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Text('settings.save_notifications'.tr()),
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
        ),
      ),
    );
  }
}

class _PrayerCalculationSection extends StatefulWidget {
  const _PrayerCalculationSection();

  @override
  State<_PrayerCalculationSection> createState() =>
      _PrayerCalculationSectionState();
}

class _PrayerCalculationSectionState extends State<_PrayerCalculationSection> {
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
      title: 'settings.prayer_calculation'.tr(),
      children: [
        _SettingsDropdownTile<CalculationMethod>(
          icon: Icons.tune_rounded,
          title: 'prayer_times.method'.tr(),
          value: _settings.method,
          items: _methodOptions
              .map(
                (method) => DropdownMenuItem<CalculationMethod>(
                  value: method,
                  child: Text(_methodLabel(method)),
                ),
              )
              .toList(growable: false),
          onChanged: (value) {
            if (value != null) {
              _save(_settings.copyWith(method: value));
            }
          },
        ),
        _SettingsDropdownTile<Madhab>(
          icon: Icons.mosque_outlined,
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
          onChanged: (value) {
            if (value != null) {
              _save(_settings.copyWith(madhab: value));
            }
          },
        ),
      ],
    );
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
}

class _ThemeModeTile extends StatelessWidget {
  const _ThemeModeTile({required this.value, required this.onChanged});

  final ThemeMode value;
  final ValueChanged<ThemeMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return _SettingsDropdownTile<ThemeMode>(
      icon: Icons.contrast_rounded,
      title: 'settings.theme_mode'.tr(),
      value: value,
      items: [
        DropdownMenuItem(
          value: ThemeMode.system,
          child: Text('settings.theme_system'.tr()),
        ),
        DropdownMenuItem(
          value: ThemeMode.light,
          child: Text('settings.theme_light'.tr()),
        ),
        DropdownMenuItem(
          value: ThemeMode.dark,
          child: Text('settings.theme_dark'.tr()),
        ),
      ],
      onChanged: (value) {
        if (value != null) {
          onChanged(value);
        }
      },
    );
  }
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final colors = AppThemeColors.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 12),
            DecoratedBox(
              decoration: BoxDecoration(
                color: colors.cardSurfaceTint.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: colors.softBorder),
              ),
              child: Column(children: children),
            ),
          ],
        ),
      ),
    );
  }
}

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
      minVerticalPadding: 10,
      leading: Icon(icon, color: colors.prayerIcon),
      title: Text(title),
      trailing: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          items: items,
          onChanged: onChanged,
          borderRadius: BorderRadius.circular(18),
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
      secondary: Icon(icon, color: colors.prayerIcon),
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

    return ListTile(
      minVerticalPadding: 10,
      leading: Icon(Icons.alarm_rounded, color: colors.prayerIcon),
      title: Text(title),
      subtitle: Text(
        TimeFormatter.formatTimeOfDay(
          time,
          use24h: use24h,
          locale: context.locale.toString(),
        ),
      ),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: onTap,
    );
  }
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
