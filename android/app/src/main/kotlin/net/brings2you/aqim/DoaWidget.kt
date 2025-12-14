package net.brings2you.aqim

import android.content.Context
import android.content.Intent
import android.util.Log
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.glance.GlanceId
import androidx.glance.GlanceModifier
import androidx.glance.action.action
import androidx.glance.action.clickable
import androidx.glance.appwidget.GlanceAppWidget
import androidx.glance.appwidget.SizeMode
import androidx.glance.appwidget.provideContent
import androidx.glance.background
import androidx.glance.layout.Alignment
import androidx.glance.layout.Column
import androidx.glance.layout.fillMaxSize
import androidx.glance.layout.fillMaxWidth
import androidx.glance.layout.padding
import androidx.glance.text.FontWeight
import androidx.glance.text.Text
import androidx.glance.text.TextAlign
import androidx.glance.text.TextStyle
import androidx.glance.unit.ColorProvider

class DoaWidget : GlanceAppWidget() {
    override val sizeMode: SizeMode = SizeMode.Single

    override suspend fun provideGlance(
        context: Context,
        id: GlanceId,
    ) {
        Log.d("DoaWidget", "🟢 provideGlance called")
        provideContent { DoaWidgetContent(context = context) }
    }

    @Composable
    fun DoaWidgetContent(context: Context) {
        val prefs = context.getSharedPreferences("doa_prefs", Context.MODE_PRIVATE)

        val titleMs = prefs.getString("title_ms", "Doa Harian") ?: "Doa Harian"
        val arabic =
            prefs.getString("arabic", "اللّهُمَّ اجْعَلْنِي مِنَ التَّوَّابِينَ")
                ?: "اللّهُمَّ اجْعَلْنِي مِنَ التَّوَّابِينَ"
        val ms =
            prefs.getString(
                "ms",
                "Ya Allah, jadikan aku daripada orang yang bertaubat.",
            )
                ?: "Ya Allah, jadikan aku daripada orang yang bertaubat."
        val ref = prefs.getString("ref", "—") ?: "—"

        Log.d("DoaWidget", "✅ Loaded: $titleMs")

        Column(
            modifier =
                GlanceModifier
                    .fillMaxSize()
                    .background(ColorProvider(Color(0x4D000000)))
                    .padding(12.dp)
                    .clickable(
                        action {
                            val updateIntent =
                                Intent(context, DoaWidgetUpdater::class.java).apply {
                                    setAction("net.brings2you.aqim.UPDATE_DOA_WIDGET")
                                }
                            context.sendBroadcast(updateIntent)
                        },
                    ),
            verticalAlignment = Alignment.CenterVertically,
            horizontalAlignment = Alignment.CenterHorizontally,
        ) {
            Text(
                text = titleMs,
                style =
                    TextStyle(
                        color = ColorProvider(Color.White),
                        fontSize = 16.sp,
                        fontWeight = FontWeight.Bold,
                        textAlign = TextAlign.Center,
                    ),
                modifier = GlanceModifier.fillMaxWidth(),
            )

            Text(
                text = arabic,
                style =
                    TextStyle(
                        color = ColorProvider(Color.White),
                        fontSize = 24.sp,
                        textAlign = TextAlign.Center,
                    ),
                modifier = GlanceModifier.fillMaxWidth().padding(top = 12.dp),
            )

            Text(
                text = ms,
                style =
                    TextStyle(
                        color = ColorProvider(Color.LightGray),
                        fontSize = 11.sp,
                        textAlign = TextAlign.Center,
                    ),
                modifier =
                    GlanceModifier
                        .fillMaxWidth()
                        .padding(top = 6.dp, bottom = 4.dp),
            )

            Text(
                text = ref,
                style =
                    TextStyle(
                        color = ColorProvider(Color.Gray),
                        fontSize = 9.sp,
                        textAlign = TextAlign.Center,
                    ),
                modifier = GlanceModifier.fillMaxWidth(),
            )
        }

        Log.d("DoaWidget", "✅ UI rendered")
    }
}
