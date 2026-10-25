package com.example.resonance.widget

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.view.KeyEvent
import android.widget.RemoteViews
import com.example.resonance.MainActivity
import com.example.resonance.R
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider
import java.io.File

class MusicWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: android.content.SharedPreferences
    ) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.music_widget).apply {
                val title = widgetData.getString("song_title", "Not playing")
                val artist = widgetData.getString("artist_name", "Resonance")
                val isPlaying = widgetData.getBoolean("is_playing", false)
                val isTransparent = widgetData.getBoolean("widget_transparent", false)
                val artworkPath = widgetData.getString("artwork_path", null)

                setTextViewText(R.id.widget_title, title)
                setTextViewText(R.id.widget_artist, artist)

                // Kapak resmi
                val artworkBitmap: Bitmap? = if (!artworkPath.isNullOrEmpty()) {
                    val file = File(artworkPath)
                    if (file.exists()) {
                        // RGB_565 → 200x200 için ~80KB, RemoteViews 1MB limitine rahat sığar
                        val opts = BitmapFactory.Options().apply {
                            inPreferredConfig = Bitmap.Config.RGB_565
                        }
                        BitmapFactory.decodeFile(file.absolutePath, opts)
                    } else null
                } else null

                if (artworkBitmap != null) {
                    setImageViewBitmap(R.id.widget_artwork, artworkBitmap)
                } else {
                    setImageViewResource(R.id.widget_artwork, R.mipmap.ic_launcher)
                }

                // Play/Pause ikonu
                setImageViewResource(
                    R.id.widget_play_pause,
                    if (isPlaying) android.R.drawable.ic_media_pause
                    else android.R.drawable.ic_media_play
                )

                // Arka plan
                if (isTransparent) {
                    setInt(R.id.widget_root, "setBackgroundColor",
                        android.graphics.Color.TRANSPARENT)
                } else {
                    setInt(R.id.widget_root, "setBackgroundColor",
                        android.graphics.Color.parseColor("#1C1B1F"))
                }

                // Tıklama: uygulamayı aç
                val launchIntent = HomeWidgetLaunchIntent.getActivity(
                    context,
                    MainActivity::class.java
                )
                setOnClickPendingIntent(R.id.widget_root, launchIntent)

                // Tıklama: Play/Pause → audio_service
                setOnClickPendingIntent(
                    R.id.widget_play_pause,
                    mediaButtonPendingIntent(
                        context,
                        KeyEvent.KEYCODE_MEDIA_PLAY_PAUSE,
                        1
                    )
                )

                // Tıklama: Next → audio_service
                setOnClickPendingIntent(
                    R.id.widget_next,
                    mediaButtonPendingIntent(
                        context,
                        KeyEvent.KEYCODE_MEDIA_NEXT,
                        2
                    )
                )
            }
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }

    private fun mediaButtonPendingIntent(
        context: Context,
        keyCode: Int,
        requestCode: Int
    ): PendingIntent {
        val intent = Intent(Intent.ACTION_MEDIA_BUTTON).apply {
            setClass(
                context,
                com.ryanheise.audioservice.MediaButtonReceiver::class.java
            )
            putExtra(
                Intent.EXTRA_KEY_EVENT,
                KeyEvent(KeyEvent.ACTION_DOWN, keyCode)
            )
        }
        return PendingIntent.getBroadcast(
            context,
            requestCode,
            intent,
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
        )
    }
}