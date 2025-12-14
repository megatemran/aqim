package net.brings2you.aqim

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.util.Log
import java.time.ZonedDateTime
import java.util.concurrent.TimeUnit

class AlarmTester(
    private val context: Context,
) {
    companion object {
        private const val TAG = "AlarmTester"

        fun testAllAlarms(context: Context) {
            Log.d(TAG, "═══════════════════════════════════════════════════")
            Log.d(TAG, "🔧 TESTING ALL ALARMS")
            Log.d(TAG, "═══════════════════════════════════════════════════")

            val tester = AlarmTester(context)

            // Test 1: AppScheduler alarms
            tester.testAppSchedulerAlarms()

            // Test 2: AppReceiver alarms
            tester.testAppReceiverAlarms()

            // Test 3: Immediate test alarm
            tester.testImmediateAlarm()

            Log.d(TAG, "═══════════════════════════════════════════════════")
            Log.d(TAG, "✅ ALL TESTS SCHEDULED")
            Log.d(TAG, "═══════════════════════════════════════════════════")
        }
    }

    private fun testImmediateAlarm() {
        try {
            Log.d(TAG, "⏰ Testing IMMEDIATE alarm (10 seconds from now)...")

            val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
            val triggerTime = System.currentTimeMillis() + TimeUnit.SECONDS.toMillis(10)

            val intent =
                Intent(context, AppReceiver::class.java).apply {
                    action = AppReceiver.ACTION_APP_ALARM
                    putExtra("alarm_name", "TEST_ALARM")
                    putExtra("alarm_time", "12:00")
                    putExtra("test_mode", true)
                }

            val pendingIntent =
                PendingIntent.getBroadcast(
                    context,
                    99999,
                    intent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
                )

            // Cancel any existing test alarm
            alarmManager.cancel(pendingIntent)

            // Schedule test alarm
            if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.M) {
                alarmManager.setExactAndAllowWhileIdle(
                    AlarmManager.RTC_WAKEUP,
                    triggerTime,
                    pendingIntent,
                )
            } else {
                alarmManager.setExact(
                    AlarmManager.RTC_WAKEUP,
                    triggerTime,
                    pendingIntent,
                )
            }

            val triggerTimeFormatted =
                ZonedDateTime
                    .now()
                    .plusSeconds(10)
                    .toLocalTime()
                    .toString()

            Log.d(TAG, "✅ Test alarm scheduled for: $triggerTimeFormatted")
            Log.d(TAG, "   Will trigger ACTION_APP_ALARM in 10 seconds")
        } catch (e: Exception) {
            Log.e(TAG, "❌ Failed to schedule test alarm", e)
        }
    }

    private fun testAppSchedulerAlarms() {
        Log.d(TAG, "🕌 Testing AppScheduler alarms...")

        // Force reschedule
        val appScheduler = AppScheduler(context)

        // Check current scheduled prayers
        val prefs = context.getSharedPreferences("HomeWidgetPreferences", Context.MODE_PRIVATE)
        val subuh = prefs.getString("subuh", "") ?: ""
        val zohor = prefs.getString("zohor", "") ?: ""
        val asar = prefs.getString("asar", "") ?: ""
        val maghrib = prefs.getString("maghrib", "") ?: ""
        val isyak = prefs.getString("isyak", "") ?: ""

        Log.d(TAG, "📋 Current prayer times:")
        Log.d(TAG, "   Subuh: $subuh")
        Log.d(TAG, "   Zohor: $zohor")
        Log.d(TAG, "   Asar: $asar")
        Log.d(TAG, "   Maghrib: $maghrib")
        Log.d(TAG, "   Isyak: $isyak")

        // Reschedule
        appScheduler.scheduleNextPrayerTime()

        Log.d(TAG, "✅ AppScheduler test completed")
    }

    private fun testAppReceiverAlarms() {
        Log.d(TAG, "🔔 Testing AppReceiver alarms...")

        // Schedule a test alarm via AppReceiver
        AppReceiver.scheduleAppAlarm(
            context,
            "TEST_SOLAT",
            "12:00",
            0,
        )

        // Also schedule a before-reminder
        AppReceiver.scheduleAppAlarm(
            context,
            "TEST_SOLAT",
            "12:00",
            -5, // 5 minutes before
        )

        Log.d(TAG, "✅ AppReceiver test alarms scheduled")
    }
}
