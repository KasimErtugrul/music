package com.example.resonance.mediastore

import io.flutter.embedding.engine.plugins.FlutterPlugin

/**
 * GeneratedPluginRegistrant registers this class on EVERY FlutterEngine, including the
 * audio_service engine that starts without an Activity (Android Auto cold connect,
 * media button / widget while the process is dead).
 */
class MediaStorePlugin : FlutterPlugin {
    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        MediaStoreBridge.attach(binding.binaryMessenger, binding.applicationContext)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        MediaStoreBridge.detach(binding.binaryMessenger)
    }
}