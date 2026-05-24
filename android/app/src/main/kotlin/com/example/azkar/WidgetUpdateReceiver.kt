package com.example.azkar

import android.app.AlarmManager
import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.BroadcastReceiver
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.os.Build

/**
 * BroadcastReceiver that triggers widget updates every minute.
 *
 * This receiver is triggered by AlarmManager at fixed intervals.
 * It refreshes the widget by sending a broadcast to PrayerWidgetProvider,
 * which causes onUpdate() to be called with the latest SharedPreferences data.
 *
 * Battery optimization:
 * - Uses setInexactRepeating() on older Android versions
 * - Uses setExactAndAllowWhileIdle() on Android 6+ for reliability
 * - Respects Doze mode by using allowWhileIdle variants
 */
class WidgetUpdateReceiver : BroadcastReceiver() {

    companion object {
        private const val ACTION_UPDATE_WIDGET = "com.example.azkar.UPDATE_WIDGET"
        private const val REQUEST_CODE = 1001
        private const val UPDATE_INTERVAL_MS = 60_000L // 1 minute

        /**
         * Schedules periodic widget updates using AlarmManager.
         *
         * This method:
         * - Cancels any existing alarm first (prevents duplicates)
         * - Sets up a repeating alarm that triggers every 60 seconds
         * - Uses exact alarms when available for reliability
         * - Survives app restarts (but not reboots - see BootReceiver)
         */
        fun scheduleUpdates(context: Context) {
            val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
            val intent = Intent(context, WidgetUpdateReceiver::class.java).apply {
                action = ACTION_UPDATE_WIDGET
            }

            val pendingIntent = PendingIntent.getBroadcast(
                context,
                REQUEST_CODE,
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )

            // Cancel existing alarms to prevent duplicates
            alarmManager.cancel(pendingIntent)

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                // Android 6+: Use exact alarm with idle permission
                // This ensures updates happen even in Doze mode
                val triggerAt = System.currentTimeMillis() + UPDATE_INTERVAL_MS
                alarmManager.setExactAndAllowWhileIdle(
                    AlarmManager.RTC_WAKEUP,
                    triggerAt,
                    pendingIntent
                )
            } else {
                // Older Android: Use inexact repeating for battery efficiency
                alarmManager.setInexactRepeating(
                    AlarmManager.RTC_WAKEUP,
                    System.currentTimeMillis() + UPDATE_INTERVAL_MS,
                    UPDATE_INTERVAL_MS,
                    pendingIntent
                )
            }
        }

        /**
         * Cancels all scheduled widget updates.
         * Call this when the user disables widgets or uninstalls the app.
         */
        fun cancelUpdates(context: Context) {
            val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
            val intent = Intent(context, WidgetUpdateReceiver::class.java).apply {
                action = ACTION_UPDATE_WIDGET
            }

            val pendingIntent = PendingIntent.getBroadcast(
                context,
                REQUEST_CODE,
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )

            alarmManager.cancel(pendingIntent)
        }
    }

    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == ACTION_UPDATE_WIDGET) {
            // Trigger widget update by broadcasting to PrayerWidgetProvider
            // This causes PrayerWidgetProvider.onUpdate() to be called
            // with the latest SharedPreferences data set by Flutter
            val appWidgetManager = AppWidgetManager.getInstance(context)
            val componentName = ComponentName(context, PrayerWidgetProvider::class.java)
            val appWidgetIds = appWidgetManager.getAppWidgetIds(componentName)

            if (appWidgetIds.isNotEmpty()) {
                val updateIntent = Intent(context, PrayerWidgetProvider::class.java).apply {
                    action = AppWidgetManager.ACTION_APPWIDGET_UPDATE
                    putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, appWidgetIds)
                }
                context.sendBroadcast(updateIntent)
            }

            // Reschedule the next alarm (for exact alarm mode on Android 6+)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                scheduleUpdates(context)
            }
        }
    }
}
