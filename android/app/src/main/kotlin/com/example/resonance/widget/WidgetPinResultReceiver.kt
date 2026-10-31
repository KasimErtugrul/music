package com.example.resonance.widget

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.widget.Toast
import com.example.resonance.R

/**
 * Launcher, widget'ı gerçekten ana ekrana ekleyince (kullanıcı onayladıktan sonra)
 * [WidgetPinActivity] içinde verilen geri çağrı ile burayı tetikler.
 * Uygulama kapalı olsa bile çalışır.
 */
class WidgetPinResultReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent?) {
        Toast.makeText(
            context.applicationContext,
            R.string.widget_pin_success,
            Toast.LENGTH_LONG,
        ).show()
    }
}