package net.brings2you.aqim

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Base64
import android.util.Log
import androidx.glance.appwidget.updateAll
import androidx.work.WorkManager
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import org.json.JSONArray
import org.json.JSONObject
import java.net.URL
import java.util.concurrent.TimeUnit
import kotlin.random.Random

class DoaWidgetUpdater : BroadcastReceiver() {
    override fun onReceive(
        context: Context,
        intent: Intent?,
    ) {
        Log.d("DoaWidgetUpdater", "🔔 Update triggered: ${intent?.action}")

        CoroutineScope(Dispatchers.IO).launch {
            try {
                val prefs = context.getSharedPreferences("doa_prefs", Context.MODE_PRIVATE)
                val lastApiCallTime = prefs.getLong("last_api_call", 0)
                val currentTime = System.currentTimeMillis()

                // Only fetch from API if cache is older than 24 hours
                val dayInMillis = TimeUnit.DAYS.toMillis(1)
                if (currentTime - lastApiCallTime > dayInMillis) {
                    Log.d("DoaWidgetUpdater", "📡 Fetching duas from API (cache expired)")
                    fetchAndCacheDuas(context)
                } else {
                    val minutesOld = ((currentTime - lastApiCallTime) / 1000 / 60)
                    Log.d("DoaWidgetUpdater", "💾 Using cached duas ($minutesOld min old)")
                }

                // Update widget from cache
                updateWidgetFromCache(context)
            } catch (e: Exception) {
                Log.e("DoaWidgetUpdater", "❌ Error: ${e.message}", e)
            }
        }

        // Reschedule next update (for both AlarmManager and WorkManager)
        schedule(context)
    }

    private fun fetchAndCacheDuas(context: Context) {
        try {
            val url = "https://api.github.com/repos/megatemran/aqim/contents/duas_all.json?ref=main"

            val response = URL(url).readText()
            val json = JSONObject(response)
            val base64 = json.getString("content").replace("\n", "")
            val decoded = String(Base64.decode(base64, Base64.DEFAULT))
            val jsonArray = JSONArray(decoded)

            Log.d("DoaWidgetUpdater", "✅ Loaded ${jsonArray.length()} duas from API")

            // Save entire cache to SharedPreferences
            val prefs = context.getSharedPreferences("doa_prefs", Context.MODE_PRIVATE)
            prefs.edit().apply {
                putString("duas_cache", decoded)
                putLong("last_api_call", System.currentTimeMillis())
                apply()
            }

            Log.d("DoaWidgetUpdater", "💾 Cached ${jsonArray.length()} duas to local storage")
        } catch (e: Exception) {
            Log.e("DoaWidgetUpdater", "❌ Failed to fetch from API: ${e.message}", e)
        }
    }

    private suspend fun updateWidgetFromCache(context: Context) {
        try {
            val prefs = context.getSharedPreferences("doa_prefs", Context.MODE_PRIVATE)

            // Get cached duas
            val cachedJson = prefs.getString("duas_cache", null)
            if (cachedJson == null) {
                Log.w("DoaWidgetUpdater", "⚠️ No cache found, fetching from API...")
                fetchAndCacheDuas(context)
                val retryCache = prefs.getString("duas_cache", null)
                if (retryCache != null) {
                    updateWidgetFromCache(context)
                }
                return
            }

            val jsonArray = JSONArray(cachedJson)

            // Get random doa from cache
            val random = Random.nextInt(jsonArray.length())
            val doa = jsonArray.getJSONObject(random)

            // Extract fields
            val arabic = doa.optString("arabic", "اللّهُمَّ اجْعَلْنِي مِنَ التَّوَّابِينَ")

            var titleMs = ""
            if (doa.has("title")) {
                val titleObj = doa.optJSONObject("title")
                if (titleObj != null) {
                    titleMs = titleObj.optString("ms", "") ?: titleObj.optString("en", "")
                } else {
                    titleMs = doa.optString("title", "")
                }
            }
            if (titleMs.isEmpty()) {
                titleMs = "Doa Harian"
            }

            var ms = ""
            if (doa.has("translation")) {
                val translationObj = doa.optJSONObject("translation")
                if (translationObj != null) {
                    ms = translationObj.optString("ms", "") ?: translationObj.optString("en", "")
                } else {
                    ms = doa.optString("translation", "")
                }
            }
            if (ms.isEmpty()) {
                ms = "Ya Allah, jadikan aku daripada orang yang bertaubat."
            }

            val ref = doa.optString("source", "—")

            Log.d("DoaWidgetUpdater", "🏷️ Title MS: $titleMs")

            // Save current doa to SharedPreferences
            prefs.edit().apply {
                putString("arabic", arabic)
                putString("title_ms", titleMs)
                putString("ms", ms)
                putString("ref", ref)
                putLong("last_update", System.currentTimeMillis())
                apply()
            }

            // Update widget
            DoaWidget().updateAll(context)
            Log.d("DoaWidgetUpdater", "✅ Widget updated: $titleMs")
        } catch (e: Exception) {
            Log.e("DoaWidgetUpdater", "❌ Error updating widget: ${e.message}", e)
        }
    }

    companion object {
        private const val REQUEST_CODE = 12345
        private const val INTERVAL_MINUTES = 15

        fun schedule(context: Context) {
            try {
                // AlarmManager approach for precise timing
                val am = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
                val intent =
                    Intent(context, DoaWidgetUpdater::class.java).apply {
                        action = "net.brings2you.aqim.UPDATE_DOA_WIDGET"
                    }
                val pendingIntent =
                    PendingIntent.getBroadcast(
                        context,
                        REQUEST_CODE,
                        intent,
                        PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
                    )

                am.cancel(pendingIntent)
                val triggerTime = System.currentTimeMillis() + (INTERVAL_MINUTES * 60 * 1000)
                am.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, triggerTime, pendingIntent)

                Log.d("DoaWidgetUpdater", "⏱️ AlarmManager scheduled in $INTERVAL_MINUTES minute(s)")

                // WorkManager approach as fallback for reliability
                DoaWidgetWorker.scheduleNextUpdate(context)
                Log.d("DoaWidgetUpdater", "⏱️ WorkManager also scheduled")
            } catch (e: Exception) {
                Log.e("DoaWidgetUpdater", "❌ Error scheduling: ${e.message}")
            }
        }
    }
}
