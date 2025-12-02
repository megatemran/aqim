package net.brings2you.aqim

import android.content.Context
import android.util.Log
import androidx.glance.appwidget.GlanceAppWidget
import androidx.glance.appwidget.GlanceAppWidgetReceiver

class WaktuSolatWidgetReceiver : GlanceAppWidgetReceiver() {
    override val glanceAppWidget: GlanceAppWidget = WaktuSolatWidget()
}

class BismillahWhiteWidgetReceiver : GlanceAppWidgetReceiver() {
    override val glanceAppWidget: GlanceAppWidget = BismillahWhiteWidget()
}

class BismillahBlackWidgetReceiver : GlanceAppWidgetReceiver() {
    override val glanceAppWidget: GlanceAppWidget = BismillahBlackWidget()
}

class BismillahColorWidgetReceiver : GlanceAppWidgetReceiver() {
    override val glanceAppWidget: GlanceAppWidget = BismillahColorWidget()
}

class DoaWidgetReceiver : GlanceAppWidgetReceiver() {
    override val glanceAppWidget: GlanceAppWidget = DoaWidget()

    override fun onEnabled(context: Context) {
        super.onEnabled(context)
        Log.d("DoaWidget", "🚀 Widget enabled")
        initializeDefaultData(context)
    }

    override fun onDisabled(context: Context) {
        super.onDisabled(context)
        Log.d("DoaWidget", "🛑 Widget disabled")
    }

    private fun initializeDefaultData(context: Context) {
        try {
            val prefs = context.getSharedPreferences("doa_prefs", Context.MODE_PRIVATE)
            if (!prefs.contains("arabic")) {
                Log.d("DoaWidget", "🔧 Initializing default widget data...")
                prefs.edit().apply {
                    putString("arabic", "اللّهُمَّ اجْعَلْنِي مِنَ التَّوَّابِينَ")
                    putString("title_ms", "Doa Harian")
                    putString("ms", "Ya Allah, jadikan aku daripada orang yang bertaubat.")
                    putString("ref", "Quran")
                    putLong("last_update", System.currentTimeMillis())
                    apply()
                }
                Log.d("DoaWidget", "✅ Default data initialized")
            }
        } catch (e: Exception) {
            Log.e("DoaWidget", "❌ Error initializing default data: ${e.message}", e)
        }
    }
}
