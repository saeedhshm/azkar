import 'dart:math';
import 'dart:ui';

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
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          title: Text('common.settings'.tr()),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: Stack(
          children: [
            _SettingsBackground(
              isDark: Theme.of(context).brightness == Brightness.dark,
            ),
            SafeArea(
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
                      final isDarkMode =
                          context.watch<ThemeCubit>().state == ThemeMode.dark;
                      final currentLanguage = context.locale.languageCode;

                      return ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          _MetallicCard(
                            isDark: isDarkMode,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'settings.language.title'.tr(),
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                                const SizedBox(height: 8),
                                _MetallicDropdownButton<String>(
                                  initialValue:
                                      _languageCodes.contains(currentLanguage)
                                      ? currentLanguage
                                      : 'en',
                                  labelText: 'settings.language.label'.tr(),
                                  isDark: isDarkMode,
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
                          const SizedBox(height: 12),
                          _MetallicCard(
                            isDark: isDarkMode,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'settings.appearance'.tr(),
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                                const SizedBox(height: 8),
                                _MetallicSwitchTile(
                                  isDark: isDarkMode,
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
                          const SizedBox(height: 12),
                          _MetallicCard(
                            isDark: isDarkMode,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'settings.reminders'.tr(),
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                                const SizedBox(height: 8),
                                _MetallicSwitchTile(
                                  isDark: isDarkMode,
                                  title: Text(
                                    'settings.enable_notifications'.tr(),
                                  ),
                                  value: state.enabled,
                                  onChanged: (value) {
                                    context
                                        .read<NotificationSettingsCubit>()
                                        .setEnabled(value);
                                  },
                                ),
                                _MetallicListTile(
                                  isDark: isDarkMode,
                                  title: Text('settings.morning_reminder'.tr()),
                                  subtitle: Text(state.morning.format(context)),
                                  trailing: Icon(
                                    Icons.schedule,
                                    color: isDarkMode
                                        ? const Color(0xFF6EE7E8)
                                        : const Color(0xFFC58B55),
                                  ),
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
                                _MetallicListTile(
                                  isDark: isDarkMode,
                                  title: Text('settings.evening_reminder'.tr()),
                                  subtitle: Text(state.evening.format(context)),
                                  trailing: Icon(
                                    Icons.schedule,
                                    color: isDarkMode
                                        ? const Color(0xFF6EE7E8)
                                        : const Color(0xFFC58B55),
                                  ),
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
                                _MetallicListTile(
                                  isDark: isDarkMode,
                                  title: Text('settings.sleep_reminder'.tr()),
                                  subtitle: Text(state.sleep.format(context)),
                                  trailing: Icon(
                                    Icons.schedule,
                                    color: isDarkMode
                                        ? const Color(0xFF6EE7E8)
                                        : const Color(0xFFC58B55),
                                  ),
                                  onTap: () => _pickTime(
                                    context,
                                    initial: state.sleep,
                                    onSelected: (value) {
                                      context
                                          .read<NotificationSettingsCubit>()
                                          .setSleep(value);
                                    },
                                  ),
                                ),
                                _MetallicListTile(
                                  isDark: isDarkMode,
                                  title: Text('settings.waking_reminder'.tr()),
                                  subtitle: Text(state.waking.format(context)),
                                  trailing: Icon(
                                    Icons.schedule,
                                    color: isDarkMode
                                        ? const Color(0xFF6EE7E8)
                                        : const Color(0xFFC58B55),
                                  ),
                                  onTap: () => _pickTime(
                                    context,
                                    initial: state.waking,
                                    onSelected: (value) {
                                      context
                                          .read<NotificationSettingsCubit>()
                                          .setWaking(value);
                                    },
                                  ),
                                ),
                                _MetallicListTile(
                                  isDark: isDarkMode,
                                  title: Text('settings.friday_reminder'.tr()),
                                  subtitle: Text(state.friday.format(context)),
                                  trailing: Icon(
                                    Icons.schedule,
                                    color: isDarkMode
                                        ? const Color(0xFF6EE7E8)
                                        : const Color(0xFFC58B55),
                                  ),
                                  onTap: () => _pickTime(
                                    context,
                                    initial: state.friday,
                                    onSelected: (value) {
                                      context
                                          .read<NotificationSettingsCubit>()
                                          .setFriday(value);
                                    },
                                  ),
                                ),
                                const SizedBox(height: 8),
                                _MetallicButton(
                                  isDark: isDarkMode,
                                  isLoading:
                                      state.saveStatus ==
                                      NotificationSaveStatus.saving,
                                  onPressed:
                                      state.saveStatus ==
                                          NotificationSaveStatus.saving
                                      ? null
                                      : () => context
                                            .read<NotificationSettingsCubit>()
                                            .save(),
                                  child: Text(
                                    'settings.save_notifications'.tr(),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsBackground extends StatelessWidget {
  const _SettingsBackground({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final gradient = isDark
        ? const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0A1220), Color(0xFF0F1C2E), Color(0xFF071A1B)],
          )
        : const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF3E7D2), Color(0xFFECD9BF), Color(0xFFE3C9A6)],
          );

    return DecoratedBox(
      decoration: BoxDecoration(gradient: gradient),
      child: CustomPaint(
        painter: _SoftDustPainter(isDark: isDark),
        child: Container(),
      ),
    );
  }
}

class _SoftDustPainter extends CustomPainter {
  _SoftDustPainter({required this.isDark});

  final bool isDark;

  @override
  void paint(Canvas canvas, Size size) {
    final random = Random(5);
    final count = isDark ? 80 : 55;
    final baseOpacity = isDark ? 0.4 : 0.2;

    for (var i = 0; i < count; i++) {
      final dx = random.nextDouble() * size.width;
      final dy = random.nextDouble() * size.height;
      final radius = random.nextDouble() * 1.2 + 0.2;
      final opacity = baseOpacity + random.nextDouble() * 0.4;
      final paint = Paint()
        ..color = (isDark ? Colors.white : const Color(0xFFB48A45)).withValues(
          alpha: opacity,
        );
      canvas.drawCircle(Offset(dx, dy), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _MetallicCard extends StatelessWidget {
  const _MetallicCard({required this.child, required this.isDark});

  final Widget child;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final glowColor = isDark
        ? const Color(0xFF6EE7E8)
        : const Color(0xFFC58B55);
    final cardColor = isDark
        ? Colors.white.withValues(alpha: 0.06)
        : Colors.white.withValues(alpha: 0.7);
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.16)
        : glowColor.withValues(alpha: 0.35);

    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: borderColor, width: 1),
            boxShadow: [
              BoxShadow(
                color: glowColor.withValues(alpha: isDark ? 0.2 : 0.15),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Padding(padding: const EdgeInsets.all(16), child: child),
        ),
      ),
    );
  }
}

class _MetallicButton extends StatelessWidget {
  const _MetallicButton({
    required this.child,
    required this.isDark,
    this.isLoading = false,
    this.onPressed,
  });

  final Widget child;
  final bool isDark;
  final bool isLoading;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final glowColor = isDark
        ? const Color(0xFF6EE7E8)
        : const Color(0xFFD4A574);
    final metallicStart = isDark
        ? const Color(0xFF2C3640)
        : const Color(0xFFF5E6D3);
    final metallicMid = isDark
        ? const Color(0xFF1E2A34)
        : const Color(0xFFE8D4B8);
    final metallicEnd = isDark
        ? const Color(0xFF141E27)
        : const Color(0xFFD4B896);

    return SizedBox(
      height: 48,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (onPressed != null)
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: glowColor.withValues(alpha: 0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                  BoxShadow(
                    color: glowColor.withValues(alpha: 0.18),
                    blurRadius: 30,
                  ),
                ],
              ),
            ),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: onPressed != null
                    ? glowColor.withValues(alpha: 0.7)
                    : Colors.grey.withValues(alpha: 0.6),
                width: 2,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: onPressed != null
                            ? [metallicStart, metallicMid, metallicEnd]
                            : [
                                Colors.grey.shade400.withValues(alpha: 0.8),
                                Colors.grey.shade500.withValues(alpha: 0.85),
                                Colors.grey.shade600.withValues(alpha: 0.8),
                              ],
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.topLeft,
                    child: Container(
                      width: double.infinity,
                      height: 15,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.white.withValues(
                              alpha: onPressed != null
                                  ? (isDark ? 0.3 : 0.5)
                                  : 0.15,
                            ),
                            Colors.transparent,
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                  ),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(30),
                      onTap: onPressed,
                      child: Center(
                        child: isLoading
                            ? SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    glowColor,
                                  ),
                                ),
                              )
                            : DefaultTextStyle(
                                style: TextStyle(
                                  color: onPressed != null
                                      ? glowColor
                                      : Colors.grey.shade400,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                                child: child,
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetallicDropdownButton<T> extends StatelessWidget {
  const _MetallicDropdownButton({
    required this.initialValue,
    required this.labelText,
    required this.isDark,
    required this.items,
    required this.onChanged,
  });

  final T? initialValue;
  final String labelText;
  final bool isDark;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?>? onChanged;

  @override
  Widget build(BuildContext context) {
    final glowColor = isDark
        ? const Color(0xFF6EE7E8)
        : const Color(0xFFD4A574);
    final metallicStart = isDark
        ? const Color(0xFF2C3640)
        : const Color(0xFFF5E6D3);
    final metallicMid = isDark
        ? const Color(0xFF1E2A34)
        : const Color(0xFFE8D4B8);
    final metallicEnd = isDark
        ? const Color(0xFF141E27)
        : const Color(0xFFD4B896);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: glowColor.withValues(alpha: 0.5), width: 1),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [metallicStart, metallicMid, metallicEnd],
        ),
      ),
      child: DropdownButtonFormField<T>(
        initialValue: initialValue,
        decoration: InputDecoration(
          labelText: labelText,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
          labelStyle: TextStyle(color: glowColor.withValues(alpha: 0.8)),
        ),
        style: TextStyle(
          color: isDark ? Colors.white : const Color(0xFF1D2530),
        ),
        dropdownColor: isDark
            ? const Color(0xFF2D3748)
            : const Color(0xFFF5E6D3),
        items: items,
        onChanged: onChanged,
      ),
    );
  }
}

class _MetallicSwitchTile extends StatelessWidget {
  const _MetallicSwitchTile({
    required this.isDark,
    required this.title,
    required this.value,
    required this.onChanged,
  });

  final bool isDark;
  final Widget title;
  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final glowColor = isDark
        ? const Color(0xFF6EE7E8)
        : const Color(0xFFC58B55);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            (isDark ? const Color(0xFF2C3640) : const Color(0xFFF0D2A0))
                .withValues(alpha: 0.3),
            (isDark ? const Color(0xFF1E2A34) : const Color(0xFFD7A769))
                .withValues(alpha: 0.3),
          ],
        ),
      ),
      child: SwitchListTile.adaptive(
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        title: title,
        value: value,
        activeThumbColor: glowColor,
        activeTrackColor: glowColor.withValues(alpha: 0.35),
        onChanged: onChanged,
      ),
    );
  }
}

class _MetallicListTile extends StatelessWidget {
  const _MetallicListTile({
    required this.isDark,
    required this.title,
    required this.subtitle,
    required this.trailing,
    required this.onTap,
  });

  final bool isDark;
  final Widget title;
  final Widget subtitle;
  final Widget trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            (isDark ? const Color(0xFF2C3640) : const Color(0xFFF0D2A0))
                .withValues(alpha: 0.3),
            (isDark ? const Color(0xFF1E2A34) : const Color(0xFFD7A769))
                .withValues(alpha: 0.3),
          ],
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        title: title,
        subtitle: subtitle,
        trailing: trailing,
        onTap: onTap,
      ),
    );
  }
}
