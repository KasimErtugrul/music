package com.example.resonance.widget

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Color
import android.view.KeyEvent
import android.widget.RemoteViews
import com.example.resonance.MainActivity
import com.example.resonance.R
import com.ryanheise.audioservice.MediaButtonReceiver
import es.antonborri.home_widget.HomeWidgetProvider

class MusicWidgetProvider : HomeWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        val title = widgetData.getString("song_title", null)?.takeIf { it.isNotEmpty() }
            ?: context.getString(R.string.widget_not_playing)
        val artist = widgetData.getString("artist_name", null)?.takeIf { it.isNotEmpty() }
            ?: context.getString(R.string.app_name)
        val isPlaying = widgetData.getBoolean("is_playing", false)
        val isTransparent = widgetData.getBoolean("widget_transparent", false)
        val artwork = decodeArtwork(widgetData.getString("artwork_path", null))

        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.music_widget).apply {
                setTextViewText(R.id.widget_title, title)
                setTextViewText(R.id.widget_artist, artist)

                if (artwork != null) {
                    setImageViewBitmap(R.id.widget_artwork, artwork)
                } else {
                    setImageViewResource(R.id.widget_artwork, R.mipmap.ic_launcher)
                }

                setImageViewResource(
                    R.id.widget_play_pause,
                    if (isPlaying) android.R.drawable.ic_media_pause
                    else android.R.drawable.ic_media_play,
                )

                setInt(
                    R.id.widget_root,
                    "setBackgroundColor",
                    if (isTransparent) Color.TRANSPARENT else BACKGROUND_COLOR,
                )

                setOnClickPendingIntent(R.id.widget_root, launchAppIntent(context))
                setOnClickPendingIntent(
                    R.id.widget_play_pause,
                    mediaButtonIntent(context, KeyEvent.KEYCODE_MEDIA_PLAY_PAUSE, 1),
                )
                setOnClickPendingIntent(
                    R.id.widget_next,
                    mediaButtonIntent(context, KeyEvent.KEYCODE_MEDIA_NEXT, 2),
                )
            }
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }

    /**
     * Kapağı en fazla [MAX_ARTWORK_PX] kenara küçülterek okur. RemoteViews bitmap belleği
     * sınırlıdır; büyük dosya `RemoteViews ... exceeds maximum bitmap memory usage` ile
     * güncellemeyi düşürür. (ARGB_8888 256x256 ≈ 256 KB.)
     */
    private fun decodeArtwork(path: String?): Bitmap? {
        if (path.isNullOrEmpty()) return null
        return try {
            val bounds = BitmapFactory.Options().apply { inJustDecodeBounds = true }
            BitmapFactory.decodeFile(path, bounds)
            if (bounds.outWidth <= 0 || bounds.outHeight <= 0) return null
            var sample = 1
            while (bounds.outWidth / (sample * 2) >= MAX_ARTWORK_PX &&
                bounds.outHeight / (sample * 2) >= MAX_ARTWORK_PX
            ) {
                sample *= 2
            }
            BitmapFactory.decodeFile(path, BitmapFactory.Options().apply { inSampleSize = sample })
        } catch (e: Exception) {
            null
        }
    }

    private fun launchAppIntent(context: Context): PendingIntent {
        val intent = Intent(context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP
        }
        return PendingIntent.getActivity(
            context, 0, intent,
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
        )
    }

    private fun mediaButtonIntent(context: Context, keyCode: Int, requestCode: Int): PendingIntent {
        val intent = Intent(Intent.ACTION_MEDIA_BUTTON).apply {
            setClass(context, MediaButtonReceiver::class.java)
            putExtra(Intent.EXTRA_KEY_EVENT, KeyEvent(KeyEvent.ACTION_DOWN, keyCode))
        }
        return PendingIntent.getBroadcast(
            context, requestCode, intent,
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
        )
    }

    private companion object {
        const val MAX_ARTWORK_PX = 256
        val BACKGROUND_COLOR: Int = Color.parseColor("#1C1B1F")
    }
}
