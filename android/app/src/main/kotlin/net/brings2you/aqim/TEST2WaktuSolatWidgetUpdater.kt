// package net.brings2you.aqim

// import android.app.AlarmManager
// import android.app.PendingIntent
// import android.content.BroadcastReceiver
// import android.content.Context
// import android.content.Intent
// import android.util.Log
// import androidx.glance.appwidget.updateAll
// import kotlinx.coroutines.CoroutineScope
// import kotlinx.coroutines.Dispatchers
// import kotlinx.coroutines.launch
// import java.time.LocalTime
// import java.time.ZonedDateTime

// class WaktuSolatWidgetUpdater : BroadcastReceiver() {
//     override fun onReceive(
//         context: Context,
//         intent: Intent?,
//     ) {
//         val pendingResult = goAsync()

//         CoroutineScope(Dispatchers.IO).launch {
//             try {
//                 Log.d("WaktuSolatWidgetUpdater", "🔔 Alarm triggered")

//                 WaktuSolatWidget().updateAll(context)
//                 scheduleNextPrayerTime(context)
//             } catch (e: Exception) {
//                 Log.e("WaktuSolatWidgetUpdater", "❌ Error", e)
//             } finally {
//                 pendingResult.finish()
//             }
//         }
//     }

//     companion object {
//         private const val REQUEST_CODE = 54321

//         fun initializeScheduling(context: Context) {
//             scheduleNextPrayerTime(context)
//         }

//         fun updateImmediately(context: Context) {
//             CoroutineScope(Dispatchers.IO).launch {
//                 try {
//                     WaktuSolatWidget().updateAll(context)
//                     Log.d("WaktuSolatWidgetUpdater", "✅ Widget updated immediately")
//                 } catch (e: Exception) {
//                     Log.e("WaktuSolatWidgetUpdater", "❌ Immediate update failed", e)
//                 }
//             }
//         }

//         fun scheduleNextPrayerTime(context: Context) {
//             val prefs =
//                 context.getSharedPreferences("HomeWidgetPreferences", Context.MODE_PRIVATE)

//             val subuh = prefs.getString("subuh", "") ?: ""
//             val zohor = prefs.getString("zohor", "") ?: ""
//             val asar = prefs.getString("asar", "") ?: ""
//             val maghrib = prefs.getString("maghrib", "") ?: ""
//             val isyak = prefs.getString("isyak", "") ?: ""

//             if (subuh.isEmpty()) return

//             val nextTime =
//                 getNextUpdateTime(subuh, zohor, asar, maghrib, isyak) ?: return

//             val am = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager

//             val intent = Intent(context, WaktuSolatWidgetUpdater::class.java)
//             val pi =
//                 PendingIntent.getBroadcast(
//                     context,
//                     REQUEST_CODE,
//                     intent,
//                     PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
//                 )

//             am.cancel(pi)
//             am.setAlarmClock(
//                 AlarmManager.AlarmClockInfo(nextTime, pi),
//                 pi,
//             )
//         }

//         private fun getNextUpdateTime(
//             subuh: String,
//             zohor: String,
//             asar: String,
//             maghrib: String,
//             isyak: String,
//         ): Long? =
//             try {
//                 val now = ZonedDateTime.now()

//                 val times =
//                     listOf(
//                         parseTimeString(subuh),
//                         LocalTime.of(7, 0),
//                         parseTimeString(zohor),
//                         parseTimeString(asar),
//                         parseTimeString(maghrib),
//                         parseTimeString(isyak),
//                     )

//                 val dateTimes =
//                     times.map {
//                         now
//                             .withHour(it.hour)
//                             .withMinute(it.minute)
//                             .withSecond(0)
//                             .withNano(0)
//                     }

//                 val next =
//                     dateTimes.firstOrNull { it.isAfter(now) }
//                         ?: dateTimes.first().plusDays(1)

//                 next.toInstant().toEpochMilli()
//             } catch (e: Exception) {
//                 null
//             }

//         private fun parseTimeString(timeStr: String): LocalTime {
//             val cleaned = timeStr.trim().lowercase()
//             val timePart =
//                 cleaned.replace(" ", "").replace(".", ":").replace(Regex("[^0-9:]"), "")

//             return if (timePart.contains(":")) {
//                 val (h, m) = timePart.split(":")
//                 var hour = h.toInt()
//                 val min = m.toInt()

//                 if (cleaned.contains("pm") && hour != 12) hour += 12
//                 if (cleaned.contains("am") && hour == 12) hour = 0

//                 LocalTime.of(hour, min)
//             } else {
//                 LocalTime.of(timePart.toInt(), 0)
//             }
//         }
//     }
// }
