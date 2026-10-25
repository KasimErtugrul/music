package com.example.resonance

import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Intent
import android.os.Build
import android.widget.Toast
import com.example.resonance.widget.MusicWidgetProvider
import com.ryanheise.audioservice.AudioServiceActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : AudioServiceActivity() {

    private var pendingPinWidget = false

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MediaStoreChannel.attach(flutterEngine, applicationContext)
        handleIntent(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        handleIntent(intent)
    }

    override fun onPostResume() {
        super.onPostResume()
        // Activity tamamen öne geldikten sonra iste; soğuk başlatmada daha güvenilir.
        if (pendingPinWidget) {
            pendingPinWidget = false
            requestPinWidget()
        }
    }

    private fun handleIntent(intent: Intent?) {
        if (intent == null) return

        if (intent.action == ACTION_ADD_WIDGET) {
            intent.action = Intent.ACTION_MAIN // tekrar tetiklenmesin
            pendingPinWidget = true
            return
        }

        if (intent.action != Intent.ACTION_VIEW) return
        val uri = intent.dataString
        val fromHistory =
            (intent.flags and Intent.FLAG_ACTIVITY_LAUNCHED_FROM_HISTORY) != 0
        intent.action = Intent.ACTION_MAIN
        if (uri != null && !fromHistory) {
            MediaStoreChannel.handleExternalUri(uri)
        }
    }

    private fun requestPinWidget() {
        val manager = AppWidgetManager.getInstance(this)
        val supported = Build.VERSION.SDK_INT >= Build.VERSION_CODES.O &&
            manager.isRequestPinAppWidgetSupported
        if (supported) {
            manager.requestPinAppWidget(
                ComponentName(this, MusicWidgetProvider::class.java), null, null,
            )
        } else {
            Toast.makeText(this, R.string.widget_pin_unsupported, Toast.LENGTH_LONG).show()
        }
    }

    private companion object {
        const val ACTION_ADD_WIDGET = "com.example.resonance.ADD_WIDGET"
    }
}