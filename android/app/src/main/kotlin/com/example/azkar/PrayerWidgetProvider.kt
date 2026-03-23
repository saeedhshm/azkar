package com.example.azkar

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.app.PendingIntent
import android.os.Build
import android.os.SystemClock
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider

class PrayerWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: android.content.SharedPreferences
    ) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.prayer_widget)

            val hijri = widgetData.getString("widget_hijri", "") ?: ""
            val dateLine = widgetData.getString("widget_date", "") ?: ""
            val location = widgetData.getString("widget_location", "") ?: ""
            val prayer = widgetData.getString("widget_next_prayer", "--") ?: "--"
            val time = widgetData.getString("widget_next_time", "--") ?: "--"
            val nextLabel = widgetData.getString("widget_next_label", "Next prayer") ?: "Next prayer"
            val nextEpochText = widgetData.getString("widget_next_epoch", "") ?: ""
            val nextEpoch = nextEpochText.toLongOrNull() ?: 0L

            views.setTextViewText(R.id.widget_hijri, hijri)
            views.setTextViewText(R.id.widget_date, dateLine)
            views.setTextViewText(R.id.widget_location, location)
            views.setTextViewText(R.id.widget_next_prayer, prayer)
            views.setTextViewText(R.id.widget_next_time, time)
            views.setTextViewText(R.id.widget_next_label, nextLabel)

            if (nextEpoch > 0L) {
                val now = System.currentTimeMillis()
                val base = SystemClock.elapsedRealtime() + (nextEpoch - now)
                views.setChronometer(R.id.widget_countdown, base, null, true)
                views.setBoolean(R.id.widget_countdown, "setCountDown", true)
            }

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

            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
