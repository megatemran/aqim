package net.brings2you.aqim

import android.content.Context
import android.util.Base64
import android.util.Log
import androidx.glance.appwidget.updateAll
import androidx.work.*
import java.net.URL
import java.util.concurrent.TimeUnit
import kotlin.random.Random
import org.json.JSONArray
import org.json.JSONObject

class DoaWidgetWorker(context: Context, params: WorkerParameters) : CoroutineWorker(context, params) {
    override suspend fun doWork(): Result {
        return try {
            Log.d("DoaWidgetWorker", "🔄 Updating Doa widget via WorkManager...")
            
            val context = applicationContext
            val prefs = context.getSharedPreferences("doa_prefs", Context.MODE_PRIVATE)
            val lastApiCallTime = prefs.getLong("last_api_call", 0)
            val currentTime = System.currentTimeMillis()
            
            // Only fetch from API if cache is older than 24 hours
            val dayInMillis = TimeUnit.DAYS.toMillis(1)
            if (currentTime - lastApiCallTime > dayInMillis) {
                Log.d("DoaWidgetWorker", "📡 Fetching duas from API (cache expired)")
                fetchAndCacheDuas(context)
            } else {
                val minutesOld = ((currentTime - lastApiCallTime) / 1000 / 60)
                Log.d("DoaWidgetWorker", "💾 Using cached duas ($minutesOld min old)")
            }
            
            // Update widget from cache
            updateWidgetFromCache(context)
            
            // Schedule next update
            scheduleNextUpdate(context)
            
            Result.success()
        } catch (e: Exception) {
            Log.e("DoaWidgetWorker", "❌ Error: ${e.message}", e)
            Result.retry()
        }
    }

    private fun fetchAndCacheDuas(context: Context) {
        try {
            val url = "https://api.github.com/repos/megatemran/aqim/contents/duas_all.json?ref=main"
            
            val response = URL(url).readText()
            val json = JSONObject(response)
            val base64 = json.getString("content").replace("\n", "")
            val decoded = String(Base64.decode(base64, Base64.DEFAULT))
            val jsonArray = JSONArray(decoded)

            Log.d("DoaWidgetWorker", "✅ Loaded ${jsonArray.length()} duas from API")

            // Save entire cache to SharedPreferences
            val prefs = context.getSharedPreferences("doa_prefs", Context.MODE_PRIVATE)
            prefs.edit().apply {
                putString("duas_cache", decoded)
                putLong("last_api_call", System.currentTimeMillis())
                apply()
            }
            
            Log.d("DoaWidgetWorker", "💾 Cached ${jsonArray.length()} duas to local storage")
            
        } catch (e: Exception) {
            Log.e("DoaWidgetWorker", "❌ Failed to fetch from API: ${e.message}", e)
        }
    }

    private suspend fun updateWidgetFromCache(context: Context) {
        try {
            val prefs = context.getSharedPreferences("doa_prefs", Context.MODE_PRIVATE)
            
            // Get cached duas
            val cachedJson = prefs.getString("duas_cache", null)
            if (cachedJson == null) {
                Log.w("DoaWidgetWorker", "⚠️ No cache found, fetching from API...")
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

            Log.d("DoaWidgetWorker", "🏷️ Title MS: $titleMs")

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
            Log.d("DoaWidgetWorker", "✅ Widget updated: $titleMs")
            
        } catch (e: Exception) {
            Log.e("DoaWidgetWorker", "❌ Error updating widget: ${e.message}", e)
        }
    }

    companion object {
        private const val WORK_TAG = "doa_widget_update"
        
        fun scheduleNextUpdate(context: Context) {
            val updateRequest = OneTimeWorkRequestBuilder<DoaWidgetWorker>()
                .setInitialDelay(15, TimeUnit.MINUTES)
                .addTag(WORK_TAG)
                .build()
            
            WorkManager.getInstance(context).enqueueUniqueWork(
                WORK_TAG,
                ExistingWorkPolicy.REPLACE,
                updateRequest
            )
        }
    }
}