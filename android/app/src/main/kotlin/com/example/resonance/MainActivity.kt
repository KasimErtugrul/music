package com.example.resonance

import android.content.ContentResolver
import android.content.ContentUris
import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.provider.MediaStore
import android.util.Size
import com.ryanheise.audioservice.AudioServiceActivity
import com.ryanheise.audioservice.AudioServicePlugin
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream
import java.nio.ByteBuffer
import java.nio.CharBuffer
import java.nio.charset.CharacterCodingException
import java.nio.charset.Charset
import java.nio.charset.CodingErrorAction
import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors

class MainActivity : AudioServiceActivity() {
    private val executor: ExecutorService = Executors.newFixedThreadPool(2)
    private val mainHandler = Handler(Looper.getMainLooper())

    override fun provideFlutterEngine(context: Context): FlutterEngine? {
        return AudioServicePlugin.getFlutterEngine(context)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // Sızıntıyı önlemek için applicationContext kullanıyoruz
        val resolver = applicationContext.contentResolver
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "querySongs" -> runAsync(result) { querySongs(resolver) }
                    "queryArtwork" -> {
                        val id = call.argument<Number>("id")?.toLong()
                        val size = call.argument<Number>("size")?.toInt() ?: 200
                        if (id == null) {
                            result.error("bad_args", "id is required", null)
                        } else {
                            runAsync(result) { queryArtwork(resolver, id, size) }
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler(null)
        super.cleanUpFlutterEngine(flutterEngine)
    }

    override fun onDestroy() {
        executor.shutdown()
        super.onDestroy()
    }

    private fun <T> runAsync(result: MethodChannel.Result, block: () -> T) {
        executor.execute {
            try {
                val value = block()
                mainHandler.post { result.success(value) }
            } catch (e: Exception) {
                mainHandler.post { result.error("media_store_error", e.message, null) }
            }
        }
    }

    @Suppress("DEPRECATION")
    private fun querySongs(resolver: ContentResolver): List<Map<String, Any?>> {
        val collection = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            MediaStore.Audio.Media.getContentUri(MediaStore.VOLUME_EXTERNAL)
        } else {
            MediaStore.Audio.Media.EXTERNAL_CONTENT_URI
        }
        val hasGenre = Build.VERSION.SDK_INT >= Build.VERSION_CODES.R
        val projection = mutableListOf(
            MediaStore.Audio.Media._ID,
            MediaStore.Audio.Media.TITLE,
            MediaStore.Audio.Media.ARTIST,
            MediaStore.Audio.Media.ALBUM,
            MediaStore.Audio.Media.ALBUM_ID,
            MediaStore.Audio.Media.ARTIST_ID,
            MediaStore.Audio.Media.DURATION,
            MediaStore.Audio.Media.DATE_ADDED,
            MediaStore.Audio.Media.SIZE,
            MediaStore.Audio.Media.DISPLAY_NAME,
            MediaStore.Audio.Media.DATA,
            MediaStore.Audio.Media.IS_RINGTONE,
            MediaStore.Audio.Media.IS_ALARM,
            MediaStore.Audio.Media.IS_NOTIFICATION,
        )
        if (hasGenre) projection.add(MediaStore.Audio.Media.GENRE)

        // IS_MUSIC filtresi eklendi
        val selection = "${MediaStore.Audio.Media.IS_MUSIC} != 0"

        val songs = ArrayList<Map<String, Any?>>()
        resolver.query(collection, projection.toTypedArray(), selection, null, null)?.use { c ->
            val iId = c.getColumnIndexOrThrow(MediaStore.Audio.Media._ID)
            val iTitle = c.getColumnIndexOrThrow(MediaStore.Audio.Media.TITLE)
            val iArtist = c.getColumnIndexOrThrow(MediaStore.Audio.Media.ARTIST)
            val iAlbum = c.getColumnIndexOrThrow(MediaStore.Audio.Media.ALBUM)
            val iAlbumId = c.getColumnIndexOrThrow(MediaStore.Audio.Media.ALBUM_ID)
            val iArtistId = c.getColumnIndexOrThrow(MediaStore.Audio.Media.ARTIST_ID)
            val iDuration = c.getColumnIndexOrThrow(MediaStore.Audio.Media.DURATION)
            val iDate = c.getColumnIndexOrThrow(MediaStore.Audio.Media.DATE_ADDED)
            val iSize = c.getColumnIndexOrThrow(MediaStore.Audio.Media.SIZE)
            val iName = c.getColumnIndexOrThrow(MediaStore.Audio.Media.DISPLAY_NAME)
            val iData = c.getColumnIndexOrThrow(MediaStore.Audio.Media.DATA)
            val iRing = c.getColumnIndexOrThrow(MediaStore.Audio.Media.IS_RINGTONE)
            val iAlarm = c.getColumnIndexOrThrow(MediaStore.Audio.Media.IS_ALARM)
            val iNotif = c.getColumnIndexOrThrow(MediaStore.Audio.Media.IS_NOTIFICATION)
            val iGenre = if (hasGenre) c.getColumnIndexOrThrow(MediaStore.Audio.Media.GENRE) else -1

            while (c.moveToNext()) {
                if (c.getInt(iRing) != 0 || c.getInt(iAlarm) != 0 || c.getInt(iNotif) != 0) continue
                val id = c.getLong(iId)
                songs.add(
                    mapOf(
                        "id" to id,
                        "uri" to ContentUris.withAppendedId(collection, id).toString(),
                        "path" to c.getString(iData),
                        "title" to fixText(c.getString(iTitle)),
                        "displayName" to c.getString(iName),
                        "artist" to fixText(c.getString(iArtist)),
                        "album" to fixText(c.getString(iAlbum)),
                        "genre" to (if (iGenre >= 0) fixText(c.getString(iGenre)) else null),
                        "albumId" to (if (c.isNull(iAlbumId)) null else c.getLong(iAlbumId)),
                        "artistId" to (if (c.isNull(iArtistId)) null else c.getLong(iArtistId)),
                        "durationMs" to c.getLong(iDuration),
                        "dateAddedSec" to c.getLong(iDate),
                        "sizeBytes" to c.getLong(iSize),
                    )
                )
            }
        }
        return songs
    }

    private fun queryArtwork(resolver: ContentResolver, songId: Long, size: Int): ByteArray? {
        val loaded: Bitmap? = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            val uri = ContentUris.withAppendedId(MediaStore.Audio.Media.EXTERNAL_CONTENT_URI, songId)
            try {
                resolver.loadThumbnail(uri, Size(size, size), null)
            } catch (e: Exception) {
                null
            }
        } else {
            legacyAlbumArt(resolver, songId, size)
        }
        val bitmap = loaded ?: return null
        val out = ByteArrayOutputStream()
        bitmap.compress(Bitmap.CompressFormat.JPEG, 85, out)
        bitmap.recycle()
        return out.toByteArray()
    }

    @Suppress("DEPRECATION")
    private fun legacyAlbumArt(resolver: ContentResolver, songId: Long, size: Int): Bitmap? {
        val albumId = resolver.query(
            MediaStore.Audio.Media.EXTERNAL_CONTENT_URI,
            arrayOf(MediaStore.Audio.Media.ALBUM_ID),
            "${MediaStore.Audio.Media._ID}=?",
            arrayOf(songId.toString()),
            null,
        )?.use { if (it.moveToFirst()) it.getLong(0) else null } ?: return null
        val artPath = resolver.query(
            MediaStore.Audio.Albums.EXTERNAL_CONTENT_URI,
            arrayOf(MediaStore.Audio.Albums.ALBUM_ART),
            "${MediaStore.Audio.Albums._ID}=?",
            arrayOf(albumId.toString()),
            null,
        )?.use { if (it.moveToFirst()) it.getString(0) else null } ?: return null

        val bounds = BitmapFactory.Options().apply { inJustDecodeBounds = true }
        BitmapFactory.decodeFile(artPath, bounds)
        var sample = 1
        while (bounds.outWidth / (sample * 2) >= size && bounds.outHeight / (sample * 2) >= size) {
            sample *= 2
        }
        val opts = BitmapFactory.Options().apply { inSampleSize = sample }
        return BitmapFactory.decodeFile(artPath, opts)
    }

    private val repairCharsets: List<Charset> by lazy {
        listOf("ISO-8859-1", "windows-1252", "windows-1254", "GB18030", "GBK", "Big5")
            .mapNotNull { name -> try { Charset.forName(name) } catch (e: Exception) { null } }
    }

    private fun fixText(raw: String?): String? {
        if (raw == null || raw.all { it.code < 0x80 }) return raw
        for (cs in repairCharsets) {
            val bytes = encodeStrict(raw, cs) ?: continue
            val repaired = decodeUtf8Strict(bytes) ?: continue
            if (repaired != raw) return repaired
        }
        return raw
    }

    private fun encodeStrict(text: String, cs: Charset): ByteArray? = try {
        val buf = cs.newEncoder()
            .onMalformedInput(CodingErrorAction.REPORT)
            .onUnmappableCharacter(CodingErrorAction.REPORT)
            .encode(CharBuffer.wrap(text))
        ByteArray(buf.remaining()).also { buf.get(it) }
    } catch (e: CharacterCodingException) {
        null
    }

    private fun decodeUtf8Strict(bytes: ByteArray): String? = try {
        Charsets.UTF_8.newDecoder()
            .onMalformedInput(CodingErrorAction.REPORT)
            .onUnmappableCharacter(CodingErrorAction.REPORT)
            .decode(ByteBuffer.wrap(bytes))
            .toString()
    } catch (e: CharacterCodingException) {
        null
    }

    companion object {
        private const val CHANNEL = "com.example.resonance/media_store"
    }
}