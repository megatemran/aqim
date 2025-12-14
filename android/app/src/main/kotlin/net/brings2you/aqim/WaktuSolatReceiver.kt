// package net.brings2you.aqim

// import android.app.AlarmManager
// import android.app.NotificationChannel
// import android.app.NotificationManager
// import android.app.PendingIntent
// import android.content.BroadcastReceiver
// import android.content.Context
// import android.content.Intent
// import android.os.Build
// import android.os.PowerManager
// import android.util.Log
// import androidx.core.app.NotificationCompat
// import java.time.LocalTime
// import java.time.ZonedDateTime

// class WaktuSolatReceiver : BroadcastReceiver() {
//     companion object {
//         private const val TAG = "WaktuSolatReceiver"
//         private const val ACTION_PRAYER_ALARM = "net.brings2you.aqim.PRAYER_ALARM"
//         private const val EXTRA_PRAYER_NAME = "prayer_name"
//         private const val EXTRA_PRAYER_TIME = "prayer_time"
//     }

//     override fun onReceive(
//         context: Context,
//         intent: Intent?,
//     ) {
//         val prayerName = intent?.getStringExtra(EXTRA_PRAYER_NAME)
//         val prayerTime = intent?.getStringExtra(EXTRA_PRAYER_TIME)

//         if (prayerName == null || prayerTime == null) {
//             Log.e(TAG, "Prayer name or time is null!")
//             return
//         }

//         Log.d(TAG, "🔔 Prayer alarm triggered: $prayerName at $prayerTime")
//         Log.d(TAG, "⏰ Current time: ${ZonedDateTime.now()}")

//         val inForeground = isAppInForeground(context)
//         Log.d(TAG, "App in foreground? $inForeground")

//         // Simpan data untuk app nanti
//         storeAlarmData(context, prayerName, prayerTime)

//         if (!inForeground) {
//             // App di background: tunjuk notification & wake device
//             wakeUpDevice(context)
//             showPrayerNotification(context, prayerName)
//         } else {
//             // App di foreground: boleh main azan terus (placeholder)
//             Log.d(TAG, "App in foreground: update UI / play sound")
//         }
//     }

//     private fun isAppInForeground(context: Context): Boolean {
//         val activityManager = context.getSystemService(Context.ACTIVITY_SERVICE) as android.app.ActivityManager
//         val appProcesses = activityManager.runningAppProcesses ?: return false
//         val packageName = context.packageName

//         appProcesses.forEach { processInfo ->
//             if (processInfo.importance == android.app.ActivityManager.RunningAppProcessInfo.IMPORTANCE_FOREGROUND &&
//                 processInfo.processName == packageName
//             ) {
//                 return true
//             }
//         }
//         return false
//     }

//     private fun storeAlarmData(
//         context: Context,
//         prayerName: String,
//         prayerTime: String,
//     ) {
//         val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
//         prefs.edit().apply {
//             putString("flutter.pending_prayer_name", prayerName)
//             putString("flutter.pending_prayer_time", prayerTime)
//             putLong("flutter.pending_prayer_timestamp", System.currentTimeMillis())
//             putBoolean("flutter.has_pending_alarm", true)
//             apply()
//         }
//         Log.d(TAG, "✅ Alarm data stored: $prayerName at $prayerTime")
//     }

//     private fun wakeUpDevice(context: Context) {
//         try {
//             val powerManager = context.getSystemService(Context.POWER_SERVICE) as PowerManager
//             val wakeLock =
//                 powerManager.newWakeLock(
//                     PowerManager.SCREEN_BRIGHT_WAKE_LOCK or
//                         PowerManager.ACQUIRE_CAUSES_WAKEUP or
//                         PowerManager.ON_AFTER_RELEASE,
//                     "$TAG:WakeLock",
//                 )
//             wakeLock.acquire(30000) // 30 seconds
//             Log.d(TAG, "✅ Device screen turned on")
//         } catch (e: Exception) {
//             Log.e(TAG, "❌ Error waking device: ${e.message}")
//         }
//     }

//     private fun showPrayerNotification(
//         context: Context,
//         prayerName: String,
//     ) {
//         val notificationManager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
//         val channelId = "prayer_alarm_channel"

//         if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
//             val channel =
//                 NotificationChannel(
//                     channelId,
//                     "Prayer Alarms",
//                     NotificationManager.IMPORTANCE_HIGH,
//                 ).apply {
//                     description = "Notifications for prayer times"
//                 }
//             notificationManager.createNotificationChannel(channel)
//         }

//         val notification =
//             NotificationCompat
//                 .Builder(context, channelId)
//                 .setSmallIcon(android.R.drawable.ic_lock_idle_alarm)
//                 .setContentTitle("Solat $prayerName masuk")
//                 .setContentText("Ya Allah, jadikan kami orang yang mendirikan solat")
//                 .setPriority(NotificationCompat.PRIORITY_HIGH)
//                 .setCategory(NotificationCompat.CATEGORY_ALARM)
//                 .build()

//         notificationManager.notify(prayerName.hashCode(), notification)
//         Log.d(TAG, "✅ Notification shown for $prayerName")
//     }
// }
