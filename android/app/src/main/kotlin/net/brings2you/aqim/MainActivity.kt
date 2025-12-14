package net.brings2you.aqim

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.Bundle
import android.util.Log
import androidx.core.app.NotificationCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.time.ZonedDateTime

class MainActivity : FlutterActivity() {
    // ktlint -F "**/*.kt"
    private var lastWidgetUpdate: Long = 0
    private val WIDGET_UPDATE_INTERVAL = 60 * 60 * 1000L // 1 hour

    // PRAYER ALARM RECEIVER METHOD CHANNEL
    private val PRAYER_CHANNEL = "net.brings2you.aqim/prayer_alarm"
    private var prayerMethodChannel: MethodChannel? = null

    // ALARM TESTER METHOD CHANNEL
    private val TESTER_CHANNEL = "net.brings2you.aqim/alarm_tester"
    private var testerMethodChannel: MethodChannel? = null

    // Prevent duplicate alarm triggers
    private var lastAlarmTrigger: String = ""
    private var lastAlarmTime: Long = 0
    private val ALARM_DEBOUNCE_MS = 3000L // 3 seconds

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // Check if launched by prayer alarm - apply lock screen flags IMMEDIATELY
        if (intent?.getBooleanExtra("prayer_alarm", false) == true) {
            applyLockScreenFlags()
        }

        initializeWidgetData()

        // Initialize Doa widget scheduling
        DoaWidgetUpdater.schedule(this)

        // Check if launched by prayer alarm
        handlePrayerAlarmIntent(intent)
        Log.d("MainActivity", "✅ onCreate initialized")

        // ✅ Test alarms immediately on startup for debugging
        testAlarmsOnStartup()
    }

    // ✅ TAMBAHKAN: Test alarms on startup
    private fun testAlarmsOnStartup() {
        // Only run test on fresh startup, not on resume
        if (intent?.action == Intent.ACTION_MAIN && intent.categories?.contains(Intent.CATEGORY_LAUNCHER) == true) {
            Log.d("MainActivity", "🚀 Fresh app launch - running alarm tests...")

            // Schedule test alarm in 15 seconds
            android.os.Handler(mainLooper).postDelayed({
                AlarmTester.testAllAlarms(this)
            }, 15000)
        }
    }

    // Helper function to apply all lock screen bypass flags
    private fun applyLockScreenFlags() {
        Log.d("MainActivity", "🔓 Applying lock screen bypass flags for prayer alarm")

        try {
            // Modern API (27+)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
                setShowWhenLocked(true)
                setTurnScreenOn(true)
                Log.d("MainActivity", "✅ Modern lock screen flags set (API 27+)")
            }

            // Legacy API + Extra insurance flags for ALL Android versions
            @Suppress("DEPRECATION")
            window.addFlags(
                android.view.WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
                    android.view.WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON or
                    android.view.WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON or
                    android.view.WindowManager.LayoutParams.FLAG_DISMISS_KEYGUARD or
                    android.view.WindowManager.LayoutParams.FLAG_ALLOW_LOCK_WHILE_SCREEN_ON,
            )

            Log.d("MainActivity", "✅ ALL lock screen flags applied successfully!")
        } catch (e: Exception) {
            Log.e("MainActivity", "❌ Error applying lock screen flags: ${e.message}", e)
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Setup Prayer Alarm Method Channel
        prayerMethodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, PRAYER_CHANNEL)

        prayerMethodChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "scheduleAllPrayerAlarms" -> {
                    try {
                        AppScheduler(this).scheduleNextPrayerTime()
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("ERROR", e.message, null)
                    }
                }

                "cancelAllPrayerAlarms" -> {
                    try {
                        AppScheduler(this).cancelAllAlarms()
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("ERROR", e.message, null)
                    }
                }

                "testNotification" -> {
                    try {
                        testNotification()
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("ERROR", e.message, null)
                    }
                }

                "isBatteryOptimizationDisabled" -> {
                    try {
                        val isDisabled = BatteryOptimizationHelper.isBatteryOptimizationDisabled(this)
                        result.success(isDisabled)
                    } catch (e: Exception) {
                        result.error("ERROR", e.message, null)
                    }
                }

                "requestDisableBatteryOptimization" -> {
                    try {
                        BatteryOptimizationHelper.requestDisableBatteryOptimization(this)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("ERROR", e.message, null)
                    }
                }

                "openBatteryOptimizationSettings" -> {
                    try {
                        BatteryOptimizationHelper.openBatteryOptimizationSettings(this)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("ERROR", e.message, null)
                    }
                }

                else -> {
                    result.notImplemented()
                }
            }
        }

        Log.d("MainActivity", "✅ Prayer alarm channel configured")

        // ✅ TAMBAHKAN: Setup Alarm Tester Method Channel
        setupAlarmTesterChannel(flutterEngine)
    }

    // ✅ TAMBAHKAN: Setup Alarm Tester Channel
    private fun setupAlarmTesterChannel(flutterEngine: FlutterEngine) {
        testerMethodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, TESTER_CHANNEL)

        testerMethodChannel?.setMethodCallHandler { call, result ->
            Log.d("MainActivity", "🔧 AlarmTester method called: ${call.method}")

            when (call.method) {
                "testImmediateAlarm" -> {
                    try {
                        AlarmTester.testAllAlarms(this)
                        result.success("Test alarm scheduled! Check notifications in 10 seconds.")
                    } catch (e: Exception) {
                        Log.e("MainActivity", "❌ Error testing immediate alarm", e)
                        result.error("ERROR", e.message, null)
                    }
                }

                "testAppScheduler" -> {
                    try {
                        AppScheduler(this).scheduleNextPrayerTime()
                        result.success("AppScheduler executed successfully")
                    } catch (e: Exception) {
                        Log.e("MainActivity", "❌ Error testing AppScheduler", e)
                        result.error("ERROR", e.message, null)
                    }
                }

                "testAppReceiver" -> {
                    try {
                        AppReceiver.scheduleAllAppAlarms(this)
                        result.success("AppReceiver executed successfully")
                    } catch (e: Exception) {
                        Log.e("MainActivity", "❌ Error testing AppReceiver", e)
                        result.error("ERROR", e.message, null)
                    }
                }

                "getPrayerTimes" -> {
                    try {
                        val times = getCurrentPrayerTimes()
                        result.success(times)
                    } catch (e: Exception) {
                        Log.e("MainActivity", "❌ Error getting prayer times", e)
                        result.error("ERROR", e.message, null)
                    }
                }

                "getScheduledAlarmInfo" -> {
                    try {
                        val info = getScheduledAlarmInfo()
                        result.success(info)
                    } catch (e: Exception) {
                        Log.e("MainActivity", "❌ Error getting alarm info", e)
                        result.error("ERROR", e.message, null)
                    }
                }

                else -> {
                    result.notImplemented()
                }
            }
        }

        Log.d("MainActivity", "✅ AlarmTester channel configured")
    }

    // ✅ TAMBAHKAN: Get current prayer times
    private fun getCurrentPrayerTimes(): Map<String, Any> {
        val prefs = getSharedPreferences("HomeWidgetPreferences", Context.MODE_PRIVATE)

        val times =
            mapOf(
                "Subuh" to (prefs.getString("subuh", "") ?: ""),
                "Zohor" to (prefs.getString("zohor", "") ?: ""),
                "Asar" to (prefs.getString("asar", "") ?: ""),
                "Maghrib" to (prefs.getString("maghrib", "") ?: ""),
                "Isyak" to (prefs.getString("isyak", "") ?: ""),
            )

        Log.d("MainActivity", "📋 Current prayer times: $times")
        return times
    }

    // ✅ TAMBAHKAN: Get scheduled alarm information
    private fun getScheduledAlarmInfo(): Map<String, Any> {
        try {
            val appScheduler = AppScheduler(this)
            val prefs = getSharedPreferences("HomeWidgetPreferences", Context.MODE_PRIVATE)

            // Get next prayer time
            val subuh = prefs.getString("subuh", "") ?: ""
            val zohor = prefs.getString("zohor", "") ?: ""
            val asar = prefs.getString("asar", "") ?: ""
            val maghrib = prefs.getString("maghrib", "") ?: ""
            val isyak = prefs.getString("isyak", "") ?: ""

            val azanData = appScheduler.getNextUpdateTime(subuh, zohor, asar, maghrib, isyak)

            val info = mutableMapOf<String, Any>()
            info["current_time"] = ZonedDateTime.now().toString()
            info["next_prayer"] = azanData?.prayerName ?: "unknown"
            info["next_prayer_time_millis"] = azanData?.timeMillis ?: 0L
            info["next_prayer_time_formatted"] =
                if (azanData != null) {
                    val zdt =
                        java.time.Instant
                            .ofEpochMilli(azanData.timeMillis)
                            .atZone(java.time.ZoneId.systemDefault())
                    "${zdt.hour}:${zdt.minute.toString().padStart(2, '0')}"
                } else {
                    "unknown"
                }
            info["exact_alarm_permission"] = appScheduler.canScheduleExactAlarms()

            Log.d("MainActivity", "🔍 Alarm info: $info")
            return info
        } catch (e: Exception) {
            Log.e("MainActivity", "❌ Error getting alarm info", e)
            return mapOf("error" to e.message.toString())
        }
    }

    override fun onResume() {
        super.onResume()
        updateWidgetIfNeeded()
        checkPendingAlarm()

        // ✅ Log current alarm status
        logAlarmStatus()
    }

    // ✅ TAMBAHKAN: Log current alarm status
    private fun logAlarmStatus() {
        Log.d("MainActivity", "═══════════════════════════════════════════════════")
        Log.d("MainActivity", "🔔 CURRENT ALARM STATUS")
        Log.d("MainActivity", "═══════════════════════════════════════════════════")

        val times = getCurrentPrayerTimes()
        times.forEach { (name, time) ->
            Log.d("MainActivity", "   $name: $time")
        }

        val alarmInfo = getScheduledAlarmInfo()
        alarmInfo.forEach { (key, value) ->
            Log.d("MainActivity", "   $key: $value")
        }

        Log.d("MainActivity", "═══════════════════════════════════════════════════")
    }

    private fun checkPendingAlarm() {
        try {
            // Use Flutter's SharedPreferences format
            val prefs = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
            val hasPending = prefs.getBoolean("flutter.has_pending_alarm", false)

            if (hasPending) {
                val prayerName = prefs.getString("flutter.pending_prayer_name", "") ?: ""
                val prayerTime = prefs.getString("flutter.pending_prayer_time", "") ?: ""
                val timestamp = prefs.getLong("flutter.pending_prayer_timestamp", 0)

                // Clear pending alarm FIRST to prevent duplicate triggers
                prefs.edit().putBoolean("flutter.has_pending_alarm", false).apply()

                // Check if alarm is recent (within last 5 minutes)
                val age = System.currentTimeMillis() - timestamp
                if (age < 5 * 60 * 1000 && prayerName.isNotEmpty()) {
                    // Check if we already handled this alarm recently
                    val alarmKey = "$prayerName:$prayerTime"
                    if (alarmKey == lastAlarmTrigger && (System.currentTimeMillis() - lastAlarmTime) < ALARM_DEBOUNCE_MS) {
                        Log.d("MainActivity", "⏭️ Skipping duplicate pending alarm: $prayerName")
                        return
                    }

                    Log.d("MainActivity", "📲 Found pending alarm from Flutter SharedPreferences: $prayerName at $prayerTime")
                    handlePrayerAlarmIntent(
                        Intent().apply {
                            putExtra("prayer_alarm", true)
                            putExtra("prayer_name", prayerName)
                            putExtra("prayer_time", prayerTime)
                        },
                    )
                }
            }
        } catch (e: Exception) {
            Log.e("MainActivity", "❌ Error checking pending alarm: ${e.message}", e)
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)

        // Apply lock screen flags if this is a prayer alarm intent
        if (intent.getBooleanExtra("prayer_alarm", false) == true) {
            applyLockScreenFlags()
        }

        // Handle new intent (when app is already running)
        handlePrayerAlarmIntent(intent)
    }

    private fun initializeWidgetData() {
        try {
            val prefs = getSharedPreferences("doa_prefs", Context.MODE_PRIVATE)
            if (!prefs.contains("arabic")) {
                prefs.edit().apply {
                    putString("arabic", "اللّهُمَّ اجْعَلْنِي مِنَ التَّوَّابِينَ")
                    putString("title_ms", "Doa Harian")
                    putString("ms", "Ya Allah, jadikan aku daripada orang yang bertaubat.")
                    putString("ref", "Quran")
                    putLong("last_update", System.currentTimeMillis())
                    apply()
                }
            }
        } catch (e: Exception) {
            Log.e("MainActivity", "❌ Error initializing widget data: ${e.message}", e)
        }
    }

    private fun updateWidgetIfNeeded() {
        val now = System.currentTimeMillis()
        if (now - lastWidgetUpdate > WIDGET_UPDATE_INTERVAL) {
            lastWidgetUpdate = now
        }
    }

    private fun handlePrayerAlarmIntent(intent: Intent?) {
        if (intent?.getBooleanExtra("prayer_alarm", false) == true) {
            val prayerName = intent.getStringExtra("prayer_name") ?: return
            val prayerTime = intent.getStringExtra("prayer_time") ?: return

            // Check for duplicate alarm triggers
            val alarmKey = "$prayerName:$prayerTime"
            val now = System.currentTimeMillis()

            if (alarmKey == lastAlarmTrigger && (now - lastAlarmTime) < ALARM_DEBOUNCE_MS) {
                Log.d("MainActivity", "⏭️ Skipping duplicate alarm: $prayerName (${now - lastAlarmTime}ms ago)")
                return
            }

            // Update last alarm info
            lastAlarmTrigger = alarmKey
            lastAlarmTime = now

            Log.d("MainActivity", "🔔 Prayer alarm received: $prayerName at $prayerTime")

            // Clear intent extras to prevent re-trigger
            intent.removeExtra("prayer_alarm")
            intent.removeExtra("prayer_name")
            intent.removeExtra("prayer_time")

            // Wait for Flutter to be ready, then send data
            flutterEngine?.dartExecutor?.let { executor ->
                // Post to handler to ensure Flutter is ready
                android.os.Handler(android.os.Looper.getMainLooper()).postDelayed({
                    prayerMethodChannel?.invokeMethod(
                        "onPrayerAlarm",
                        mapOf(
                            "prayerName" to prayerName,
                            "prayerTime" to prayerTime,
                            "timestamp" to System.currentTimeMillis(),
                        ),
                    )
                    Log.d("MainActivity", "✅ Sent prayer alarm to Flutter: $prayerName")
                }, 500) // Wait 500ms for Flutter to initialize (faster response)
            }
        }
    }

    private fun testNotification() {
        val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

        // Create channel
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel =
                NotificationChannel(
                    "test_channel",
                    "Test Notifications",
                    NotificationManager.IMPORTANCE_HIGH,
                )
            notificationManager.createNotificationChannel(channel)
        }

        // Build notification
        val notification =
            NotificationCompat
                .Builder(this, "test_channel")
                .setSmallIcon(android.R.drawable.ic_dialog_info)
                .setContentTitle("Test Notification")
                .setContentText("If you see this, notifications work!")
                .setPriority(NotificationCompat.PRIORITY_HIGH)
                .setAutoCancel(true)
                .build()

        // Show notification
        notificationManager.notify(999, notification)

        Log.d("MainActivity", "✅ Test notification sent")
    }
}
