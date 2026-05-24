package com.example.azkar

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

/**
 * BroadcastReceiver that reschedules widget updates after device reboot.
 *
 * Android clears all AlarmManager alarms when the device reboots.
 * This receiver listens for BOOT_COMPLETED and re-registers the
 * WidgetUpdateReceiver alarm so widget updates continue automatically.
 *
 * Required permissions in AndroidManifest.xml:
 * - android.permission.RECEIVE_BOOT_COMPLETED
 *
 * This receiver is registered in AndroidManifest.xml with the
 * BOOT_COMPLETED intent filter.
 */
class BootReceiver : BroadcastReceiver() {

    override fun onReceive(context: Context, intent: Intent) {
        when (intent.action) {
            Intent.ACTION_BOOT_COMPLETED,
            Intent.ACTION_MY_PACKAGE_REPLACED,
            "android.intent.action.QUICKBOOT_POWERON",
            "com.htc.intent.action.QUICKBOOT_POWERON" -> {
                // Reschedule widget updates after reboot or app update
                WidgetUpdateReceiver.scheduleUpdates(context)
            }
        }
    }
}
