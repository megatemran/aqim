package net.brings2you.aqim

import android.content.Context
import android.util.Log
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.glance.*
import androidx.glance.action.actionStartActivity
import androidx.glance.action.clickable
import androidx.glance.appwidget.GlanceAppWidget
import androidx.glance.appwidget.SizeMode
import androidx.glance.appwidget.provideContent
import androidx.glance.layout.*
import androidx.glance.text.FontWeight
import androidx.glance.text.Text
import androidx.glance.text.TextAlign
import androidx.glance.text.TextStyle
import androidx.glance.unit.ColorProvider
import java.time.LocalTime

class WaktuSolatWidget : GlanceAppWidget() {
    override val sizeMode: SizeMode = SizeMode.Single

    override suspend fun provideGlance(
        context: Context,
        id: GlanceId,
    ) {
        Log.d("WaktuSolatWidget", "🟢 provideGlance called")
        provideContent { PrayerTime(context) }
    }

    @Composable
    private fun PrayerTime(context: Context) {
        val prefs =
            context.getSharedPreferences("HomeWidgetPreferences", Context.MODE_PRIVATE)

        val location = prefs.getString("location", "Unknown") ?: "Unknown"
        val subuh = prefs.getString("subuh", "-") ?: "-"
        val zohor = prefs.getString("zohor", "-") ?: "-"
        val asar = prefs.getString("asar", "-") ?: "-"
        val maghrib = prefs.getString("maghrib", "-") ?: "-"
        val isyak = prefs.getString("isyak", "-") ?: "-"
        val lastUpdate = prefs.getString("last_update", "-") ?: "-"

        Log.d("WaktuSolatWidget", "✅ Loaded: $location - Subuh: $subuh")

        // Get current prayer time
        val currentPrayer = getCurrentPrayerTime(subuh, zohor, asar, maghrib, isyak)
        Log.d("WaktuSolatWidget", "🕐 Current prayer time: $currentPrayer")

        WidgetContent(
            location = location,
            subuh = subuh,
            zohor = zohor,
            asar = asar,
            maghrib = maghrib,
            isyak = isyak,
            lastUpdate = lastUpdate,
            currentPrayer = currentPrayer,
        )
    }

    @Composable
    fun WidgetContent(
        location: String,
        subuh: String,
        zohor: String,
        asar: String,
        maghrib: String,
        isyak: String,
        lastUpdate: String,
        currentPrayer: String,
    ) {
        Column(
            modifier =
                GlanceModifier
                    .fillMaxSize()
                    .background(ColorProvider(Color(0x4D000000)))
                    .padding(12.dp)
                    .clickable(actionStartActivity<MainActivity>()),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Text(
                text = "Waktu Solat",
                style =
                    TextStyle(
                        color = ColorProvider(Color.White),
                        fontSize = 17.sp,
                        fontWeight = FontWeight.Bold,
                        textAlign = TextAlign.Center,
                    ),
                modifier = GlanceModifier.fillMaxWidth(),
            )

            Spacer(modifier = GlanceModifier.size(8.dp))

            // Highlight based on current prayer time
            PrayerTimeRow("Subuh", subuh, isHighlighted = currentPrayer == "subuh")
            PrayerTimeRow("Zohor", zohor, isHighlighted = currentPrayer == "zohor")
            PrayerTimeRow("Asar", asar, isHighlighted = currentPrayer == "asar")
            PrayerTimeRow("Maghrib", maghrib, isHighlighted = currentPrayer == "maghrib")
            PrayerTimeRow("Isyak", isyak, isHighlighted = currentPrayer == "isyak")

            Spacer(modifier = GlanceModifier.size(8.dp))

            Text(
                text = location,
                style =
                    TextStyle(
                        color = ColorProvider(Color.White),
                        fontSize = 11.sp,
                        textAlign = TextAlign.Center,
                        fontWeight = FontWeight.Bold,
                    ),
                modifier = GlanceModifier.fillMaxWidth(),
            )
            Text(
                text = "(Updated: $lastUpdate)",
                style =
                    TextStyle(
                        color = ColorProvider(Color.White),
                        fontSize = 9.sp,
                        textAlign = TextAlign.Center,
                    ),
                modifier = GlanceModifier.fillMaxWidth().padding(top = 2.dp),
            )
        }
    }

    @Composable
    fun PrayerTimeRow(
        name: String,
        time: String,
        isHighlighted: Boolean = false,
    ) {
        val textColor = if (isHighlighted) Color.Yellow else Color.White

        Row(
            modifier =
                GlanceModifier
                    .fillMaxWidth()
                    .padding(vertical = 4.dp, horizontal = 4.dp),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Text(
                text = name,
                style =
                    TextStyle(
                        color = ColorProvider(textColor),
                        fontSize = 14.sp,
                        fontWeight = if (isHighlighted) FontWeight.Bold else FontWeight.Normal,
                    ),
                modifier = GlanceModifier.defaultWeight(),
            )

            Text(
                text = time,
                style =
                    TextStyle(
                        color = ColorProvider(textColor),
                        fontSize = 14.sp,
                        textAlign = TextAlign.End,
                        fontWeight = if (isHighlighted) FontWeight.Bold else FontWeight.Normal,
                    ),
            )
        }
    }

    private fun parseTimeString(timeStr: String): LocalTime {
        // Handle formats like "5.55 am", "5:55 am", "5.55", "5:55", "13:05", "1:05 pm"
        val cleaned = timeStr.trim().lowercase()

        // Remove spaces
        val noSpaces = cleaned.replace(" ", "")

        // Replace dot with colon if needed
        val withColon = noSpaces.replace(".", ":")

        // Extract hour and minute
        val timePart = withColon.replace(Regex("[^0-9:]"), "")

        return if (timePart.contains(":")) {
            val (hourStr, minStr) = timePart.split(":")
            var hour = hourStr.toInt()
            val minute = minStr.toInt()

            // Convert to 24-hour if it has pm
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

    private fun getCurrentPrayerTime(
        subuh: String,
        zohor: String,
        asar: String,
        maghrib: String,
        isyak: String,
    ): String =
        try {
            val now = LocalTime.now()

            val subuhTime = parseTimeString(subuh)
            val zohorTime = parseTimeString(zohor)
            val asarTime = parseTimeString(asar)
            val maghribTime = parseTimeString(maghrib)
            val isyakTime = parseTimeString(isyak)

            val sevenAM = LocalTime.of(7, 0)

            Log.d("WaktuSolatWidget", "🕐 Current time: $now")
            Log.d("WaktuSolatWidget", "  Subuh: $subuhTime, Zohor: $zohorTime, Asar: $asarTime, Maghrib: $maghribTime, Isyak: $isyakTime")

            when {
                // Subuh: from subuh time until 7 AM
                now >= subuhTime && now < sevenAM -> {
                    Log.d("WaktuSolatWidget", "✅ Currently in SUBUH time")
                    "subuh"
                }

                // Zohor: from 7 AM until zohor time
                now >= sevenAM && now < zohorTime -> {
                    Log.d("WaktuSolatWidget", "✅ Before prayer time")
                    "none"
                }

                // Zohor: from zohor until asar
                now >= zohorTime && now < asarTime -> {
                    Log.d("WaktuSolatWidget", "✅ Currently in ZOHOR time")
                    "zohor"
                }

                // Asar: from asar until maghrib
                now >= asarTime && now < maghribTime -> {
                    Log.d("WaktuSolatWidget", "✅ Currently in ASAR time")
                    "asar"
                }

                // Maghrib: from maghrib until isyak
                now >= maghribTime && now < isyakTime -> {
                    Log.d("WaktuSolatWidget", "✅ Currently in MAGHRIB time")
                    "maghrib"
                }

                // Isyak: from isyak until subuh (next day)
                now >= isyakTime -> {
                    Log.d("WaktuSolatWidget", "✅ Currently in ISYAK time")
                    "isyak"
                }

                // Before subuh (between previous subuh and current subuh)
                now < subuhTime -> {
                    Log.d("WaktuSolatWidget", "✅ Currently in ISYAK time (before subuh)")
                    "isyak"
                }

                else -> {
                    Log.d("WaktuSolatWidget", "⚠️ No matching prayer time")
                    "none"
                }
            }
        } catch (e: Exception) {
            Log.e("WaktuSolatWidget", "❌ Error parsing time: ${e.message}")
            "none"
        }
}
