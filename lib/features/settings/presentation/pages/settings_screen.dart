import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/storage/local_storage_service.dart';
import '../cubit/notification_settings_cubit.dart';
import '../cubit/notification_settings_state.dart';
import '../cubit/theme_cubit.dart';

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
        appBar: AppBar(title: Text('common.settings'.tr())),
        body:
            BlocConsumer<NotificationSettingsCubit, NotificationSettingsState>(
              listener: (context, state) {
                if (state.saveStatus == NotificationSaveStatus.saved) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('settings.saved'.tr())),
                  );
                }
              },
              builder: (context, state) {
                final isDarkMode =
                    context.watch<ThemeCubit>().state == ThemeMode.dark;
                final currentLanguage = context.locale.languageCode;

                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'settings.language.title'.tr(),
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 8),
                            DropdownButtonFormField<String>(
                              initialValue:
                                  _languageCodes.contains(currentLanguage)
                                  ? currentLanguage
                                  : 'en',
                              decoration: InputDecoration(
                                labelText: 'settings.language.label'.tr(),
                                border: const OutlineInputBorder(),
                              ),
                              items: _languageCodes
                                  .map(
                                    (code) => DropdownMenuItem(
                                      value: code,
                                      child: Text(
                                        'settings.language.$code'.tr(),
                                      ),
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
                      ),
                    ),
                    const SizedBox(height: 12),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'settings.appearance'.tr(),
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 8),
                            SwitchListTile.adaptive(
                              contentPadding: EdgeInsets.zero,
                              title: Text('settings.dark_mode'.tr()),
                              value: isDarkMode,
                              onChanged: (value) {
                                context.read<ThemeCubit>().setMode(
                                  value ? ThemeMode.dark : ThemeMode.light,
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'settings.reminders'.tr(),
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 8),
                            SwitchListTile.adaptive(
                              contentPadding: EdgeInsets.zero,
                              title: Text('settings.enable_notifications'.tr()),
                              value: state.enabled,
                              onChanged: (value) {
                                context
                                    .read<NotificationSettingsCubit>()
                                    .setEnabled(value);
                              },
                            ),
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text('settings.morning_reminder'.tr()),
                              subtitle: Text(state.morning.format(context)),
                              trailing: const Icon(Icons.schedule),
                              onTap: () => _pickTime(
                                context,
                                initial: state.morning,
                                onSelected: (value) {
                                  context
                                      .read<NotificationSettingsCubit>()
                                      .setMorning(value);
                                },
                              ),
                            ),
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text('settings.evening_reminder'.tr()),
                              subtitle: Text(state.evening.format(context)),
                              trailing: const Icon(Icons.schedule),
                              onTap: () => _pickTime(
                                context,
                                initial: state.evening,
                                onSelected: (value) {
                                  context
                                      .read<NotificationSettingsCubit>()
                                      .setEvening(value);
                                },
                              ),
                            ),
                            const SizedBox(height: 8),
                            FilledButton.icon(
                              onPressed:
                                  state.saveStatus ==
                                      NotificationSaveStatus.saving
                                  ? null
                                  : () => context
                                        .read<NotificationSettingsCubit>()
                                        .save(),
                              icon:
                                  state.saveStatus ==
                                      NotificationSaveStatus.saving
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.save_outlined),
                              label: Text('settings.save_notifications'.tr()),
                              style: FilledButton.styleFrom(
                                minimumSize: const Size.fromHeight(48),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
      ),
    );
  }
}
