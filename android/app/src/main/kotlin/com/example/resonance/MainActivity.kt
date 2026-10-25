package com.example.resonance

import android.content.Intent
import com.ryanheise.audioservice.AudioServiceActivity
import io.flutter.embedding.engine.FlutterEngine

/**
 * audio_service'in AudioServiceActivity'si, paylaşımlı FlutterEngine'i zaten sağlar
 * (provideFlutterEngine). Bu yüzden burada tekrar override edilmez.
 */
class MainActivity : AudioServiceActivity() {

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MediaStoreChannel.attach(flutterEngine, applicationContext)
        // Soğuk başlatma: uygulama "Bununla aç" ile açıldıysa.
        handleIntent(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        handleIntent(intent)
    }

    private fun handleIntent(intent: Intent?) {
        if (intent == null || intent.action != Intent.ACTION_VIEW) return
        val uri = intent.dataString
        // Intent'i tüket: Activity yeniden oluşturulursa (veya son uygulamalardan açılırsa)
        // aynı dosya tekrar çalınmasın.
        val fromHistory =
            (intent.flags and Intent.FLAG_ACTIVITY_LAUNCHED_FROM_HISTORY) != 0
        intent.action = Intent.ACTION_MAIN
        if (uri != null && !fromHistory) {
            MediaStoreChannel.deliverExternalUri(uri)
        }
    }
}
