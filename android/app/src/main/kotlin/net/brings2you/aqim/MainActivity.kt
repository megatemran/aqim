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
import androidx.core.view.WindowCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel     

class MainActivity : FlutterActivity() {
    private var lastWidgetUpdate: Long = 0
    private val WIDGET_UPDATE_INTERVAL = 60 * 60 * 1000L // 1 hour

    //PRAYER ALARM RECEIVER METHOD CHANNEL
    private val CHANNEL = "net.brings2you.aqim/prayer_alarm"
    private var methodChannel: MethodChannel? = null

    // Prevent duplicate alarm triggers
    private var lastAlarmTrigger: String = ""
    private var lastAlarmTime: Long = 0
    private val ALARM_DEBOUNCE_MS = 3000L // 3 seconds

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // ✅ Enable edge-to-edge for Android 15+ compatibility
        enableEdgeToEdge()

        // Check if launched by prayer alarm - apply lock screen flags IMMEDIATELY
        if (intent?.getBooleanExtra("prayer_alarm", false) == true) {
            applyLockScreenFlags()
        }

        initializeWidgetData()

        WaktuSolatWidgetUpdater.initializeScheduling(this)
        Log.d("MainActivity", "✅ WaktuSolat widget scheduling initialized")

        // Initialize Doa widget scheduling
        DoaWidgetUpdater.schedule(this)

        // Check if launched by prayer alarm
        handlePrayerAlarmIntent(intent)
        Log.d("MainActivity", "✅ onCreate initialized")
    }

    /**
     * ✅ Enable edge-to-edge display for Android 15+ compatibility
     * This replaces deprecated methods like setStatusBarColor() and setNavigationBarColor()
     */
    private fun enableEdgeToEdge() {
        try {
            // Enable edge-to-edge using WindowCompat (backward compatible)
            WindowCompat.setDecorFitsSystemWindows(window, false)
            Log.d("MainActivity", "✅ Edge-to-edge enabled successfully")
        } catch (e: Exception) {
            Log.e("MainActivity", "❌ Error enabling edge-to-edge: ${e.message}", e)
        }
    }

    // Helper function to apply all lock screen bypass flags
    private fun applyLockScreenFlags() {
        Log.d("MainActivity", "🔓 Applying MAXIMUM AGGRESSIVE lock screen bypass flags for prayer alarm")

        try {
            // Modern API (27+) - Native methods
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
                android.view.WindowManager.LayoutParams.FLAG_ALLOW_LOCK_WHILE_SCREEN_ON or
                android.view.WindowManager.LayoutParams.FLAG_FULLSCREEN or // ✅ Force fullscreen
                android.view.WindowManager.LayoutParams.FLAG_NOT_TOUCHABLE.inv() // ✅ Allow touch
            )

            // ✅ ADDITIONAL: Disable keyguard completely during alarm
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                val keyguardManager = getSystemService(Context.KEYGUARD_SERVICE) as android.app.KeyguardManager
                keyguardManager.requestDismissKeyguard(this, null)
                Log.d("MainActivity", "✅ Keyguard dismiss requested (API 26+)")
            }

            Log.d("MainActivity", "✅ ALL MAXIMUM lock screen flags applied successfully!")
            Log.d("MainActivity", "   App WILL show over lock screen in ALL conditions!")
        } catch (e: Exception) {
            Log.e("MainActivity", "❌ Error applying lock screen flags: ${e.message}", e)
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        // Setup Method Channel
        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        
        methodChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "scheduleAllPrayerAlarms" -> {
                    try {
                        PrayerAlarmReceiver.scheduleAllPrayerAlarms(this)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("ERROR", e.message, null)
                    }
                }
                "cancelAllPrayerAlarms" -> {
                    try {
                        PrayerAlarmReceiver.cancelAllPrayerAlarms(this)
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
                "canScheduleExactAlarms" -> {
                    try {
                        val canSchedule = ExactAlarmPermissionHelper.canScheduleExactAlarms(this)
                        result.success(canSchedule)
                    } catch (e: Exception) {
                        result.error("ERROR", e.message, null)
                    }
                }
                "openExactAlarmSettings" -> {
                    try {
                        if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.S) {
                            ExactAlarmPermissionHelper.openExactAlarmSettings(this)
                            result.success(true)
                        } else {
                            result.success(false) // Not needed on Android < 12
                        }
                    } catch (e: Exception) {
                        result.error("ERROR", e.message, null)
                    }
                }
                "shouldRequestExactAlarmPermission" -> {
                    try {
                        val shouldRequest = ExactAlarmPermissionHelper.shouldRequestPermission(this)
                        result.success(shouldRequest)
                    } catch (e: Exception) {
                        result.error("ERROR", e.message, null)
                    }
                }
                "markExactAlarmPermissionAsked" -> {
                    try {
                        val userDismissed = call.argument<Boolean>("dismissed") ?: false
                        ExactAlarmPermissionHelper.markPermissionAsked(this, userDismissed)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("ERROR", e.message, null)
                    }
                }
                "canUseFullScreenIntent" -> {
                    try {
                        val canUse = FullScreenIntentPermissionHelper.canUseFullScreenIntent(this)
                        result.success(canUse)
                    } catch (e: Exception) {
                        result.error("ERROR", e.message, null)
                    }
                }
                "openFullScreenIntentSettings" -> {
                    try {
                        if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
                            FullScreenIntentPermissionHelper.openFullScreenIntentSettings(this)
                            result.success(true)
                        } else {
                            result.success(false) // Not needed on Android < 14
                        }
                    } catch (e: Exception) {
                        result.error("ERROR", e.message, null)
                    }
                }
                "shouldRequestFullScreenIntentPermission" -> {
                    try {
                        val shouldRequest = FullScreenIntentPermissionHelper.shouldRequestPermission(this)
                        result.success(shouldRequest)
                    } catch (e: Exception) {
                        result.error("ERROR", e.message, null)
                    }
                }
                "markFullScreenIntentPermissionAsked" -> {
                    try {
                        val userDismissed = call.argument<Boolean>("dismissed") ?: false
                        FullScreenIntentPermissionHelper.markPermissionAsked(this, userDismissed)
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
    }

    override fun onResume() {
        super.onResume()
        updateWidgetIfNeeded()
        checkPendingAlarm()
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
                    handlePrayerAlarmIntent(Intent().apply {
                        putExtra("prayer_alarm", true)
                        putExtra("prayer_name", prayerName)
                        putExtra("prayer_time", prayerTime)
                    })
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
                    methodChannel?.invokeMethod("onPrayerAlarm", mapOf(
                        "prayerName" to prayerName,
                        "prayerTime" to prayerTime,
                        "timestamp" to System.currentTimeMillis()
                    ))
                    Log.d("MainActivity", "✅ Sent prayer alarm to Flutter: $prayerName")
                }, 500) // Wait 500ms for Flutter to initialize (faster response)
            }
        }
    }
    
    private fun testNotification() {
        val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        
        // Create channel
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                "test_channel",
                "Test Notifications",
                NotificationManager.IMPORTANCE_MAX
            )
            notificationManager.createNotificationChannel(channel)
        }
        
        // Build notification
        val notification = NotificationCompat.Builder(this, "test_channel")
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