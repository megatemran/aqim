// package net.brings2you.aqim

// import android.content.Context
// import android.util.Log
// import androidx.glance.appwidget.updateAll
// import androidx.work.*
// import java.time.LocalTime
// import java.time.ZonedDateTime
// import java.time.format.DateTimeFormatter
// import java.util.concurrent.TimeUnit

// class TESTWaktuSolatWorker(context: Context, params: WorkerParameters) : CoroutineWorker(context, params) {
//     override suspend fun doWork(): Result {
//         return try {
//             Log.d("WaktuSolatWorker", "🔄 Updating prayer times widget via WorkManager...")

//             val context = applicationContext

//             // Update widget
//             WaktuSolatWidget().updateAll(context)
//             Log.d("WaktuSolatWorker", "✅ Prayer times widget updated")

//             // Schedule next update
//             scheduleNextUpdate(context)

//             Result.success()
//         } catch (e: Exception) {
//             Log.e("WaktuSolatWorker", "❌ Error: ${e.message}", e)
//             Result.retry()
//         }
//     }

//     companion object {
//         private const val WORK_TAG = "prayer_time_widget_update"

//         fun scheduleNextUpdate(context: Context) {
//             try {
//                 val prefs = context.getSharedPreferences("HomeWidgetPreferences", Context.MODE_PRIVATE)

//                 val subuh = prefs.getString("subuh", "") ?: ""
//                 val zohor = prefs.getString("zohor", "") ?: ""
//                 val asar = prefs.getString("asar", "") ?: ""
//                 val maghrib = prefs.getString("maghrib", "") ?: ""
//                 val isyak = prefs.getString("isyak", "") ?: ""

//                 if (subuh.isEmpty() || zohor.isEmpty()) {
//                     Log.w("WaktuSolatWorker", "⚠️ Prayer times not set, scheduling generic check in 5 minutes")
//                     scheduleGenericUpdate(context)
//                     return
//                 }

//                 val nextUpdateTime = getNextUpdateTime(subuh, zohor, asar, maghrib, isyak)

//                 if (nextUpdateTime == null) {
//                     Log.w("WaktuSolatWorker", "⚠️ Could not determine next update time")
//                     scheduleGenericUpdate(context)
//                     return
//                 }

//                 val diffMinutes = (nextUpdateTime - System.currentTimeMillis()) / 1000 / 60
//                 val delayMinutes = if (diffMinutes > 0) diffMinutes else 5

//                 Log.d("WaktuSolatWorker", "⏱️ Next widget update scheduled in $delayMinutes minutes")

//                 val updateRequest = OneTimeWorkRequestBuilder<WaktuSolatWorker>()
//                     .setInitialDelay(delayMinutes, TimeUnit.MINUTES)
//                     .addTag(WORK_TAG)
//                     .build()

//                 WorkManager.getInstance(context).enqueueUniqueWork(
//                     WORK_TAG,
//                     ExistingWorkPolicy.REPLACE,
//                     updateRequest
//                 )
//             } catch (e: Exception) {
//                 Log.e("WaktuSolatWorker", "❌ Error scheduling: ${e.message}")
//                 scheduleGenericUpdate(context)
//             }
//         }

//         private fun scheduleGenericUpdate(context: Context) {
//             val updateRequest = OneTimeWorkRequestBuilder<WaktuSolatWorker>()
//                 .setInitialDelay(5, TimeUnit.MINUTES)
//                 .addTag(WORK_TAG)
//                 .build()

//             WorkManager.getInstance(context).enqueueUniqueWork(
//                 WORK_TAG,
//                 ExistingWorkPolicy.REPLACE,
//                 updateRequest
//             )
//             Log.d("WaktuSolatWorker", "⏱️ Generic update scheduled in 5 minutes")
//         }

//         private fun getNextUpdateTime(
//             subuh: String,
//             zohor: String,
//             asar: String,
//             maghrib: String,
//             isyak: String
//         ): Long? {
//             return try {
//                 val now = ZonedDateTime.now()

//                 val subuhTime = parseTimeString(subuh)
//                 val zohorTime = parseTimeString(zohor)
//                 val asarTime = parseTimeString(asar)
//                 val maghribTime = parseTimeString(maghrib)
//                 val isyakTime = parseTimeString(isyak)

//                 // Create ZonedDateTime for each update time today
//                 // 6 update times: Subuh, 7 AM, Zohor, Asar, Maghrib, Isyak
//                 val subuhDateTime = now.withHour(subuhTime.hour).withMinute(subuhTime.minute).withSecond(0).withNano(0)
//                 val sevenAmDateTime = now.withHour(7).withMinute(0).withSecond(0).withNano(0)
//                 val zohorDateTime = now.withHour(zohorTime.hour).withMinute(zohorTime.minute).withSecond(0).withNano(0)
//                 val asarDateTime = now.withHour(asarTime.hour).withMinute(asarTime.minute).withSecond(0).withNano(0)
//                 val maghribDateTime = now.withHour(maghribTime.hour).withMinute(maghribTime.minute).withSecond(0).withNano(0)
//                 val isyakDateTime = now.withHour(isyakTime.hour).withMinute(isyakTime.minute).withSecond(0).withNano(0)

//                 // All update times (5 prayers + 7 AM transition)
//                 val updateTimes = listOf(
//                     subuhDateTime,
//                     sevenAmDateTime,
//                     zohorDateTime,
//                     asarDateTime,
//                     maghribDateTime,
//                     isyakDateTime
//                 )

//                 // Find first update time that's after now
//                 val nextUpdate = updateTimes.find { it.isAfter(now) }

//                 return if (nextUpdate != null) {
//                     Log.d("WaktuSolatWorker", "🕐 Next widget update at: $nextUpdate")
//                     nextUpdate.toInstant().toEpochMilli()
//                 } else {
//                     val tomorrowSubuh = subuhDateTime.plusDays(1)
//                     Log.d("WaktuSolatWorker", "🕐 Next widget update: Subuh (tomorrow) at $tomorrowSubuh")
//                     tomorrowSubuh.toInstant().toEpochMilli()
//                 }

//             } catch (e: Exception) {
//                 Log.e("WaktuSolatWorker", "❌ Error calculating next update time: ${e.message}")
//                 null
//             }
//         }
//         private fun parseTimeString(timeStr: String): LocalTime {
//             val cleaned = timeStr.trim().lowercase()
//             val noSpaces = cleaned.replace(" ", "")
//             val withColon = noSpaces.replace(".", ":")
//             val timePart = withColon.replace(Regex("[^0-9:]"), "")

//             return if (timePart.contains(":")) {
//                 val (hourStr, minStr) = timePart.split(":")
//                 var hour = hourStr.toInt()
//                 val minute = minStr.toInt()

//                 if (cleaned.contains("pm") && hour != 12) {
//                     hour += 12
//                 } else if (cleaned.contains("am") && hour == 12) {
//                     hour = 0
//                 }

//                 LocalTime.of(hour, minute)
//             } else {
//                 LocalTime.of(timePart.toInt(), 0)
//             }
//         }
//     }
// }
