package net.brings2you.aqim

import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.PowerManager
import android.provider.Settings
import android.util.Log

object BatteryOptimizationHelper {
    private const val TAG = "BatteryOptimization"

    /**
     * Check if battery optimization is disabled for this app
     */
    fun isBatteryOptimizationDisabled(context: Context): Boolean =
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            val powerManager = context.getSystemService(Context.POWER_SERVICE) as PowerManager
            val isIgnoring = powerManager.isIgnoringBatteryOptimizations(context.packageName)
            Log.d(TAG, "Battery optimization disabled: $isIgnoring")
            isIgnoring
        } else {
            // Battery optimization doesn't exist before Android 6.0
            true
        }

    /**
     * Request to disable battery optimization for this app
     * This should be called from an Activity
     */
    fun requestDisableBatteryOptimization(context: Context) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            if (!isBatteryOptimizationDisabled(context)) {
                try {
                    Log.d(TAG, "Requesting battery optimization exemption...")

                    // Method 1: Direct request (recommended for alarm apps)
                    val intent =
                        Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS).apply {
                            data = Uri.parse("package:${context.packageName}")
                            flags = Intent.FLAG_ACTIVITY_NEW_TASK
                        }
                    context.startActivity(intent)

                    Log.d(TAG, "Battery optimization request dialog shown")
                } catch (e: Exception) {
                    Log.e(TAG, "Error requesting battery optimization: ${e.message}", e)

                    // Fallback: Open battery settings page
                    try {
                        val fallbackIntent =
                            Intent(Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS).apply {
                                flags = Intent.FLAG_ACTIVITY_NEW_TASK
                            }
                        context.startActivity(fallbackIntent)
                        Log.d(TAG, "Opened battery optimization settings")
                    } catch (fallbackError: Exception) {
                        Log.e(TAG, "Fallback also failed: ${fallbackError.message}")
                    }
                }
            } else {
                Log.d(TAG, "Battery optimization already disabled")
            }
        }
    }

    /**
     * Open battery optimization settings page
     */
    fun openBatteryOptimizationSettings(context: Context) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            try {
                val intent =
                    Intent(Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS).apply {
                        flags = Intent.FLAG_ACTIVITY_NEW_TASK
                    }
                context.startActivity(intent)
                Log.d(TAG, "Opened battery optimization settings")
            } catch (e: Exception) {
                Log.e(TAG, "Error opening battery settings: ${e.message}", e)
            }
        }
    }
}
