package com.example.resonance.mediastore

import android.content.ContentResolver
import android.content.ContentUris
import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.media.MediaScannerConnection
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.os.Handler
import android.os.Looper
import android.provider.MediaStore
import android.provider.OpenableColumns
import android.util.Size
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream
import java.io.File
import java.nio.ByteBuffer
import java.nio.CharBuffer
import java.nio.charset.CharacterCodingException
import java.nio.charset.Charset
import java.nio.charset.CodingErrorAction
import java.util.UUID
import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors

/**
 * MediaStore MethodChannel. Holds no Activity reference; uses applicationContext only.
 * Attached to every FlutterEngine by [MediaStorePlugin].
 */
object MediaStoreBridge {
    const val CHANNEL = "com.example.resonance/media_store"

    private const val MAX_EXTERNAL_COPY_BYTES = 1L shl 30   // 1 GB
    private const val MAX_QUEUED_PER_ROOT = 4000            // per ROOT, files to scan (new ones)
    private const val MAX_VISITED_PER_ROOT = 200_000        // visited files cap

    private val AUDIO_EXTENSIONS = setOf(
        "mp3", "flac", "wav", "ogg", "oga", "opus", "m4a", "aac", "wma",
        "aif", "aiff", "ape", "wv", "dsf", "dff",
    )

    // Separate pools: a long scan/query must not block artwork and file opening.
    private val queryExecutor = newExecutor("media-store-query", 1)
    private val scanExecutor = newExecutor("media-store-scan", 1)
    private val artworkExecutor = newExecutor("media-store-art", 2)
    private val externalExecutor = newExecutor("media-store-external", 1)
    private val mainHandler = Handler(Looper.getMainLooper())

    @Volatile private var appContext: Context? = null
    private var channel: MethodChannel? = null
    private var attachedMessenger: BinaryMessenger? = null

    /** URI from "Open with" not yet picked up by Dart. Main thread only. */
    private var pendingExternalUri: String? = null

    private fun newExecutor(name: String, threads: Int): ExecutorService =
        Executors.newFixedThreadPool(threads) { r -> Thread(r, name).apply { isDaemon = true } }

    // ---------------------------------------------------------------- engine binding

    /** Calling again for the same messenger is harmless. Main thread. */
    fun attach(messenger: BinaryMessenger, context: Context) {
        appContext = context.applicationContext
        if (attachedMessenger === messenger) return
        channel?.setMethodCallHandler(null)
        channel = MethodChannel(messenger, CHANNEL).also {
            it.setMethodCallHandler { call, result -> onMethodCall(call, result) }
        }
        attachedMessenger = messenger
    }

    fun detach(messenger: BinaryMessenger) {
        if (attachedMessenger !== messenger) return
        channel?.setMethodCallHandler(null)
        channel = null
        attachedMessenger = null
    }

    // ---------------------------------------------------------------- "Open with"

    /** Called from the main thread. */
    fun handleExternalUri(uriString: String) {
        val ctx = appContext
        if (ctx == null) {
            deliverExternalUri(uriString)
            return
        }
        externalExecutor.execute {
            val resolved = try {
                resolveExternal(ctx, uriString)
            } catch (e: Throwable) {
                uriString
            }
            mainHandler.post { deliverExternalUri(resolved) }
        }
    }

    private fun resolveExternal(ctx: Context, uriString: String): String {
        val uri = Uri.parse(uriString)
        if (uri.scheme != "content") return uriString
        if (uri.authority == MediaStore.AUTHORITY) return uriString
        val resolver = ctx.contentResolver

        var name: String? = null
        var size = -1L
        try {
            resolver.query(
                uri, arrayOf(OpenableColumns.DISPLAY_NAME, OpenableColumns.SIZE), null, null, null,
            )?.use {
                if (it.moveToFirst()) {
                    if (!it.isNull(0)) name = it.getString(0)
                    if (!it.isNull(1)) size = it.getLong(1)
                }
            }
        } catch (e: Exception) {
            // name/size unavailable; continue
        }
        // Very large file: do not copy, continue with the original uri (no start-up delay).
        if (size > MAX_EXTERNAL_COPY_BYTES) return uriString

        val safeName = sanitizeFileName(name ?: "audio")
        val root = File(ctx.cacheDir, "external").apply { mkdirs() }
        val dir = File(root, UUID.randomUUID().toString()).apply { mkdirs() }
        val out = File(dir, safeName)
        try {
            val input = resolver.openInputStream(uri)
            if (input == null) {
                dir.deleteRecursively()
                return uriString
            }
            input.use { src -> out.outputStream().use { dst -> src.copyTo(dst) } }
        } catch (e: Exception) {
            dir.deleteRecursively()
            return uriString
        }
        // After a successful copy, clean old ones: keep the newest 3 folders.
        root.listFiles()?.sortedByDescending { it.lastModified() }?.drop(3)
            ?.forEach { it.deleteRecursively() }
        return Uri.fromFile(out).toString()
    }

    private fun sanitizeFileName(name: String): String {
        val cleaned = name
            .replace(Regex("[\\\\/:*?\"<>|\\u0000-\\u001F]"), "_")
            .trim()
            .trimStart('.')
        return cleaned.ifEmpty { "audio" }.takeLast(120)
    }

    /** Main thread. The URI stays pending until Dart confirms with true. */
    fun deliverExternalUri(uri: String) {
        pendingExternalUri = uri
        channel?.invokeMethod("onExternalIntent", uri, object : MethodChannel.Result {
            override fun success(result: Any?) {
                if (result == true && pendingExternalUri == uri) pendingExternalUri = null
            }
            override fun error(code: String, message: String?, details: Any?) {}
            override fun notImplemented() {}
        })
    }

    // ---------------------------------------------------------------- channel calls

    private fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        val ctx = appContext
        if (ctx == null) {
            result.error("no_context", "Channel is not attached", null)
            return
        }
        val resolver = ctx.contentResolver
        when (call.method) {
            "querySongs" -> runAsync(queryExecutor, result) { querySongs(resolver) }
            "queryArtwork" -> {
                val id = call.argument<Number>("id")?.toLong()
                val size = call.argument<Number>("size")?.toInt() ?: 200
                if (id == null) result.error("bad_args", "id is required", null)
                else runAsync(artworkExecutor, result) { loadArtworkBytes(resolver, id, size) }
            }
            "getExternalUri" -> {
                result.success(pendingExternalUri)
                pendingExternalUri = null
            }
            "triggerMediaScan" -> {
                val paths = call.argument<List<String>>("paths") ?: emptyList()
                if (paths.isEmpty()) result.success(0)
                else runAsync(scanExecutor, result) { triggerMediaScan(ctx, paths) }
            }
            else -> result.notImplemented()
        }
    }

    private fun <T> runAsync(executor: ExecutorService, result: MethodChannel.Result, block: () -> T) {
        executor.execute {
            try {
                val value = block()
                mainHandler.post { result.success(value) }
            } catch (e: Throwable) {
                mainHandler.post { result.error("media_store_error", e.message, null) }
            }
        }
    }

    // ---------------------------------------------------------------- song query

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

    // ---------------------------------------------------------------- media scan

    /** Known audio files in MediaStore: path -> DATE_MODIFIED (sec). */
    @Suppress("DEPRECATION")
    private fun loadKnownAudio(resolver: ContentResolver): Map<String, Long> {
        val known = HashMap<String, Long>()
        resolver.query(
            MediaStore.Audio.Media.EXTERNAL_CONTENT_URI,
            arrayOf(MediaStore.Audio.Media.DATA, MediaStore.Audio.Media.DATE_MODIFIED),
            null, null, null,
        )?.use { c ->
            while (c.moveToNext()) {
                val path = c.getString(0) ?: continue
                known[path] = c.getLong(1)
            }
        }
        return known
    }

    /**
     * Walks the given folders and reports audio files that are NOT in MediaStore (or changed
     * since) to the MediaScanner. The cap is per root; Music/Download are always walked.
     * Returns the number of files handed to the scanner (the update appears asynchronously).
     */
    private fun triggerMediaScan(context: Context, roots: List<String>): Int {
        val known = try {
            loadKnownAudio(context.contentResolver)
        } catch (e: Exception) {
            emptyMap()
        }
        val visitedDirs = HashSet<String>()
        val toScan = LinkedHashSet<String>()

        fun canonicalOf(f: File): String = try {
            f.canonicalPath
        } catch (e: Exception) {
            f.absolutePath
        }

        @Suppress("DEPRECATION")
        val standardDirs = listOfNotNull(
            Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_MUSIC),
            Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOWNLOADS),
        )

        for (root in standardDirs + roots.map { File(it) }) {
            if (!root.isDirectory) continue
            var queued = 0
            var visited = 0
            root.walkTopDown()
                // Avoids walking the same subtree twice (nested roots, symlink loops).
                .onEnter { visitedDirs.add(canonicalOf(it)) }
                .filter { it.isFile }
                .takeWhile { queued < MAX_QUEUED_PER_ROOT && visited++ < MAX_VISITED_PER_ROOT }
                .forEach { f ->
                    if (f.extension.lowercase() !in AUDIO_EXTENSIONS) return@forEach
                    val path = f.absolutePath
                    val modified = known[path]
                    if (modified == null || f.lastModified() / 1000 > modified) {
                        if (toScan.add(path)) queued++
                    }
                }
        }
        if (toScan.isEmpty()) return 0
        MediaScannerConnection.scanFile(context, toScan.toTypedArray(), null, null)
        return toScan.size
    }

    // ---------------------------------------------------------------- artwork

    /** Shared by the channel and [ArtworkProvider]. JPEG bytes or null. */
    fun loadArtworkBytes(resolver: ContentResolver, songId: Long, size: Int): ByteArray? {
        val px = size.coerceIn(16, 2048)
        val loaded: Bitmap? = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            val uri = ContentUris.withAppendedId(MediaStore.Audio.Media.EXTERNAL_CONTENT_URI, songId)
            try {
                resolver.loadThumbnail(uri, Size(px, px), null)
            } catch (e: Exception) {
                null
            }
        } else {
            legacyAlbumArt(resolver, songId, px)
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
        if (bounds.outWidth <= 0 || bounds.outHeight <= 0) return null
        var sample = 1
        while (bounds.outWidth / (sample * 2) >= size && bounds.outHeight / (sample * 2) >= size) {
            sample *= 2
        }
        return BitmapFactory.decodeFile(artPath, BitmapFactory.Options().apply { inSampleSize = sample })
    }

    // ---------------------------------------------------------------- mojibake repair

    // Latin-based code pages only: GBK/Big5/GB18030 could corrupt short Chinese titles.
    private val repairCharsets: List<Charset> by lazy {
        listOf("ISO-8859-1", "windows-1252", "windows-1254")
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
}