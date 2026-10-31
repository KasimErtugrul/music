package com.example.resonance.widget

import android.app.Activity
import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Intent
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.util.Log
import android.widget.Toast
import com.example.resonance.R

/**
 * Uygulama simgesindeki "Widget ekle" kısayolunun hedefi.
 *
 * Arayüzü yoktur (şeffaf tema) ve MainActivity'yi / Flutter motorunu başlatmaz:
 * launcher'a widget ekleme isteğini iletir.
 *
 * Önemli (MIUI): İstek gönderildikten sonra launcher/MIUI penceresi açılırken bu ekranı
 * HEMEN kapatmıyoruz. Bazı MIUI sürümleri isteği, isteği gönderen ekran kapanınca
 * iptal edebilir. Bu yüzden pencere kapanıp ekranımıza dönülene kadar (ya da güvenlik
 * süresi dolana kadar) açık kalırız. Ekran şeffaf olduğu için kullanıcı bunu görmez.
 *
 * Başarı mesajı: [WidgetPinResultReceiver]. Hata mesajları: bu sınıf.
 * DEBUG = true yapılırsa tüm aşamalar kapanırken TEK teşhis mesajında gösterilir
 * (aynı kayıtlar logcat'te "WidgetPin" etiketiyle her zaman yazılır).
 */
class WidgetPinActivity : Activity() {

    private val handler = Handler(Looper.getMainLooper())
    private val trail = StringBuilder()
    private var requestSent = false
    private var paused = false
    private var summaryShown = false

    /** İstek gönderildi ama hiçbir pencere açılmadı: launcher isteği yuttu. */
    private val onNoResponse = Runnable {
        done("2sn doldu, launcher yanıt vermedi", R.string.widget_pin_failed)
    }

    /** Pencere açıldı ama hiç kapanmadı: ekranı sonsuza dek açık bırakma. */
    private val onPausedTooLong = Runnable {
        done("pencere ${PAUSED_MAX_MS / 1000} sn açık kaldı, kapanıyor")
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        step("açıldı (action=${intent?.action})")
        // Sistem activity'yi yeniden oluşturduysa isteği tekrarlama.
        if (savedInstanceState != null) {
            done("yeniden oluşturuldu, istek atlanıyor")
            return
        }
        // Kısayoldan gelmeyen (başka bir uygulamanın tetiklediği) istekleri yok say.
        if (intent?.action != ACTION_ADD_WIDGET) {
            done("beklenmeyen action")
            return
        }
        try {
            requestPin()
        } catch (e: Throwable) {
            Log.e(TAG, "requestPin hata", e)
            done("HATA ${e.javaClass.simpleName}: ${e.message}", R.string.widget_pin_failed)
        }
    }

    private fun requestPin() {
        val manager = AppWidgetManager.getInstance(this)
        val supported = Build.VERSION.SDK_INT >= Build.VERSION_CODES.O &&
            manager.isRequestPinAppWidgetSupported
        step("destek=$supported")
        if (!supported) {
            done("desteklenmiyor", R.string.widget_pin_unsupported)
            return
        }

        // Widget gerçekten eklenince launcher bu geri çağrıyı tetikler ("Widget eklendi" mesajı).
        val successCallback = PendingIntent.getBroadcast(
            this,
            0,
            Intent(this, WidgetPinResultReceiver::class.java),
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
        )
        val accepted = manager.requestPinAppWidget(
            ComponentName(this, MusicWidgetProvider::class.java), null, successCallback,
        )
        step("kabul=$accepted")
        if (accepted) {
            requestSent = true
            handler.postDelayed(onNoResponse, NO_RESPONSE_MS)
        } else {
            done("launcher reddetti", R.string.widget_pin_failed)
        }
    }

    override fun onPause() {
        handler.removeCallbacks(onNoResponse)
        step("onPause")
        if (requestSent && !isFinishing) {
            // Launcher/MIUI penceresi açık: o kapanana kadar bekle, kapatma.
            paused = true
            handler.removeCallbacks(onPausedTooLong)
            handler.postDelayed(onPausedTooLong, PAUSED_MAX_MS)
        }
        super.onPause()
    }

    override fun onResume() {
        super.onResume()
        if (paused) {
            // Pencere kapandı, ekranımıza dönüldü: iş bitti.
            done("pencere kapandı, geri dönüldü")
        }
    }

    override fun onStop() {
        step("onStop")
        super.onStop()
        // noHistory sistem tarafından kapatabilir; en azından özeti göster.
        showSummaryOnce()
    }

    override fun onDestroy() {
        handler.removeCallbacks(onNoResponse)
        handler.removeCallbacks(onPausedTooLong)
        showSummaryOnce()
        super.onDestroy()
    }

    private fun step(msg: String) {
        Log.d(TAG, msg)
        if (trail.isNotEmpty()) trail.append(" → ")
        trail.append(msg)
    }

    private fun showSummaryOnce() {
        if (summaryShown) return
        summaryShown = true
        if (DEBUG) {
            Toast.makeText(applicationContext, trail.toString(), Toast.LENGTH_LONG).show()
        }
    }

    /** Son adımı yazar, özeti gösterir, gerekirse kullanıcı mesajını verir ve kapanır. */
    private fun done(reason: String, userMessage: Int? = null) {
        step(reason)
        handler.removeCallbacks(onNoResponse)
        handler.removeCallbacks(onPausedTooLong)
        val firstTime = !summaryShown
        showSummaryOnce()
        if (firstTime) {
            userMessage?.let { Toast.makeText(applicationContext, it, Toast.LENGTH_LONG).show() }
        }
        if (!isFinishing) finish()
    }

    private companion object {
        const val TAG = "WidgetPin"
        const val DEBUG = false
        const val ACTION_ADD_WIDGET = "com.example.resonance.ADD_WIDGET"
        const val NO_RESPONSE_MS = 2000L
        const val PAUSED_MAX_MS = 30_000L
    }
}