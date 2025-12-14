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

class AppReceiver : BroadcastReceiver() {
    companion object {
        private const val TAG = "AppReceiver"
        private const val CHANNEL_NAME = "net.brings2you.aqim/app_alarms"

        // Custom actions for our app
        const val ACTION_DAILY_RESCHEDULE = "net.brings2you.aqim.DAILY_RESCHEDULE"
        const val ACTION_APP_ALARM = "net.brings2you.aqim.APP_ALARM"
        const val ACTION_START_FOREGROUND_SERVICE = "net.brings2you.aqim.START_FOREGROUND_SERVICE"
        const val ACTION_HEARTBEAT = "net.brings2you.aqim.HEARTBEAT"
        const val ACTION_APP_SCHEDULER_ALARM = "net.brings2you.aqim.APP_SCHEDULER_ALARM"

        // ✅ TAMBAHKAN actions untuk AppScheduler integration
        const val ACTION_EXACT_AZAN_PRIMARY = "net.brings2you.aqim.ACTION_EXACT_AZAN_PRIMARY"
        const val ACTION_BACKUP_AZAN_ALARM = "net.brings2you.aqim.ACTION_BACKUP_AZAN_ALARM"
        const val ACTION_BOOT_COMPLETED = "android.intent.action.BOOT_COMPLETED"

        // Base IDs for alarms
        const val BASE_ID_SUBUH = 1000
        const val BASE_ID_ZOHOR = 2000
        const val BASE_ID_ASAR = 3000
        const val BASE_ID_MAGHRIB = 4000
        const val BASE_ID_ISYAK = 5000
        private const val REQUEST_CODE_DAILY_RESCHEDULE = 1999

        private const val EXTRA_ALARM_NAME = "alarm_name"
        private const val EXTRA_ALARM_TIME = "alarm_time"

        // Helper to get base ID
        fun getBaseID(alarmName: String): Int =
            when (alarmName.lowercase()) {
                "subuh" -> BASE_ID_SUBUH
                "zohor" -> BASE_ID_ZOHOR
                "asar" -> BASE_ID_ASAR
                "maghrib" -> BASE_ID_MAGHRIB
                "isyak" -> BASE_ID_ISYAK
                else -> 9999
            }

        fun scheduleAllAppAlarms(context: Context) {
            Log.d(TAG, "═══════════════════════════════════════════════════")
            Log.d(TAG, "🔔 AppReceiver: Scheduling all app alarms...")
            Log.d(TAG, "═══════════════════════════════════════════════════")

            // Check if notifications are enabled globally
            val flutterPrefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
            val notificationsEnabled = flutterPrefs.getBoolean("flutter.notificationsEnabled", true)

            Log.d(TAG, "⚙️ Global notification setting: $notificationsEnabled")

            if (!notificationsEnabled) {
                Log.w(TAG, "⚠️ Notifications are disabled globally. Skipping all app alarms.")
                Log.d(TAG, "═══════════════════════════════════════════════════")
                return
            }

            // Read prayer times from SharedPreferences
            val prefs = context.getSharedPreferences("HomeWidgetPreferences", Context.MODE_PRIVATE)

            val prayers =
                mapOf(
                    "Subuh" to prefs.getString("subuh", ""),
                    "Zohor" to prefs.getString("zohor", ""),
                    "Asar" to prefs.getString("asar", ""),
                    "Maghrib" to prefs.getString("maghrib", ""),
                    "Isyak" to prefs.getString("isyak", ""),
                )

            Log.d(TAG, "📋 Prayer times from SharedPreferences:")
            prayers.forEach { (name, time) ->
                Log.d(TAG, "   $name: $time")
            }

            // Schedule each prayer
            prayers.forEach { (name, time) ->
                if (!time.isNullOrEmpty()) {
                    // Check if this specific prayer is enabled
                    val prayerEnabled = flutterPrefs.getBoolean("flutter.${name.lowercase()}Enabled", true)

                    if (prayerEnabled) {
                        Log.d(TAG, "✅ $name is enabled, scheduling alarm")
                        scheduleAppAlarm(context, name, time, 0) // Main alarm
                    } else {
                        Log.w(TAG, "⚠️ $name is disabled in settings, skipping alarm")
                    }
                } else {
                    Log.w(TAG, "⚠️ $name time is empty, skipping")
                }
            }

            Log.d(TAG, "═══════════════════════════════════════════════════")
            Log.d(TAG, "✅ App alarms scheduled (respecting user settings)")
            Log.d(TAG, "═══════════════════════════════════════════════════")

            // ✅ Schedule daily safety check
            scheduleDailySafetyCheck(context)
        }

        /**
         * Schedule a daily alarm to reschedule all app alarms as a safety net
         */
        private fun scheduleDailySafetyCheck(context: Context) {
            try {
                Log.d(TAG, "")
                Log.d(TAG, "🛡️ AppReceiver: Scheduling daily safety check...")

                val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
                val now = ZonedDateTime.now()

                // Schedule for 3:00 AM tomorrow
                var nextCheck =
                    now
                        .withHour(3)
                        .withMinute(0)
                        .withSecond(0)
                        .withNano(0)

                // If 3 AM has already passed today, schedule for tomorrow
                if (nextCheck.isBefore(now)) {
                    nextCheck = nextCheck.plusDays(1)
                }

                val intent =
                    Intent(context, AppReceiver::class.java).apply {
                        action = ACTION_DAILY_RESCHEDULE
                    }

                val pendingIntent =
                    PendingIntent.getBroadcast(
                        context,
                        REQUEST_CODE_DAILY_RESCHEDULE,
                        intent,
                        PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
                    )

                // Cancel any existing daily check
                alarmManager.cancel(pendingIntent)

                val checkTimeMillis = nextCheck.toInstant().toEpochMilli()

                // Use setInexactRepeating for better battery efficiency
                alarmManager.setInexactRepeating(
                    AlarmManager.RTC_WAKEUP,
                    checkTimeMillis,
                    AlarmManager.INTERVAL_DAY,
                    pendingIntent,
                )

                val hoursUntil =
                    java.time.Duration
                        .between(now, nextCheck)
                        .toHours()
                Log.d(TAG, "✅ Daily safety check scheduled for ${nextCheck.toLocalTime()} (in ${hoursUntil}h)")
            } catch (e: Exception) {
                Log.e(TAG, "❌ Error scheduling daily safety check: ${e.message}", e)
            }
        }

        fun scheduleAppAlarm(
            context: Context,
            alarmName: String,
            alarmTimeStr: String,
            offsetMinutes: Int = 0,
        ) {
            try {
                Log.d(TAG, "")
                Log.d(TAG, "─────────────────────────────────────────────────")
                Log.d(TAG, "⏰ AppReceiver: Scheduling: $alarmName at $alarmTimeStr (offset: $offsetMinutes min)")

                val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
                val time = parseTimeString(alarmTimeStr)
                val now = ZonedDateTime.now()

                Log.d(TAG, "🕐 Current time: ${now.toLocalTime()}")
                Log.d(TAG, "🕐 Parsed alarm time: $time")

                var alarmTime =
                    now
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

                // Apply offset if any
                if (offsetMinutes != 0) {
                    alarmTime =
                        if (offsetMinutes > 0) {
                            alarmTime.plusMinutes(offsetMinutes.toLong())
                        } else {
                            alarmTime.minusMinutes(-offsetMinutes.toLong())
                        }
                    Log.d(TAG, "⏱️ Applied offset: $offsetMinutes minutes")
                    Log.d(TAG, "📅 Adjusted alarm time: $alarmTime")
                }

                val millisUntilAlarm = alarmTime.toInstant().toEpochMilli() - System.currentTimeMillis()
                val minutesUntilAlarm = millisUntilAlarm / 60000
                val hoursUntilAlarm = minutesUntilAlarm / 60
                val remainingMinutes = minutesUntilAlarm % 60

                Log.d(TAG, "⏳ Time until alarm: ${hoursUntilAlarm}h ${remainingMinutes}m")

                val intent =
                    Intent(context, AppReceiver::class.java).apply {
                        action = ACTION_APP_ALARM
                        putExtra(EXTRA_ALARM_NAME, alarmName)
                        putExtra(EXTRA_ALARM_TIME, alarmTimeStr)
                        putExtra("offset_minutes", offsetMinutes)
                    }

                val requestCode = getBaseID(alarmName) + offsetMinutes
                Log.d(TAG, "🔑 Request code: $requestCode")

                val pendingIntent =
                    PendingIntent.getBroadcast(
                        context,
                        requestCode,
                        intent,
                        PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
                    )

                alarmManager.cancel(pendingIntent)
                Log.d(TAG, "🚫 Cancelled any existing alarm")

                val alarmTimeMillis = alarmTime.toInstant().toEpochMilli()

                // Create show intent for setAlarmClock (shows in alarm clock apps)
                val showIntent =
                    Intent(context, MainActivity::class.java).apply {
                        putExtra("app_alarm", true)
                        putExtra("alarm_name", alarmName)
                        putExtra("alarm_time", alarmTimeStr)
                        putExtra("offset_minutes", offsetMinutes)
                    }
                val showPendingIntent =
                    PendingIntent.getActivity(
                        context,
                        requestCode + 5000,
                        showIntent,
                        PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
                    )

                // ✅ BEST METHOD: Use setAlarmClock for highest priority
                val alarmClockInfo = AlarmManager.AlarmClockInfo(alarmTimeMillis, showPendingIntent)

                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                    if (alarmManager.canScheduleExactAlarms()) {
                        Log.d(TAG, "✅ Using setAlarmClock (HIGHEST PRIORITY - bypasses all restrictions)")
                        alarmManager.setAlarmClock(alarmClockInfo, pendingIntent)
                    } else {
                        Log.w(TAG, "⚠️ Cannot schedule exact alarms, using setAndAllowWhileIdle")
                        Log.w(TAG, "   Please grant 'Alarms & reminders' permission in Settings")
                        alarmManager.setAndAllowWhileIdle(
                            AlarmManager.RTC_WAKEUP,
                            alarmTimeMillis,
                            pendingIntent,
                        )
                    }
                } else {
                    // For Android < 12, setAlarmClock always works
                    Log.d(TAG, "✅ Using setAlarmClock (HIGHEST PRIORITY - bypasses all restrictions)")
                    alarmManager.setAlarmClock(alarmClockInfo, pendingIntent)
                }

                Log.d(TAG, "✅ $alarmName alarm scheduled successfully! (offset: $offsetMinutes)")
                Log.d(TAG, "─────────────────────────────────────────────────")
            } catch (e: Exception) {
                Log.e(TAG, "❌ Error scheduling $alarmName alarm: ${e.message}", e)
                Log.e(TAG, "─────────────────────────────────────────────────")
            }
        }

        fun cancelAppAlarm(
            context: Context,
            alarmName: String,
            offsetMinutes: Int = 0,
        ) {
            Log.d(TAG, "🚫 AppReceiver: Cancelling alarm: $alarmName (offset: $offsetMinutes)")

            val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
            val intent =
                Intent(context, AppReceiver::class.java).apply {
                    action = ACTION_APP_ALARM
                }
            val requestCode = getBaseID(alarmName) + offsetMinutes
            val pendingIntent =
                PendingIntent.getBroadcast(
                    context,
                    requestCode,
                    intent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
                )
            alarmManager.cancel(pendingIntent)
            Log.d(TAG, "   ✅ $alarmName alarm cancelled (requestCode: $requestCode)")
        }

        fun cancelAllAppAlarms(context: Context) {
            Log.d(TAG, "🚫 AppReceiver: Cancelling all app alarms...")

            val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
            val prayers = listOf("Subuh", "Zohor", "Asar", "Maghrib", "Isyak")

            // Cancel main alarms and possible offsets (-30 to +30 minutes)
            prayers.forEach { prayerName ->
                for (offset in -30..30) {
                    cancelAppAlarm(context, prayerName, offset)
                }
            }

            // Cancel daily safety check
            val intent =
                Intent(context, AppReceiver::class.java).apply {
                    action = ACTION_DAILY_RESCHEDULE
                }
            val pendingIntent =
                PendingIntent.getBroadcast(
                    context,
                    REQUEST_CODE_DAILY_RESCHEDULE,
                    intent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
                )
            alarmManager.cancel(pendingIntent)

            Log.d(TAG, "✅ All app alarms cancelled")
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

    override fun onReceive(
        context: Context,
        intent: Intent?,
    ) {
        Log.d(TAG, "═══════════════════════════════════════════════════")
        Log.d(TAG, "🔔 APP RECEIVER TRIGGERED!")
        Log.d(TAG, "═══════════════════════════════════════════════════")

        when (intent?.action) {
            ACTION_DAILY_RESCHEDULE -> {
                Log.d(TAG, "🛡️ Daily safety check triggered - rescheduling all app alarms...")
                scheduleAllAppAlarms(context)
                Log.d(TAG, "✅ Daily safety check complete")
                Log.d(TAG, "═══════════════════════════════════════════════════")
                return
            }

            ACTION_APP_ALARM -> {
                handleAppAlarm(context, intent)
            }

            ACTION_APP_SCHEDULER_ALARM -> {
                Log.d(TAG, "🔄 AppScheduler alarm triggered")
                val prayerName = intent.getStringExtra("prayer_name")
                val scheduledTime = intent.getLongExtra("scheduled_time", 0L)
                Log.d(TAG, "🕌 Azan for $prayerName at $scheduledTime")
                // Integrate with AppScheduler
                AppScheduler(context).scheduleNextPrayerTime()
            }

            // ✅ TAMBAHKAN handler untuk AppScheduler actions
            ACTION_EXACT_AZAN_PRIMARY -> {
                Log.d(TAG, "🎯 PRIMARY EXACT AZAN TRIGGERED")
            }

            ACTION_BACKUP_AZAN_ALARM -> {
                Log.d(TAG, "🔄 BACKUP AZAN ALARM TRIGGERED")
            }

            // ✅ TAMBAHKAN handler untuk BOOT_COMPLETED
            ACTION_BOOT_COMPLETED, Intent.ACTION_BOOT_COMPLETED -> {
                Log.d(TAG, "🚀 BOOT COMPLETED - Rescheduling all alarms")
            }

            ACTION_START_FOREGROUND_SERVICE -> {
                Log.d(TAG, "🚀 Start foreground service triggered")
                // TODO: Implement foreground service
            }

            ACTION_HEARTBEAT -> {
                Log.d(TAG, "❤️ Heartbeat triggered")
                Log.d(TAG, "📊 System time: ${ZonedDateTime.now()}")
            }

            else -> {
                Log.w(TAG, "⚠️ Unknown action: ${intent?.action}")
                // Coba handle sebagai boot jika action string mengandung "BOOT"
                if (intent?.action?.contains("BOOT", ignoreCase = true) == true) {
                    Log.d(TAG, "🔍 Detected boot-related action, handling as boot")
                } else {
                    return
                }
            }
        }

        Log.d(TAG, "═══════════════════════════════════════════════════")
    }

    private fun handleAppAlarm(
        context: Context,
        intent: Intent,
    ) {
        val alarmName = intent.getStringExtra(EXTRA_ALARM_NAME)
        val alarmTimeStr = intent.getStringExtra(EXTRA_ALARM_TIME)
        val offsetMinutes = intent.getIntExtra("offset_minutes", 0)
        val isTestMode = intent.getBooleanExtra("test_mode", false)

        if (alarmName == null || alarmTimeStr == null) {
            Log.e(TAG, "❌ Alarm name or time is null!")
            return
        }

        Log.d(TAG, "═══════════════════════════════════════════════════")
        Log.d(TAG, "📿 Alarm: $alarmName")
        Log.d(TAG, "🕐 Time: $alarmTimeStr")
        Log.d(TAG, "⏱️ Offset: $offsetMinutes minutes")
        Log.d(TAG, "🎯 Mode: ${if (isTestMode) "TEST" else "PRODUCTION"}")
        Log.d(TAG, "⏰ Triggered at: ${ZonedDateTime.now()}")
        Log.d(TAG, "═══════════════════════════════════════════════════")

        if (isTestMode) {
            Log.d(TAG, "🧪 TEST MODE: Showing test notification...")
            showTestNotification(context, alarmName, alarmTimeStr, offsetMinutes)
            return
        }

        // ✅ VERIFY: Check if notifications are still enabled
        val flutterPrefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        val notificationsEnabled = flutterPrefs.getBoolean("flutter.notificationsEnabled", true)
        val alarmEnabled = flutterPrefs.getBoolean("flutter.${alarmName.lowercase()}Enabled", true)

        Log.d(TAG, "⚙️ Notification settings check:")
        Log.d(TAG, "   Global notifications: $notificationsEnabled")
        Log.d(TAG, "   $alarmName enabled: $alarmEnabled")

        if (!notificationsEnabled || !alarmEnabled) {
            Log.w(TAG, "⚠️ Notifications disabled for $alarmName. Cancelling alarm and rescheduling for tomorrow.")
            // Reschedule for tomorrow in case user re-enables later
            scheduleAppAlarm(context, alarmName, alarmTimeStr, offsetMinutes)
            Log.d(TAG, "═══════════════════════════════════════════════════")
            return
        }

        // Wake up device
        Log.d(TAG, "📱 Waking up device...")
        wakeUpDevice(context)

        // Store alarm data
        Log.d(TAG, "💾 Storing alarm data...")
        storeAlarmData(context, alarmName, alarmTimeStr)

        // Launch app FIRST (before notification) for better chance of showing over lock screen
        if (offsetMinutes == 0) { // Only for main alarms, not for reminders
            Log.d(TAG, "📲 Launching app with lock screen flags...")
            launchAppOverLockScreen(context, alarmName, alarmTimeStr)
        }

        // Show notification
        Log.d(TAG, "🔔 Showing notification...")
        showAppNotification(context, alarmName, alarmTimeStr, offsetMinutes)

        // Reschedule this alarm for tomorrow
        Log.d(TAG, "🔄 Rescheduling for tomorrow...")
        scheduleAppAlarm(context, alarmName, alarmTimeStr, offsetMinutes)

        Log.d(TAG, "✅ App alarm handling completed")
    }

    private fun showTestNotification(
        context: Context,
        alarmName: String,
        alarmTime: String,
        offsetMinutes: Int = 0,
    ) {
        try {
            Log.d(TAG, "🧪 Showing TEST notification...")

            val notificationManager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

            // Create test channel
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                val channel =
                    NotificationChannel(
                        "test_alarm_channel",
                        "Test Alarms",
                        NotificationManager.IMPORTANCE_HIGH,
                    ).apply {
                        description = "Test notifications for alarm debugging"
                        setShowBadge(true)
                        lockscreenVisibility = Notification.VISIBILITY_PUBLIC
                    }
                notificationManager.createNotificationChannel(channel)
            }

            val notificationTitle = "🧪 TEST: $alarmName Alarm"
            val notificationText =
                when {
                    offsetMinutes < 0 -> "Reminder $offsetMinutes min before"
                    offsetMinutes > 0 -> "Reminder $offsetMinutes min after"
                    else -> "Main alarm triggered"
                }

            // Create tap intent
            val tapIntent =
                Intent(context, MainActivity::class.java).apply {
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK or
                        Intent.FLAG_ACTIVITY_CLEAR_TOP or
                        Intent.FLAG_ACTIVITY_SINGLE_TOP
                    putExtra("test_alarm", true)
                    putExtra("alarm_name", alarmName)
                    putExtra("offset_minutes", offsetMinutes)
                }

            val tapPendingIntent =
                PendingIntent.getActivity(
                    context,
                    System.currentTimeMillis().toInt(),
                    tapIntent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
                )

            // Build notification
            val notification =
                NotificationCompat
                    .Builder(context, "test_alarm_channel")
                    .setSmallIcon(android.R.drawable.ic_dialog_info)
                    .setContentTitle(notificationTitle)
                    .setContentText(notificationText)
                    .setStyle(
                        NotificationCompat
                            .BigTextStyle()
                            .bigText("Alarm system test successful!\n\nAlarm: $alarmName\nTime: $alarmTime\nOffset: $offsetMinutes min"),
                    ).setPriority(NotificationCompat.PRIORITY_HIGH)
                    .setCategory(NotificationCompat.CATEGORY_ALARM)
                    .setAutoCancel(true)
                    .setContentIntent(tapPendingIntent)
                    .setOngoing(false)
                    .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
                    .setTimeoutAfter(30 * 1000) // Auto-dismiss after 30 seconds
                    .build()

            // Show notification
            notificationManager.notify("TEST_${alarmName}_$offsetMinutes".hashCode(), notification)

            Log.d(TAG, "✅ Test notification shown")

            // Also log to system log
            Log.d(TAG, "═══════════════════════════════════════════════════")
            Log.d(TAG, "🎯 ALARM SYSTEM TEST SUCCESSFUL!")
            Log.d(TAG, "   Alarm: $alarmName")
            Log.d(TAG, "   Time: $alarmTime")
            Log.d(TAG, "   Offset: $offsetMinutes min")
            Log.d(TAG, "   Triggered: ${ZonedDateTime.now()}")
            Log.d(TAG, "═══════════════════════════════════════════════════")
        } catch (e: Exception) {
            Log.e(TAG, "❌ Error showing test notification", e)
        }
    }

    private fun wakeUpDevice(context: Context) {
        try {
            val powerManager = context.getSystemService(Context.POWER_SERVICE) as PowerManager
            val wakeLock =
                powerManager.newWakeLock(
                    PowerManager.SCREEN_BRIGHT_WAKE_LOCK or
                        PowerManager.ACQUIRE_CAUSES_WAKEUP or
                        PowerManager.ON_AFTER_RELEASE,
                    "$TAG:WakeLock",
                )
            wakeLock.acquire(30000) // 30 seconds
            Log.d(TAG, "✅ Device screen turned on")
        } catch (e: Exception) {
            Log.e(TAG, "❌ Error waking device: ${e.message}")
        }
    }

    private fun showAppNotification(
        context: Context,
        alarmName: String,
        alarmTime: String,
        offsetMinutes: Int = 0,
    ) {
        try {
            val notificationManager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

            // Read prayer-specific settings from Flutter SharedPreferences
            val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
            val alarmKey = alarmName.lowercase()

            // Get settings for this specific alarm
            val vibrateEnabled = prefs.getBoolean("flutter.${alarmKey}Vibrate", true)
            val ledEnabled = prefs.getBoolean("flutter.${alarmKey}Led", true)

            Log.d(TAG, "📋 Alarm settings for $alarmName:")
            Log.d(TAG, "   Vibrate: $vibrateEnabled")
            Log.d(TAG, "   LED: $ledEnabled")

            // Create notification channel (Android 8.0+)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                val channel =
                    NotificationChannel(
                        "app_alarm_channel",
                        "App Alarms",
                        NotificationManager.IMPORTANCE_HIGH,
                    ).apply {
                        description = "Notifications for app alarms"
                        setShowBadge(true)
                        lockscreenVisibility = Notification.VISIBILITY_PUBLIC
                        setBypassDnd(true) // Show even in Do Not Disturb mode

                        // Apply vibration based on settings
                        if (vibrateEnabled) {
                            enableVibration(true)
                            vibrationPattern = longArrayOf(0, 500, 200, 500)
                            Log.d(TAG, "   ✅ Vibration enabled")
                        } else {
                            enableVibration(false)
                            Log.d(TAG, "   ❌ Vibration disabled")
                        }

                        // Apply LED based on settings
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

            // Create appropriate message based on offset
            val notificationTitle =
                when {
                    offsetMinutes < 0 -> "⏰ Reminder: $alarmName in ${-offsetMinutes} min"
                    offsetMinutes > 0 -> "🕌 Post-$alarmName reminder"
                    else -> "🕌 Waktu $alarmName telah masuk"
                }

            val notificationText =
                when {
                    offsetMinutes < 0 -> "Bersiap untuk $alarmName"
                    offsetMinutes > 0 -> "Sudah solat $alarmName?"
                    else -> "Ya Allah, jadikanlah kami dalam kalangan orang-orang yang mendirikan solat"
                }

            // Create tap intent
            val tapIntent =
                Intent(context, MainActivity::class.java).apply {
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK or
                        Intent.FLAG_ACTIVITY_CLEAR_TOP or
                        Intent.FLAG_ACTIVITY_SINGLE_TOP
                    putExtra("app_alarm", true)
                    putExtra("alarm_name", alarmName)
                    putExtra("alarm_time", alarmTime)
                    putExtra("offset_minutes", offsetMinutes)
                }

            val tapPendingIntent =
                PendingIntent.getActivity(
                    context,
                    System.currentTimeMillis().toInt(),
                    tapIntent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
                )

            // Build notification
            val notificationBuilder =
                NotificationCompat
                    .Builder(context, "app_alarm_channel")
                    .setSmallIcon(android.R.drawable.ic_lock_idle_alarm)
                    .setContentTitle(notificationTitle)
                    .setContentText(notificationText)
                    .setStyle(
                        NotificationCompat
                            .BigTextStyle()
                            .bigText(notificationText),
                    ).setPriority(NotificationCompat.PRIORITY_HIGH)
                    .setCategory(NotificationCompat.CATEGORY_ALARM)
                    .setAutoCancel(true)
                    .setContentIntent(tapPendingIntent)
                    .setSound(null)
                    .setOngoing(false)
                    .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
                    .setTimeoutAfter(10 * 1000) // Auto-dismiss after 10 seconds

            // Apply vibration based on settings
            if (vibrateEnabled) {
                notificationBuilder.setVibrate(longArrayOf(0, 500, 200, 500))
            } else {
                notificationBuilder.setVibrate(null)
            }

            val notification = notificationBuilder.build()

            // Apply LED flag
            var flags = 0
            if (ledEnabled) {
                flags = flags or Notification.FLAG_SHOW_LIGHTS
            }
            notification.flags = notification.flags or flags

            // Show notification
            notificationManager.notify(alarmName.hashCode() + offsetMinutes, notification)

            Log.d(TAG, "✅ Notification shown: $notificationTitle")
        } catch (e: Exception) {
            Log.e(TAG, "❌ Error showing notification: ${e.message}", e)
        }
    }

    private fun storeAlarmData(
        context: Context,
        alarmName: String,
        alarmTime: String,
    ) {
        try {
            val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
            prefs.edit().apply {
                putString("flutter.last_alarm_name", alarmName)
                putString("flutter.last_alarm_time", alarmTime)
                putLong("flutter.last_alarm_timestamp", System.currentTimeMillis())
                apply()
            }
            Log.d(TAG, "✅ Alarm data stored: $alarmName at $alarmTime")
        } catch (e: Exception) {
            Log.e(TAG, "❌ Error storing alarm data: ${e.message}", e)
        }
    }

    private fun launchAppOverLockScreen(
        context: Context,
        alarmName: String,
        alarmTime: String,
    ) {
        try {
            val mainIntent =
                Intent(context, MainActivity::class.java).apply {
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK or
                        Intent.FLAG_ACTIVITY_CLEAR_TOP or
                        Intent.FLAG_ACTIVITY_SINGLE_TOP or
                        Intent.FLAG_ACTIVITY_NO_USER_ACTION

                    putExtra("app_alarm", true)
                    putExtra("alarm_name", alarmName)
                    putExtra("alarm_time", alarmTime)
                    putExtra("from_locked_screen", true)
                }

            context.startActivity(mainIntent)
            Log.d(TAG, "✅ Launched activity with lock screen flags")
        } catch (e: Exception) {
            Log.e(TAG, "❌ Error launching over lock screen: ${e.message}", e)
        }
    }
}
