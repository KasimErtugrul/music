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
import com.example.resonance.mediastore.MediaStoreBridge
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
        // The MediaStore channel is now registered on every engine by MediaStorePlugin
        // (via GeneratedPluginRegistrant); no separate attach here.
        super.configureFlutterEngine(flutterEngine)
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

    override fun onPause() {
        // If the launcher confirmation dialog opened, the Activity pauses: the request was not
        // swallowed, so cancel the "could not add" timeout. The receiver stays until onDestroy.
        mainHandler.removeCallbacks(pinTimeout)
        super.onPause()
    }

    override fun onDestroy() {
        mainHandler.removeCallbacks(pinTimeout)
        unregisterPinReceiver()
        super.onDestroy()
    }

    private fun handleIntent(intent: Intent?) {
        if (intent == null) return

        if (intent.action == ACTION_ADD_WIDGET) {
            intent.action = Intent.ACTION_MAIN // do not trigger again
            pendingPinWidget = true
            return
        }

        if (intent.action != Intent.ACTION_VIEW) return
        val uri = intent.dataString
        val fromHistory =
            (intent.flags and Intent.FLAG_ACTIVITY_LAUNCHED_FROM_HISTORY) != 0
        intent.action = Intent.ACTION_MAIN
        if (uri != null && !fromHistory) {
            MediaStoreBridge.handleExternalUri(uri)
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
            // If the dialog opens, onPause cancels this timer; if nothing happens at all
            // (e.g. MIUI silently swallowed the request) the user gets guidance.
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
                // already unregistered
            }
        }
        pinReceiver = null
    }

    private companion object {
        const val ACTION_ADD_WIDGET = "com.example.resonance.ADD_WIDGET"
        const val ACTION_WIDGET_PINNED = "com.example.resonance.WIDGET_PINNED"
        const val PIN_TIMEOUT_MS = 1500L
    }
}