package net.brings2you.aqim

import android.content.Context
import android.util.Log
import org.json.JSONArray
import org.json.JSONObject

data class PrayerSettings(
    val enabled: Boolean,
    val sound: String,
    val vibrate: Boolean,
    val led: Boolean,
    val fullscreen: Boolean,
    val reminder5Min: Boolean,
    val reminder10Min: Boolean,
    val reminder15Min: Boolean,
    val beforeAzanReminder: List<Int>,
    val solatReminder: Int,
)

fun loadPrayerSettingsFromFlutter(context: Context): Map<String, PrayerSettings> {
    val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
    val jsonString = prefs.getString("prayerSettings", null) ?: return emptyMap()

    val result = mutableMapOf<String, PrayerSettings>()
    try {
        val root = JSONObject(jsonString)
        root.keys().forEach { prayerName ->
            val prayerJson = root.getJSONObject(prayerName)
            val beforeAzanList = mutableListOf<Int>()
            if (prayerJson.has("beforeAzanReminder")) {
                val arr = prayerJson.getJSONArray("beforeAzanReminder")
                for (i in 0 until arr.length()) {
                    beforeAzanList.add(arr.getInt(i))
                }
            }
            val prayer =
                PrayerSettings(
                    enabled = prayerJson.optBoolean("enabled", true),
                    sound = prayerJson.optString("sound", ""),
                    vibrate = prayerJson.optBoolean("vibrate", true),
                    led = prayerJson.optBoolean("led", true),
                    fullscreen = prayerJson.optBoolean("fullscreen", true),
                    reminder5Min = prayerJson.optBoolean("reminder5Min", false),
                    reminder10Min = prayerJson.optBoolean("reminder10Min", false),
                    reminder15Min = prayerJson.optBoolean("reminder15Min", false),
                    beforeAzanReminder = beforeAzanList,
                    solatReminder = prayerJson.optInt("solatReminder", 5),
                )
            result[prayerName] = prayer
        }
    } catch (e: Exception) {
        Log.e("PrayerSettings", "Failed to parse prayerSettings JSON", e)
    }

    return result
}
