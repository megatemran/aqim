package net.brings2you.aqim

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log

class BootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent?) {
        when (intent?.action) {
            Intent.ACTION_BOOT_COMPLETED -> {
                Log.d("BootReceiver", "📱 Device booted - rescheduling everything...")
                rescheduleAll(context)
            }
            "android.intent.action.TIME_SET",
            Intent.ACTION_TIME_CHANGED -> {
                Log.d("BootReceiver", "🕐 Time changed (${intent.action}) - rescheduling prayer alarms...")
                rescheduleAll(context)
            }
            Intent.ACTION_TIMEZONE_CHANGED -> {
                Log.d("BootReceiver", "🌍 Timezone changed - rescheduling prayer alarms...")
                rescheduleAll(context)
            }
            Intent.ACTION_MY_PACKAGE_REPLACED -> {
                Log.d("BootReceiver", "📦 App updated - rescheduling prayer alarms...")
                rescheduleAll(context)
            }
            Intent.ACTION_LOCALE_CHANGED -> {
                Log.d("BootReceiver", "🌐 Locale changed - rescheduling prayer alarms...")
                rescheduleAll(context)
            }
            Intent.ACTION_DATE_CHANGED -> {
                Log.d("BootReceiver", "📅 Date changed - rescheduling prayer alarms...")
                rescheduleAll(context)
            }
        }
    }

    private fun rescheduleAll(context: Context) {
        // ✅ Update widget immediately with current prayer times
        Log.d("BootReceiver", "🔄 Updating Waktu Solat widget immediately...")
        WaktuSolatWidgetUpdater.updateImmediately(context)

        // Reschedule all prayer time widget updates
        WaktuSolatWidgetUpdater.initializeScheduling(context)

        // Reschedule Doa widget
        DoaWidgetUpdater.schedule(context)

        // ✅ CRITICAL: Reschedule prayer alarms
        Log.d("BootReceiver", "🔔 Rescheduling prayer alarms...")
        PrayerAlarmReceiver.scheduleAllPrayerAlarms(context)
    }
}