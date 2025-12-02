package net.brings2you.aqim

import android.app.AlarmManager
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.PowerManager
import android.util.Log
import androidx.core.app.NotificationCompat
import java.time.LocalTime
import java.time.ZonedDateTime

class PrayerAlarmReceiver : BroadcastReceiver() {
    
    companion object {
        private const val TAG = "PrayerAlarmReceiver"
        private const val CHANNEL_NAME = "net.brings2you.aqim/prayer_alarm"
        private const val ACTION_PRAYER_ALARM = "net.brings2you.aqim.PRAYER_ALARM"
        private const val ACTION_DAILY_RESCHEDULE = "net.brings2you.aqim.DAILY_RESCHEDULE"

        // Request codes for each prayer
        private const val REQUEST_CODE_SUBUH = 1001
        private const val REQUEST_CODE_ZOHOR = 1002
        private const val REQUEST_CODE_ASAR = 1003
        private const val REQUEST_CODE_MAGHRIB = 1004
        private const val REQUEST_CODE_ISYAK = 1005
        private const val REQUEST_CODE_DAILY_RESCHEDULE = 1999

        private const val EXTRA_PRAYER_NAME = "prayer_name"
        private const val EXTRA_PRAYER_TIME = "prayer_time"
        
        fun scheduleAllPrayerAlarms(context: Context) {
            Log.d(TAG, "═══════════════════════════════════════════════════")
            Log.d(TAG, "🔔 Scheduling all prayer alarms...")
            Log.d(TAG, "═══════════════════════════════════════════════════")
            
            val prefs = context.getSharedPreferences("HomeWidgetPreferences", Context.MODE_PRIVATE)
            
            val prayers = mapOf(
                "Subuh" to prefs.getString("subuh", ""),
                "Zohor" to prefs.getString("zohor", ""),
                "Asar" to prefs.getString("asar", ""),
                "Maghrib" to prefs.getString("maghrib", ""),
                "Isyak" to prefs.getString("isyak", "")
            )
            
            Log.d(TAG, "📋 Prayer times from SharedPreferences:")
            prayers.forEach { (name, time) ->
                Log.d(TAG, "   $name: $time")
            }
            
            prayers.forEach { (name, time) ->
                if (!time.isNullOrEmpty()) {
                    schedulePrayerAlarm(context, name, time)
                } else {
                    Log.w(TAG, "⚠️ $name time is empty, skipping")
                }
            }
            
            Log.d(TAG, "═══════════════════════════════════════════════════")
            Log.d(TAG, "✅ All prayer alarms scheduled")
            Log.d(TAG, "═══════════════════════════════════════════════════")

            // ✅ Schedule daily safety check to reschedule alarms
            scheduleDailySafetyCheck(context)
        }

        /**
         * Schedule a daily alarm to reschedule all prayer alarms as a safety net
         * This ensures alarms are always active even if something goes wrong
         */
        private fun scheduleDailySafetyCheck(context: Context) {
            try {
                Log.d(TAG, "")
                Log.d(TAG, "🛡️ Scheduling daily safety check...")

                val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
                val now = ZonedDateTime.now()

                // Schedule for 3:00 AM tomorrow (safe time when user is likely asleep)
                var nextCheck = now
                    .withHour(3)
                    .withMinute(0)
                    .withSecond(0)
                    .withNano(0)

                // If 3 AM has already passed today, schedule for tomorrow
                if (nextCheck.isBefore(now)) {
                    nextCheck = nextCheck.plusDays(1)
                }

                val intent = Intent(context, PrayerAlarmReceiver::class.java).apply {
                    action = ACTION_DAILY_RESCHEDULE
                }

                val pendingIntent = PendingIntent.getBroadcast(
                    context,
                    REQUEST_CODE_DAILY_RESCHEDULE,
                    intent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )

                // Cancel any existing daily check
                alarmManager.cancel(pendingIntent)

                val checkTimeMillis = nextCheck.toInstant().toEpochMilli()

                // Use setInexactRepeating for better battery efficiency
                alarmManager.setInexactRepeating(
                    AlarmManager.RTC_WAKEUP,
                    checkTimeMillis,
                    AlarmManager.INTERVAL_DAY, // Repeat every 24 hours
                    pendingIntent
                )

                val hoursUntil = java.time.Duration.between(now, nextCheck).toHours()
                Log.d(TAG, "✅ Daily safety check scheduled for ${nextCheck.toLocalTime()} (in ${hoursUntil}h)")
            } catch (e: Exception) {
                Log.e(TAG, "❌ Error scheduling daily safety check: ${e.message}", e)
            }
        }
        
        private fun schedulePrayerAlarm(context: Context, prayerName: String, prayerTime: String) {
            try {
                Log.d(TAG, "")
                Log.d(TAG, "─────────────────────────────────────────────────")
                Log.d(TAG, "⏰ Scheduling: $prayerName at $prayerTime")
                
                val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
                val time = parseTimeString(prayerTime)
                val now = ZonedDateTime.now()
                
                Log.d(TAG, "🕐 Current time: ${now.toLocalTime()}")
                Log.d(TAG, "🕐 Parsed prayer time: $time")
                
                var alarmTime = now
                    .withHour(time.hour)
                    .withMinute(time.minute)
                    .withSecond(0)
                    .withNano(0)
                
                Log.d(TAG, "📅 Alarm time (today): $alarmTime")
                
                val nowPlusBuffer = now.plusSeconds(30)
                if (alarmTime.isBefore(nowPlusBuffer)) {
                    alarmTime = alarmTime.plusDays(1)
                    Log.d(TAG, "⏰ Time has passed, scheduling for TOMORROW")
                    Log.d(TAG, "📅 New alarm time: $alarmTime")
                } else {
                    Log.d(TAG, "✅ Scheduling for TODAY")
                }
                
                val millisUntilAlarm = alarmTime.toInstant().toEpochMilli() - System.currentTimeMillis()
                val minutesUntilAlarm = millisUntilAlarm / 60000
                val hoursUntilAlarm = minutesUntilAlarm / 60
                val remainingMinutes = minutesUntilAlarm % 60
                
                Log.d(TAG, "⏳ Time until alarm: ${hoursUntilAlarm}h ${remainingMinutes}m")
                
                val intent = Intent(context, PrayerAlarmReceiver::class.java).apply {
                    action = ACTION_PRAYER_ALARM
                    putExtra(EXTRA_PRAYER_NAME, prayerName)
                    putExtra(EXTRA_PRAYER_TIME, prayerTime)
                }
                
                val requestCode = getRequestCodeForPrayer(prayerName)
                Log.d(TAG, "🔑 Request code: $requestCode")
                
                val pendingIntent = PendingIntent.getBroadcast(
                    context,
                    requestCode,
                    intent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )
                
                alarmManager.cancel(pendingIntent)
                Log.d(TAG, "🚫 Cancelled any existing alarm")
                
                val alarmTimeMillis = alarmTime.toInstant().toEpochMilli()
                
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                    if (alarmManager.canScheduleExactAlarms()) {
                        Log.d(TAG, "✅ Using setExactAndAllowWhileIdle (Android 12+)")
                        alarmManager.setExactAndAllowWhileIdle(
                            AlarmManager.RTC_WAKEUP,
                            alarmTimeMillis,
                            pendingIntent
                        )
                    } else {
                        Log.w(TAG, "⚠️ Cannot schedule exact alarms, using setAndAllowWhileIdle")
                        Log.w(TAG, "   Please grant 'Alarms & reminders' permission in Settings")
                        alarmManager.setAndAllowWhileIdle(
                            AlarmManager.RTC_WAKEUP,
                            alarmTimeMillis,
                            pendingIntent
                        )
                    }
                } else {
                    Log.d(TAG, "✅ Using setExactAndAllowWhileIdle (Android < 12)")
                    alarmManager.setExactAndAllowWhileIdle(
                        AlarmManager.RTC_WAKEUP,
                        alarmTimeMillis,
                        pendingIntent
                    )
                }
                
                Log.d(TAG, "✅ $prayerName alarm scheduled successfully!")
                Log.d(TAG, "─────────────────────────────────────────────────")
                
            } catch (e: Exception) {
                Log.e(TAG, "❌ Error scheduling $prayerName alarm: ${e.message}", e)
                Log.e(TAG, "─────────────────────────────────────────────────")
            }
        }
        
        fun cancelAllPrayerAlarms(context: Context) {
            Log.d(TAG, "🚫 Cancelling all prayer alarms...")
            
            val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
            val prayers = listOf("Subuh", "Zohor", "Asar", "Maghrib", "Isyak")
            
            prayers.forEach { prayerName ->
                val intent = Intent(context, PrayerAlarmReceiver::class.java).apply {
                    action = ACTION_PRAYER_ALARM
                }
                val requestCode = getRequestCodeForPrayer(prayerName)
                val pendingIntent = PendingIntent.getBroadcast(
                    context,
                    requestCode,
                    intent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )
                alarmManager.cancel(pendingIntent)
                Log.d(TAG, "   ✅ $prayerName alarm cancelled")
            }
            
            Log.d(TAG, "✅ All prayer alarms cancelled")
        }
        
        private fun getRequestCodeForPrayer(prayerName: String): Int {
            return when (prayerName.lowercase()) {
                "subuh" -> REQUEST_CODE_SUBUH
                "zohor" -> REQUEST_CODE_ZOHOR
                "asar" -> REQUEST_CODE_ASAR
                "maghrib" -> REQUEST_CODE_MAGHRIB
                "isyak" -> REQUEST_CODE_ISYAK
                else -> 1000
            }
        }
        
        private fun parseTimeString(timeStr: String): LocalTime {
            val cleaned = timeStr.trim().lowercase()
            val noSpaces = cleaned.replace(" ", "")
            val withColon = noSpaces.replace(".", ":")
            val timePart = withColon.replace(Regex("[^0-9:]"), "")
            
            return if (timePart.contains(":")) {
                val (hourStr, minStr) = timePart.split(":")
                var hour = hourStr.toInt()
                val minute = minStr.toInt()
                
                if (cleaned.contains("pm") && hour != 12) {
                    hour += 12
                } else if (cleaned.contains("am") && hour == 12) {
                    hour = 0
                }
                
                LocalTime.of(hour, minute)
            } else {
                LocalTime.of(timePart.toInt(), 0)
            }
        }
    }
    
    override fun onReceive(context: Context, intent: Intent?) {
        Log.d(TAG, "═══════════════════════════════════════════════════")
        Log.d(TAG, "🔔 ALARM TRIGGERED!")
        Log.d(TAG, "═══════════════════════════════════════════════════")

        when (intent?.action) {
            ACTION_DAILY_RESCHEDULE -> {
                Log.d(TAG, "🛡️ Daily safety check triggered - rescheduling all alarms...")
                scheduleAllPrayerAlarms(context)
                Log.d(TAG, "✅ Daily safety check complete")
                Log.d(TAG, "═══════════════════════════════════════════════════")
                return
            }
            ACTION_PRAYER_ALARM -> {
                // Continue with normal prayer alarm handling
            }
            else -> {
                Log.w(TAG, "⚠️ Wrong action: ${intent?.action}")
                return
            }
        }

        val prayerName = intent.getStringExtra(EXTRA_PRAYER_NAME)
        val prayerTime = intent.getStringExtra(EXTRA_PRAYER_TIME)
        
        if (prayerName == null || prayerTime == null) {
            Log.e(TAG, "❌ Prayer name or time is null!")
            return
        }
        
        Log.d(TAG, "📿 Prayer: $prayerName")
        Log.d(TAG, "🕐 Time: $prayerTime")
        Log.d(TAG, "⏰ Triggered at: ${ZonedDateTime.now()}")
        
        // Wake up device
        Log.d(TAG, "📱 Waking up device...")
        wakeUpDevice(context)

        // Store alarm data for app to check when it starts
        Log.d(TAG, "💾 Storing alarm data...")
        storeAlarmData(context, prayerName, prayerTime)

        // Launch app FIRST (before notification) for better chance of showing over lock screen
        Log.d(TAG, "📲 Launching app with lock screen flags...")
        launchAppOverLockScreen(context, prayerName, prayerTime)

        // Show notification as fallback (for when app is killed or launch blocked)
        Log.d(TAG, "🔔 Showing notification as fallback...")
        showPrayerNotification(context, prayerName, prayerTime)
        
        // Reschedule this prayer for tomorrow
        Log.d(TAG, "🔄 Rescheduling for tomorrow...")
        schedulePrayerAlarm(context, prayerName, prayerTime)
        
        Log.d(TAG, "═══════════════════════════════════════════════════")
    }
    
    private fun wakeUpDevice(context: Context) {
        try {
            val powerManager = context.getSystemService(Context.POWER_SERVICE) as PowerManager
            val wakeLock = powerManager.newWakeLock(
                PowerManager.SCREEN_BRIGHT_WAKE_LOCK or 
                PowerManager.ACQUIRE_CAUSES_WAKEUP or
                PowerManager.ON_AFTER_RELEASE,
                "$TAG:WakeLock"
            )
            wakeLock.acquire(30000) // 30 seconds
            Log.d(TAG, "✅ Device screen turned on")
        } catch (e: Exception) {
            Log.e(TAG, "❌ Error waking device: ${e.message}")
        }
    }
    
    private fun showPrayerNotification(context: Context, prayerName: String, prayerTime: String) {
        try {
            val notificationManager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

            // Read prayer-specific settings from Flutter SharedPreferences
            val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
            val prayerKey = prayerName.lowercase()

            // Get settings for this specific prayer
            val vibrateEnabled = prefs.getBoolean("flutter.pref${prayerName}Vibrate", true)
            val ledEnabled = prefs.getBoolean("flutter.pref${prayerName}Led", true)

            Log.d(TAG, "📋 Prayer settings for $prayerName:")
            Log.d(TAG, "   Vibrate: $vibrateEnabled")
            Log.d(TAG, "   LED: $ledEnabled")

            // Create notification channel (Android 8.0+) with prayer-specific settings
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                val channel = NotificationChannel(
                    "prayer_alarm_channel",
                    "Prayer Alarms",
                    NotificationManager.IMPORTANCE_HIGH
                ).apply {
                    description = "Notifications for prayer times"
                    setShowBadge(true)
                    lockscreenVisibility = Notification.VISIBILITY_PUBLIC
                    setBypassDnd(true) // Show even in Do Not Disturb mode

                    // Apply vibration based on prayer settings
                    if (vibrateEnabled) {
                        enableVibration(true)
                        vibrationPattern = longArrayOf(0, 500, 200, 500)
                        Log.d(TAG, "   ✅ Vibration enabled")
                    } else {
                        enableVibration(false)
                        Log.d(TAG, "   ❌ Vibration disabled")
                    }

                    // Apply LED based on prayer settings
                    if (ledEnabled) {
                        enableLights(true)
                        lightColor = android.graphics.Color.GREEN
                        Log.d(TAG, "   ✅ LED enabled")
                    } else {
                        enableLights(false)
                        Log.d(TAG, "   ❌ LED disabled")
                    }
                }
                notificationManager.createNotificationChannel(channel)
            }

            // Create full-screen intent with AGGRESSIVE flags for showing even when locked/background
            val fullScreenIntent = Intent(context, MainActivity::class.java).apply {
                // MOST AGGRESSIVE FLAGS to ensure app shows in ALL states
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or
                        Intent.FLAG_ACTIVITY_CLEAR_TOP or
                        Intent.FLAG_ACTIVITY_SINGLE_TOP or
                        Intent.FLAG_ACTIVITY_NO_USER_ACTION or
                        Intent.FLAG_ACTIVITY_EXCLUDE_FROM_RECENTS or
                        Intent.FLAG_ACTIVITY_REORDER_TO_FRONT or
                        Intent.FLAG_ACTIVITY_NO_ANIMATION

                putExtra("prayer_alarm", true)
                putExtra("prayer_name", prayerName)
                putExtra("prayer_time", prayerTime)
                putExtra("force_fullscreen", true) // Flag to force showing fullscreen
            }

            val fullScreenPendingIntent = PendingIntent.getActivity(
                context,
                prayerName.hashCode(),
                fullScreenIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )

            // Create tap intent (when user taps notification instead of auto-launch)
            val tapIntent = Intent(context, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or
                        Intent.FLAG_ACTIVITY_CLEAR_TOP or
                        Intent.FLAG_ACTIVITY_SINGLE_TOP
                putExtra("prayer_alarm", true)
                putExtra("prayer_name", prayerName)
                putExtra("prayer_time", prayerTime)
            }

            val tapPendingIntent = PendingIntent.getActivity(
                context,
                System.currentTimeMillis().toInt(),
                tapIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )

            // Build AGGRESSIVE notification with full-screen intent and prayer-specific settings
            val notificationBuilder = NotificationCompat.Builder(context, "prayer_alarm_channel")
                .setSmallIcon(android.R.drawable.ic_lock_idle_alarm) // Use alarm icon
                .setContentTitle("Solat $prayerName telah masuk")
                .setContentText("Ya Allah, jadikanlah kami dalam kalangan orang-orang yang mendirikan solat")
                .setStyle(NotificationCompat.BigTextStyle()
                    .bigText("Ya Allah, jadikanlah kami dalam kalangan orang-orang yang mendirikan solat"))
                .setPriority(NotificationCompat.PRIORITY_MAX)
                .setCategory(NotificationCompat.CATEGORY_ALARM)
                .setAutoCancel(true)
                .setContentIntent(tapPendingIntent)
                .setFullScreenIntent(fullScreenPendingIntent, true) // ✅ CRITICAL: Full-screen intent
                .setSound(null) // ✅ CRITICAL: No sound - azan plays from Flutter app only
                .setOngoing(false)
                .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
                // .setTimeoutAfter(5 * 60 * 1000) // Auto-dismiss after 5 minutes
                .setTimeoutAfter(10 * 1000) // Auto-dismiss after 10 seconds


            // Apply vibration based on prayer settings
            if (vibrateEnabled) {
                notificationBuilder.setVibrate(longArrayOf(0, 500, 200, 500))
            } else {
                notificationBuilder.setVibrate(null) // No vibration
            }

            val notification = notificationBuilder.build()

            // CRITICAL: Add flags based on prayer settings
            var flags = 0
            if (ledEnabled) {
                flags = flags or Notification.FLAG_SHOW_LIGHTS
            }
            notification.flags = notification.flags or flags

            // Show notification - this will trigger the full screen intent
            notificationManager.notify(prayerName.hashCode(), notification)

            Log.d(TAG, "✅ FULLSCREEN notification shown: $prayerName")
            Log.d(TAG, "   This should launch the app over lock screen!")
        } catch (e: Exception) {
            Log.e(TAG, "❌ Error showing notification: ${e.message}", e)
        }
    }
    
    private fun storeAlarmData(context: Context, prayerName: String, prayerTime: String) {
        try {
            // Use Flutter's SharedPreferences format
            val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
            prefs.edit().apply {
                putString("flutter.pending_prayer_name", prayerName)
                putString("flutter.pending_prayer_time", prayerTime)
                putLong("flutter.pending_prayer_timestamp", System.currentTimeMillis())
                putBoolean("flutter.has_pending_alarm", true)
                apply()
            }
            Log.d(TAG, "✅ Alarm data stored to Flutter SharedPreferences: $prayerName at $prayerTime")
        } catch (e: Exception) {
            Log.e(TAG, "❌ Error storing alarm data: ${e.message}", e)
        }
    }

    private fun launchAppOverLockScreen(context: Context, prayerName: String, prayerTime: String) {
        try {
            val mainIntent = Intent(context, MainActivity::class.java).apply {
                // MOST AGGRESSIVE FLAGS to ensure app launches in ALL states
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or
                        Intent.FLAG_ACTIVITY_CLEAR_TOP or
                        Intent.FLAG_ACTIVITY_SINGLE_TOP or
                        Intent.FLAG_ACTIVITY_NO_USER_ACTION or
                        Intent.FLAG_ACTIVITY_EXCLUDE_FROM_RECENTS or
                        Intent.FLAG_ACTIVITY_REORDER_TO_FRONT or
                        Intent.FLAG_ACTIVITY_NO_ANIMATION or
                        Intent.FLAG_ACTIVITY_BROUGHT_TO_FRONT

                putExtra("prayer_alarm", true)
                putExtra("prayer_name", prayerName)
                putExtra("prayer_time", prayerTime)
                putExtra("from_locked_screen", true)
                putExtra("force_fullscreen", true)
            }

            context.startActivity(mainIntent)
            Log.d(TAG, "✅ Launched activity DIRECTLY with aggressive flags")
            Log.d(TAG, "   App should appear over lock screen!")
        } catch (e: Exception) {
            Log.e(TAG, "❌ Error launching over lock screen: ${e.message}", e)

            // Fallback: Try without the extra flags
            try {
                val fallbackIntent = Intent(context, MainActivity::class.java).apply {
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP
                    putExtra("prayer_alarm", true)
                    putExtra("prayer_name", prayerName)
                    putExtra("prayer_time", prayerTime)
                }
                context.startActivity(fallbackIntent)
                Log.d(TAG, "✅ Launched activity with fallback flags")
            } catch (fallbackError: Exception) {
                Log.e(TAG, "❌ Fallback launch also failed: ${fallbackError.message}")
                Log.e(TAG, "   Notification full-screen intent is the last resort")
            }
        }
    }
}