package net.brings2you.aqim

import android.app.AlarmManager
import android.app.AlarmManager.AlarmClockInfo
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import android.util.Log
import androidx.work.*
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import java.time.LocalTime
import java.time.ZonedDateTime
import java.util.concurrent.TimeUnit

class AppScheduler(
    private val context: Context,
) {
    companion object {
        private const val TAG = "AppScheduler"

        // Actions untuk AppReceiver integration
        const val ACTION_EXACT_AZAN_PRIMARY = "net.brings2you.aqim.ACTION_EXACT_AZAN_PRIMARY"
        const val ACTION_BACKUP_AZAN_ALARM = "net.brings2you.aqim.ACTION_BACKUP_AZAN_ALARM"

        // Base IDs untuk setiap solat
        const val AM_ID_SUBUH = 1000
        const val AM_ID_ZOHOR = 2000
        const val AM_ID_ASAR = 3000
        const val AM_ID_MAGHRIB = 4000
        const val AM_ID_ISYAK = 5000

        // Layer-specific ID offsets
        private const val LAYER_PRIMARY_OFFSET = 0
        private const val LAYER_BACKUP_OFFSET = 100
        private const val LAYER_RECOVERY_OFFSET = 200
    }

    data class AzanData(
        val prayerName: String,
        val timeMillis: Long,
    )

    /** Schedule the next prayer based on saved times */
    fun scheduleNextPrayerTime() {
        val prefs = context.getSharedPreferences("HomeWidgetPreferences", Context.MODE_PRIVATE)

        val subuh = prefs.getString("subuh", "") ?: ""
        val zohor = prefs.getString("zohor", "") ?: ""
        val asar = prefs.getString("asar", "") ?: ""
        val maghrib = prefs.getString("maghrib", "") ?: ""
        val isyak = prefs.getString("isyak", "") ?: ""

        Log.d(TAG, "📋 Reading prayer times from SharedPreferences:")
        Log.d(TAG, "   Subuh: '$subuh'")
        Log.d(TAG, "   Zohor: '$zohor'")
        Log.d(TAG, "   Asar: '$asar'")
        Log.d(TAG, "   Maghrib: '$maghrib'")
        Log.d(TAG, "   Isyak: '$isyak'")

        if (subuh.isEmpty()) {
            Log.w(TAG, "⚠️ No prayer times found in preferences")
            // Check if maybe times are stored with different keys
            val allPrefs = prefs.all
            Log.d(TAG, "🔍 All SharedPreferences keys: ${allPrefs.keys}")
            return
        }

        val azanData =
            getNextUpdateTime(subuh, zohor, asar, maghrib, isyak) ?: run {
                Log.e(TAG, "❌ Failed to calculate next prayer time")
                return
            }

        Log.i(TAG, "🕌 Scheduling next prayer: ${azanData.prayerName} at ${azanData.timeMillis}")

        // 3-Layer Robust Scheduling
        scheduleRobustAzan(azanData)

        // Schedule reminders melalui AppReceiver
        scheduleBeforeAzanReminders(azanData)
        scheduleSolatReminder(azanData)
    }

    /** 3-LAYER ROBUST SCHEDULING - Core function */
    private fun scheduleRobustAzan(azanData: AzanData) {
        // Layer 1: Primary Exact Alarm (bypass Doze)
        schedulePrimaryExactAlarm(azanData)

        // Layer 2: Backup Alarm Clock (UI visibility)
        scheduleBackupAlarmClock(azanData)

        // Layer 3: Recovery Worker (missed alarm check)
        scheduleRecoveryWorker(azanData)
    }

    /** LAYER 1: Primary Exact Alarm - Bypass Doze Mode */
    private fun schedulePrimaryExactAlarm(azanData: AzanData) {
        try {
            val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager

            // ✅ FIX: Gunakan AppReceiver dengan action yang betul
            val intent =
                Intent(context, AppReceiver::class.java).apply {
                    action = ACTION_EXACT_AZAN_PRIMARY
                    putExtra("prayer_name", azanData.prayerName)
                    putExtra("scheduled_time", azanData.timeMillis)
                    putExtra("layer", "primary_exact")
                }

            val requestCode = getBaseID(azanData.prayerName) + LAYER_PRIMARY_OFFSET

            val pendingIntent =
                PendingIntent.getBroadcast(
                    context,
                    requestCode,
                    intent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
                )

            // Cancel existing first
            alarmManager.cancel(pendingIntent)

            // Use setExactAndAllowWhileIdle for Android M+ (bypasses Doze)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                alarmManager.setExactAndAllowWhileIdle(
                    AlarmManager.RTC_WAKEUP,
                    azanData.timeMillis,
                    pendingIntent,
                )
                Log.d(TAG, "✅ Layer 1 - Exact alarm set for ${azanData.prayerName}")
            } else {
                alarmManager.setExact(
                    AlarmManager.RTC_WAKEUP,
                    azanData.timeMillis,
                    pendingIntent,
                )
                Log.d(TAG, "✅ Layer 1 - Exact alarm set (pre-Marshmallow)")
            }
        } catch (e: Exception) {
            Log.e(TAG, "❌ Layer 1 scheduling failed", e)
        }
    }

    /** LAYER 2: Backup Alarm Clock - UI Visibility & High Priority */
    private fun scheduleBackupAlarmClock(azanData: AzanData) {
        try {
            val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager

            // Intent to show on lock screen
            val showIntent =
                Intent(context, MainActivity::class.java).apply {
                    putExtra("prayer", azanData.prayerName)
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                }

            val showRequestCode = getBaseID(azanData.prayerName) + LAYER_BACKUP_OFFSET

            val showPendingIntent =
                PendingIntent.getActivity(
                    context,
                    showRequestCode,
                    showIntent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
                )

            // Intent to trigger azan
            val triggerIntent =
                Intent(context, AppReceiver::class.java).apply {
                    action = ACTION_BACKUP_AZAN_ALARM
                    putExtra("prayer_name", azanData.prayerName)
                    putExtra("scheduled_time", azanData.timeMillis)
                    putExtra("layer", "backup_alarm_clock")
                }

            val triggerRequestCode = getBaseID(azanData.prayerName) + LAYER_BACKUP_OFFSET + 1

            val triggerPendingIntent =
                PendingIntent.getBroadcast(
                    context,
                    triggerRequestCode,
                    triggerIntent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
                )

            // Cancel existing first
            alarmManager.cancel(triggerPendingIntent)

            // setAlarmClock shows in UI and has high priority
            alarmManager.setAlarmClock(
                AlarmClockInfo(azanData.timeMillis, showPendingIntent),
                triggerPendingIntent,
            )

            Log.d(TAG, "✅ Layer 2 - AlarmClock backup set")
        } catch (e: Exception) {
            Log.e(TAG, "❌ Layer 2 scheduling failed", e)
        }
    }

    /** LAYER 3: Recovery Worker - Check for Missed Alarms */
    private fun scheduleRecoveryWorker(azanData: AzanData) {
        try {
            val checkTime = azanData.timeMillis + (10 * 60 * 1000) // 10 minutes after
            val delay = checkTime - System.currentTimeMillis()

            if (delay <= 0) {
                Log.d(TAG, "⚠️ Recovery check would be in the past, skipping")
                return
            }

            val workRequest =
                OneTimeWorkRequestBuilder<AzanRecoveryWorker>()
                    .setInitialDelay(delay, TimeUnit.MILLISECONDS)
                    .setConstraints(
                        Constraints
                            .Builder()
                            .setRequiredNetworkType(NetworkType.NOT_REQUIRED)
                            .setRequiresBatteryNotLow(false)
                            .setRequiresStorageNotLow(false)
                            .build(),
                    ).setInputData(
                        workDataOf(
                            "prayer_name" to azanData.prayerName,
                            "scheduled_time" to azanData.timeMillis,
                            "check_timestamp" to System.currentTimeMillis(),
                        ),
                    ).addTag("azan_recovery")
                    .addTag("prayer_${azanData.prayerName}")
                    .build()

            WorkManager
                .getInstance(context)
                .enqueueUniqueWork(
                    "recovery_${azanData.prayerName}_${azanData.timeMillis}",
                    ExistingWorkPolicy.REPLACE,
                    workRequest,
                )

            Log.d(TAG, "✅ Layer 3 - Recovery worker scheduled")
        } catch (e: Exception) {
            Log.e(TAG, "❌ Layer 3 scheduling failed", e)
        }
    }

    /** Legacy function (deprecated but kept for compatibility) */
    fun scheduleAzan(azanData: AzanData) {
        Log.w(TAG, "⚠️ Using legacy scheduleAzan, consider using scheduleRobustAzan instead")

        // ✅ FIX: Gunakan AppReceiver
        val am = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val intent =
            Intent(context, AppReceiver::class.java).apply {
                action = AppReceiver.ACTION_APP_SCHEDULER_ALARM
                putExtra("prayer_name", azanData.prayerName)
                putExtra("scheduled_time", azanData.timeMillis)
                putExtra("legacy", true)
            }

        val requestCode = getBaseID(azanData.prayerName)

        val pi =
            PendingIntent.getBroadcast(
                context,
                requestCode,
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
            )

        am.cancel(pi)
        am.setAlarmClock(AlarmManager.AlarmClockInfo(azanData.timeMillis, pi), pi)

        Log.d(TAG, "⏰ Legacy azan alarm for ${azanData.prayerName}")
    }

    /** Schedule reminders before the Azan (5,10,15 min) */
    fun scheduleBeforeAzanReminders(azanData: AzanData) {
        // ✅ FIX: Gunakan function dari PrayerSettings.kt
        val prayerSettings = net.brings2you.aqim.loadPrayerSettingsFromFlutter(context)
        val settings = prayerSettings[azanData.prayerName.lowercase()] ?: return

        if (settings.beforeAzanReminder.isEmpty()) return

        val baseID = getBaseID(azanData.prayerName)

        settings.beforeAzanReminder.forEach { minutesBefore ->
            // ✅ FIX: Schedule menggunakan AppReceiver
            AppReceiver.scheduleAppAlarm(
                context,
                azanData.prayerName,
                getPrayerTimeString(azanData.prayerName),
                -minutesBefore, // Negative offset untuk before-azan
            )

            Log.d(TAG, "⏰ Reminder for ${azanData.prayerName} $minutesBefore min before scheduled")
        }
    }

    /** Schedule reminder after Azan */
    fun scheduleSolatReminder(azanData: AzanData) {
        // ✅ FIX: Gunakan function dari PrayerSettings.kt
        val prayerSettings = net.brings2you.aqim.loadPrayerSettingsFromFlutter(context)
        val settings = prayerSettings[azanData.prayerName.lowercase()] ?: return

        if (settings.solatReminder <= 0) return

        // ✅ FIX: Schedule menggunakan AppReceiver
        AppReceiver.scheduleAppAlarm(
            context,
            azanData.prayerName,
            getPrayerTimeString(azanData.prayerName),
            settings.solatReminder, // Positive offset untuk after-azan
        )

        Log.d(TAG, "⏰ Solat reminder for ${azanData.prayerName} scheduled (${settings.solatReminder} min after)")
    }

    /** Helper untuk dapatkan prayer time string */
    private fun getPrayerTimeString(prayerName: String): String {
        val prefs = context.getSharedPreferences("HomeWidgetPreferences", Context.MODE_PRIVATE)
        return prefs.getString(prayerName.lowercase(), "") ?: ""
    }

    /** Cancel all alarms including all layers */
    fun cancelAllAlarms() {
        try {
            Log.d(TAG, "🚫 Cancelling ALL alarms for all prayers")

            // Cancel primary layer alarms melalui AppReceiver
            listOf("subuh", "zohor", "asar", "maghrib", "isyak").forEach { prayer ->
                val baseId = getBaseID(prayer)

                // Cancel semua variations untuk prayer ini
                listOf(
                    baseId + LAYER_PRIMARY_OFFSET,
                    baseId + LAYER_BACKUP_OFFSET,
                    baseId + LAYER_BACKUP_OFFSET + 1,
                ).forEach { requestCode ->
                    val intent = Intent(context, AppReceiver::class.java)
                    val pi =
                        PendingIntent.getBroadcast(
                            context,
                            requestCode,
                            intent,
                            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
                        )
                    val am = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
                    am.cancel(pi)
                }
            }

            // Cancel semua WorkManager workers
            WorkManager.getInstance(context).cancelAllWorkByTag("azan_recovery")

            Log.d(TAG, "✅ All alarms and workers cancelled")
        } catch (e: Exception) {
            Log.e(TAG, "❌ Error cancelling alarms", e)
        }
    }

    /** Reschedule all prayers */
    fun rescheduleAllPrayers() {
        Log.i(TAG, "🔄 Rescheduling all prayers")
        cancelAllAlarms()
        scheduleNextPrayerTime()
    }

    /** Check if exact alarm permission is available (Android 12+) */
    fun canScheduleExactAlarms(): Boolean =
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
            alarmManager.canScheduleExactAlarms()
        } else {
            true // Below Android 12, always true
        }

    /** Request exact alarm permission (Android 12+) */
    private fun requestExactAlarmPermission() {
        try {
            // Check jika kita berada pada Android 12+
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                // Gunakan reflection atau version check untuk elakkan compile error
                try {
                    // Cara 1: Gunakan string constant (avoid compile-time check)
                    val actionName =
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                            "android.app.action.REQUEST_SCHEDULE_EXACT_ALARM"
                        } else {
                            null
                        }

                    if (actionName != null) {
                        val intent = Intent(actionName)
                        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        context.startActivity(intent)
                        Log.d(TAG, "📋 Requested exact alarm permission via action string")
                    }
                } catch (e: NoSuchFieldError) {
                    // Fallback untuk device yang tidak support
                    Log.w(TAG, "⚠️ Device doesn't support REQUEST_SCHEDULE_EXACT_ALARM")
                    openAppSettingsAsFallback()
                }
            } else {
                // Android <12: Direct ke app settings
                Log.d(TAG, "📋 Android <12: Directing to app settings")
                openAppSettingsAsFallback()
            }
        } catch (e: Exception) {
            Log.e(TAG, "❌ Error requesting alarm permission", e)
        }
    }

    /** Fallback: Open app settings */
    private fun openAppSettingsAsFallback() {
        try {
            val intent = Intent(android.provider.Settings.ACTION_APPLICATION_DETAILS_SETTINGS)
            intent.data = android.net.Uri.parse("package:${context.packageName}")
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            context.startActivity(intent)
            Log.d(TAG, "⚙️ Opened app settings as fallback")
        } catch (e: Exception) {
            Log.e(TAG, "❌ Failed to open app settings", e)
        }
    }

    fun getBaseID(prayerName: String): Int =
        when (prayerName.lowercase()) {
            "subuh" -> AM_ID_SUBUH
            "zohor" -> AM_ID_ZOHOR
            "asar" -> AM_ID_ASAR
            "maghrib" -> AM_ID_MAGHRIB
            "isyak" -> AM_ID_ISYAK
            else -> 9999
        }

    /** Compute next Azan time from saved prayer times */
    fun getNextUpdateTime(
        subuh: String,
        zohor: String,
        asar: String,
        maghrib: String,
        isyak: String,
    ): AzanData? {
        return try {
            val now = ZonedDateTime.now()

            Log.d(TAG, "📊 Calculating next prayer time:")
            Log.d(TAG, "   Now: $now")
            Log.d(TAG, "   Subuh: $subuh")
            Log.d(TAG, "   Zohor: $zohor")
            Log.d(TAG, "   Asar: $asar")
            Log.d(TAG, "   Maghrib: $maghrib")
            Log.d(TAG, "   Isyak: $isyak")

            // Parse semua waktu solat
            val prayerTimes =
                listOf(
                    "subuh" to parseTimeString(subuh),
                    "zohor" to parseTimeString(zohor),
                    "asar" to parseTimeString(asar),
                    "maghrib" to parseTimeString(maghrib),
                    "isyak" to parseTimeString(isyak),
                )

            // Cari waktu solat yang akan datang
            var nextPrayer: Pair<String, ZonedDateTime>? = null

            prayerTimes.forEach { (prayerName, prayerTime) ->
                val prayerDateTime =
                    now
                        .withHour(prayerTime.hour)
                        .withMinute(prayerTime.minute)
                        .withSecond(0)
                        .withNano(0)

                Log.d(TAG, "   $prayerName: $prayerDateTime")

                // Jika waktu sudah lewat hari ini, tambah 1 hari
                val adjustedDateTime =
                    if (prayerDateTime.isBefore(now)) {
                        prayerDateTime.plusDays(1)
                    } else {
                        prayerDateTime
                    }

                // Pilih yang paling awal
                if (nextPrayer == null || adjustedDateTime.isBefore(nextPrayer!!.second)) {
                    nextPrayer = prayerName to adjustedDateTime
                }
            }

            if (nextPrayer != null) {
                val (prayerName, nextTime) = nextPrayer!!
                Log.d(TAG, "✅ Next prayer: $prayerName at $nextTime")
                return AzanData(prayerName, nextTime.toInstant().toEpochMilli())
            } else {
                Log.e(TAG, "❌ No prayer times found")
                return null
            }
        } catch (e: Exception) {
            Log.e(TAG, "❌ Error calculating next prayer time: ${e.message}", e)
            return null
        }
    }

    /** Improved time parsing with better error handling */

    /** Improved time parsing with AM/PM support */
    private fun parseTimeString(timeStr: String): LocalTime =
        try {
            val trimmed = timeStr.trim()
            if (trimmed.isEmpty()) {
                throw IllegalArgumentException("Empty time string")
            }

            // Support formats: "5.39 am", "12.03 pm", "HH:mm", "H:mm"
            var cleanTime = trimmed.lowercase()

            // Handle AM/PM
            var isPM = false
            if (cleanTime.contains("pm")) {
                isPM = true
                cleanTime = cleanTime.replace("pm", "").trim()
            } else if (cleanTime.contains("am")) {
                cleanTime = cleanTime.replace("am", "").trim()
            }

            // Replace dots with colons
            cleanTime = cleanTime.replace(".", ":")

            val parts = cleanTime.split(":")

            if (parts.size < 2) {
                throw IllegalArgumentException("Invalid time format: $trimmed")
            }

            var hour = parts[0].toInt()
            val minute = parts[1].toInt()

            // Convert 12-hour to 24-hour format
            if (isPM && hour < 12) {
                hour += 12
            } else if (!isPM && hour == 12) {
                // 12 am is midnight
                hour = 0
            }

            LocalTime.of(hour, minute)
        } catch (e: Exception) {
            Log.e(TAG, "❌ Error parsing time '$timeStr': ${e.message}")
            // Default to 00:00 if parsing fails
            LocalTime.of(0, 0)
        }
}

/** Recovery Worker class */
class AzanRecoveryWorker(
    private val context: Context,
    params: WorkerParameters,
) : CoroutineWorker(context, params) {
    override suspend fun doWork(): Result {
        val prayerName = inputData.getString("prayer_name") ?: return Result.success()
        val scheduledTime = inputData.getLong("scheduled_time", 0)

        Log.d(TAG, "🔍 Recovery worker checking for $prayerName")

        // Always reschedule next prayer
        AppScheduler(context).scheduleNextPrayerTime()

        return Result.success()
    }

    companion object {
        private const val TAG = "AzanRecoveryWorker"
    }
}
