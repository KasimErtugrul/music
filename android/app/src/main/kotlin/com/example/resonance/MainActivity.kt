package com.example.resonance

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.BroadcastReceiver
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.widget.Toast
import com.example.resonance.widget.MusicWidgetProvider
import com.ryanheise.audioservice.AudioServiceActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : AudioServiceActivity() {

    private var pendingPinWidget = false

    private val mainHandler = Handler(Looper.getMainLooper())
    private var pinReceiver: BroadcastReceiver? = null
    private val pinTimeout = Runnable {
        unregisterPinReceiver()
        Toast.makeText(this, R.string.widget_pin_failed, Toast.LENGTH_LONG).show()
    }

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
        if (pendingPinWidget) {
            pendingPinWidget = false
            requestPinWidget()
        }
    }

    override fun onDestroy() {
        mainHandler.removeCallbacks(pinTimeout)
        unregisterPinReceiver()
        super.onDestroy()
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
        if (!supported) {
            Toast.makeText(this, R.string.widget_pin_unsupported, Toast.LENGTH_LONG).show()
            return
        }

        // Launcher widget'ı gerçekten eklediğinde bu yayın gelir.
        unregisterPinReceiver()
        val receiver = object : BroadcastReceiver() {
            override fun onReceive(context: Context, intent: Intent) {
                mainHandler.removeCallbacks(pinTimeout)
                unregisterPinReceiver()
            }
        }
        val filter = IntentFilter(ACTION_WIDGET_PINNED)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            registerReceiver(receiver, filter, Context.RECEIVER_NOT_EXPORTED)
        } else {
            @Suppress("UnspecifiedRegisterReceiverFlag")
            registerReceiver(receiver, filter)
        }
        pinReceiver = receiver

        val callback = PendingIntent.getBroadcast(
            this, 0,
            Intent(ACTION_WIDGET_PINNED).setPackage(packageName),
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
        )

        val accepted = manager.requestPinAppWidget(
            ComponentName(this, MusicWidgetProvider::class.java), null, callback,
        )
        if (accepted) {
            // Pencere açılır ve kullanıcı onaylarsa receiver tetiklenir; 3 sn içinde hiçbir
            // şey olmazsa (ör. MIUI isteği sessizce yuttuysa) kullanıcıya yol gösterilir.
            mainHandler.postDelayed(pinTimeout, PIN_TIMEOUT_MS)
        } else {
            unregisterPinReceiver()
            Toast.makeText(this, R.string.widget_pin_failed, Toast.LENGTH_LONG).show()
        }
    }

    private fun unregisterPinReceiver() {
        pinReceiver?.let {
            try {
                unregisterReceiver(it)
            } catch (e: IllegalArgumentException) {
                // zaten kayıtlı değil
            }
        }
        pinReceiver = null
    }

    private companion object {
        const val ACTION_ADD_WIDGET = "com.example.resonance.ADD_WIDGET"
        const val ACTION_WIDGET_PINNED = "com.example.resonance.WIDGET_PINNED"
        const val PIN_TIMEOUT_MS = 3000L
    }
}