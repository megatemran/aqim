package net.brings2you.aqim

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch

class BootReceiver : BroadcastReceiver() {
    override fun onReceive(
        context: Context,
        intent: Intent?,
    ) {
        when (intent?.action) {
            Intent.ACTION_BOOT_COMPLETED,
            Intent.ACTION_LOCKED_BOOT_COMPLETED,
            Intent.ACTION_TIMEZONE_CHANGED,
            Intent.ACTION_MY_PACKAGE_REPLACED,
            -> {
                Log.d("BootReceiver", "🔄 System event: ${intent.action}")

                // 1. Schedule prayers melalui AppScheduler
                val scheduler = AppScheduler(context)
                scheduler.scheduleNextPrayerTime()

                // 2. Schedule Doa widget updates
                DoaWidgetUpdater.schedule(context)

                // 3. Update widget UI (jika perlu)
                CoroutineScope(Dispatchers.IO).launch {
                    try {
                        // Jika anda ada widget class, update di sini
                        // Contoh: MyWidget().updateAll(context)
                        Log.d("BootReceiver", "✅ System event handled")
                    } catch (e: Exception) {
                        Log.e("BootReceiver", "❌ Widget update failed", e)
                    }
                }
            }
        }
    }
}
