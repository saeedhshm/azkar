package com.example.azkar

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.app.PendingIntent
import android.os.Build
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider

/**
 * Android Home Widget provider for displaying prayer times.
 *
 * This widget displays:
 * - Next prayer name (localized)
 * - Countdown timer to next prayer
 * - Prayer time
 * - Hijri and Gregorian dates
 * - Location label
 *
 * Data is provided by Flutter via HomeWidget.saveWidgetData().
 * Updates are triggered by:
 * 1. Flutter code calling HomeWidget.updateWidget()
 * 2. WidgetUpdateReceiver (every 60 seconds)
 * 3. System widget refresh events
 *
 * The countdown is calculated dynamically from the stored epoch time
 * to prevent negative values and ensure accuracy.
 */
class PrayerWidgetProvider : HomeWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: android.content.SharedPreferences
    ) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.prayer_widget)

            // Read widget data from SharedPreferences (set by Flutter)
            val hijri = widgetData.getString("widget_hijri", "") ?: ""
            val dateLine = widgetData.getString("widget_date", "") ?: ""
            val location = widgetData.getString("widget_location", "") ?: ""
            val prayer = widgetData.getString("widget_next_prayer", "--") ?: "--"
            val time = widgetData.getString("widget_next_time", "--") ?: "--"
            val nextLabel = widgetData.getString("widget_next_label", "Next prayer") ?: "Next prayer"
            val nextEpochText = widgetData.getString("widget_next_epoch", "") ?: ""
            val nextEpoch = nextEpochText.toLongOrNull() ?: 0L

            // Set text views
            views.setTextViewText(R.id.widget_hijri, hijri)
            views.setTextViewText(R.id.widget_date, dateLine)
            views.setTextViewText(R.id.widget_location, location)
            views.setTextViewText(R.id.widget_next_prayer, prayer)
            views.setTextViewText(R.id.widget_next_time, time)
            views.setTextViewText(R.id.widget_next_label, nextLabel)

            // Handle countdown display
            // Calculate remaining time dynamically to prevent negative values
            if (nextEpoch > 0L) {
                val now = System.currentTimeMillis()
                val remainingMs = nextEpoch - now

                if (remainingMs > 0) {
                    // Prayer hasn't arrived yet - show countdown
                    val totalSeconds = remainingMs / 1000
                    val hours = totalSeconds / 3600
                    val minutes = (totalSeconds % 3600) / 60
                    val seconds = totalSeconds % 60

                    val countdownText = String.format("%02d:%02d:%02d", hours, minutes, seconds)
                    views.setTextViewText(R.id.widget_countdown, countdownText)
                } else {
                    // Prayer time has passed - show zero or "Now"
                    // The next widget update cycle will recalculate to the next prayer
                    views.setTextViewText(R.id.widget_countdown, "00:00:00")
                }
            } else {
                // No epoch data available
                views.setTextViewText(R.id.widget_countdown, "--:--:--")
            }

            // Set click listener to open the app
            val launchIntent = context.packageManager.getLaunchIntentForPackage(
                context.packageName
            ) ?: Intent(context, MainActivity::class.java)

            val flags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            } else {
                PendingIntent.FLAG_UPDATE_CURRENT
            }

            val pendingIntent = PendingIntent.getActivity(
                context,
                widgetId,
                launchIntent,
                flags
            )
            views.setOnClickPendingIntent(R.id.widget_root, pendingIntent)

            // Update the widget
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
