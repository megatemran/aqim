// package net.brings2you.aqim

// import android.app.AlarmManager
// import android.app.PendingIntent
// import android.content.BroadcastReceiver
// import android.content.Context
// import android.content.Intent
// import android.util.Log
// import androidx.glance.appwidget.updateAll
// import androidx.work.WorkManager
// import java.time.LocalTime
// import java.time.ZonedDateTime
// import java.time.format.DateTimeFormatter
// import kotlinx.coroutines.CoroutineScope
// import kotlinx.coroutines.Dispatchers
// import kotlinx.coroutines.launch
// import net.brings2you.aqim.WaktuSolatWorker

// class TESTWaktuSolatWidgetUpdater : BroadcastReceiver() {
//     override fun onReceive(context: Context, intent: Intent?) {
//         Log.d("WaktuSolatWidgetUpdater", "🔔 Prayer time alarm triggered!")

//         CoroutineScope(Dispatchers.IO).launch {
//             try {
//                 // Update widget
//                 WaktuSolatWidget().updateAll(context)
//                 Log.d("WaktuSolatWidgetUpdater", "✅ Widget updated at prayer time")

//                 // Schedule next prayer time update
//                 scheduleNextPrayerTime(context)

//             } catch (e: Exception) {
//                 Log.e("WaktuSolatWidgetUpdater", "❌ Error: ${e.message}", e)
//             }
//         }
//     }

//     companion object {
//         private const val REQUEST_CODE = 54321

//         fun initializeScheduling(context: Context) {
//             Log.d("WaktuSolatWidgetUpdater", "🔄 Initializing prayer time scheduling...")
//             scheduleNextPrayerTime(context)
//         }

//         /**
//          * Update widget immediately (for time/date changes)
//          */
//         fun updateImmediately(context: Context) {
//             Log.d("WaktuSolatWidgetUpdater", "🔄 Updating widget immediately...")
//             CoroutineScope(Dispatchers.IO).launch {
//                 try {
//                     WaktuSolatWidget().updateAll(context)
//                     Log.d("WaktuSolatWidgetUpdater", "✅ Widget updated immediately")
//                 } catch (e: Exception) {
//                     Log.e("WaktuSolatWidgetUpdater", "❌ Error updating widget: ${e.message}", e)
//                 }
//             }
//         }

//         fun scheduleNextPrayerTime(context: Context) {
//             try {
//                 val prefs = context.getSharedPreferences("HomeWidgetPreferences", Context.MODE_PRIVATE)

//                 val subuh = prefs.getString("subuh", "") ?: ""
//                 val zohor = prefs.getString("zohor", "") ?: ""
//                 val asar = prefs.getString("asar", "") ?: ""
//                 val maghrib = prefs.getString("maghrib", "") ?: ""
//                 val isyak = prefs.getString("isyak", "") ?: ""

//                 if (subuh.isEmpty() || zohor.isEmpty()) {
//                     Log.w("WaktuSolatWidgetUpdater", "⚠️ Prayer times not set yet, will retry later")
//                     return
//                 }

//                 val nextUpdateTime = getNextUpdateTime(subuh, zohor, asar, maghrib, isyak)

//                 if (nextUpdateTime == null) {
//                     Log.w("WaktuSolatWidgetUpdater", "⚠️ Could not determine next update time")
//                     return
//                 }

//                 // AlarmManager approach for precise timing
//                 val am = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
//                 val intent = Intent(context, WaktuSolatWidgetUpdater::class.java)
//                 val pendingIntent = PendingIntent.getBroadcast(
//                     context,
//                     REQUEST_CODE,
//                     intent,
//                     PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
//                 )

//                 // Cancel existing alarm
//                 am.cancel(pendingIntent)

//                 // Schedule for next update time
//                 am.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, nextUpdateTime, pendingIntent)

//                 val formatter = DateTimeFormatter.ofPattern("HH:mm")
//                 val nextTime = ZonedDateTime.now().withSecond(0).withNano(0)
//                 val diffMinutes = (nextUpdateTime - System.currentTimeMillis()) / 1000 / 60

//                 Log.d("WaktuSolatWidgetUpdater", "⏱️ AlarmManager: Next update scheduled in $diffMinutes minutes")

//                 // WorkManager approach as fallback for reliability
//                 WaktuSolatWorker.scheduleNextUpdate(context)
//                 Log.d("WaktuSolatWidgetUpdater", "⏱️ WorkManager also scheduled as fallback")

//             } catch (e: Exception) {
//                 Log.e("WaktuSolatWidgetUpdater", "❌ Error scheduling: ${e.message}")
//             }
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
//                     Pair("Subuh", subuhDateTime),
//                     Pair("7:00 AM", sevenAmDateTime),
//                     Pair("Zohor", zohorDateTime),
//                     Pair("Asar", asarDateTime),
//                     Pair("Maghrib", maghribDateTime),
//                     Pair("Isyak", isyakDateTime)
//                 )

//                 // Find first update time that's after now
//                 val nextUpdate = updateTimes.find { it.second.isAfter(now) }

//                 if (nextUpdate != null) {
//                     Log.d("WaktuSolatWidgetUpdater", "🕐 Next widget update: ${nextUpdate.first} at ${nextUpdate.second}")
//                     return nextUpdate.second.toInstant().toEpochMilli()
//                 }

//                 // If no update time left today, schedule for subuh tomorrow
//                 val tomorrowSubuh = subuhDateTime.plusDays(1)
//                 Log.d("WaktuSolatWidgetUpdater", "🕐 Next widget update: Subuh (tomorrow) at $tomorrowSubuh")
//                 return tomorrowSubuh.toInstant().toEpochMilli()

//             } catch (e: Exception) {
//                 Log.e("WaktuSolatWidgetUpdater", "❌ Error calculating next update time: ${e.message}")
//                 null
//             }
//         }
//         private fun parseTimeString(timeStr: String): LocalTime {
//     val cleaned = timeStr.trim().lowercase()
//     val noSpaces = cleaned.replace(" ", "")
//     val withColon = noSpaces.replace(".", ":")
//     val timePart = withColon.replace(Regex("[^0-9:]"), "")

//     return if (timePart.contains(":")) {
//         val (hourStr, minStr) = timePart.split(":")
//         var hour = hourStr.toInt()
//         val minute = minStr.toInt()

//         if (cleaned.contains("pm") && hour != 12) {
//             hour += 12
//         } else if (cleaned.contains("am") && hour == 12) {
//             hour = 0
//         }

//         LocalTime.of(hour, minute)
//     } else {
//         LocalTime.of(timePart.toInt(), 0)
//     }
// }
//     }
// }
