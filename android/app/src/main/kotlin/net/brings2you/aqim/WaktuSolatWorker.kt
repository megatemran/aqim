// package net.brings2you.aqim

// import android.content.Context
// import android.util.Log
// import androidx.glance.appwidget.updateAll
// import androidx.work.*
// import java.util.concurrent.TimeUnit

// class WaktuSolatWorker(
//     context: Context,
//     params: WorkerParameters
// ) : CoroutineWorker(context, params) {

//     override suspend fun doWork(): Result {
//         Log.d("WaktuSolatWorker", "🛟 Fallback worker running")

//         return try {
//             WaktuSolatWidget().updateAll(applicationContext)

//             // re-arm alarm in case OEM killed it
//             WaktuSolatWidgetUpdater.initializeScheduling(applicationContext)

//             Result.success()
//         } catch (e: Exception) {
//             Log.e("WaktuSolatWorker", "❌ Error", e)
//             Result.success()
//         }
//     }

//     companion object {

//         private const val TAG = "waktu_solat_fallback"

//         fun scheduleFallback(context: Context) {
//             val work = OneTimeWorkRequestBuilder<WaktuSolatWorker>()
//                 .setInitialDelay(6, TimeUnit.HOURS)
//                 .addTag(TAG)
//                 .build()

//             WorkManager.getInstance(context)
//                 .enqueueUniqueWork(
//                     TAG,
//                     ExistingWorkPolicy.REPLACE,
//                     work
//                 )
//         }
//     }
// }
