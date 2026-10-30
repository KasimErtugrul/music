package com.example.resonance.mediastore

import android.content.ContentProvider
import android.content.ContentValues
import android.database.Cursor
import android.net.Uri
import android.os.ParcelFileDescriptor
import java.io.File
import java.io.FileNotFoundException

/**
 * content://<applicationId>.artwork/art/<songId>.jpg
 *
 * Android Auto is a separate process and cannot read file:// paths in the app's private cache.
 * This provider builds the artwork from MediaStore, caches it and returns a file descriptor.
 */
class ArtworkProvider : ContentProvider() {

    override fun onCreate(): Boolean = true

    override fun getType(uri: Uri): String = "image/jpeg"

    override fun openFile(uri: Uri, mode: String): ParcelFileDescriptor {
        if (mode != "r") throw FileNotFoundException("read-only provider")
        val ctx = context ?: throw FileNotFoundException("no context")
        val id = parseId(uri) ?: throw FileNotFoundException("bad uri")

        val dir = File(ctx.cacheDir, CACHE_DIR).apply { mkdirs() }
        val file = File(dir, "$id.jpg")
        var created = false
        if (!file.exists() || file.length() == 0L) {
            val bytes = MediaStoreBridge.loadArtworkBytes(ctx.contentResolver, id, ART_SIZE)
                ?: throw FileNotFoundException("no artwork")
            val tmp = File(dir, "$id.${System.nanoTime()}.tmp")
            try {
                tmp.writeBytes(bytes)
                if (!tmp.renameTo(file)) throw FileNotFoundException("write failed")
                created = true
            } finally {
                if (tmp.exists()) tmp.delete()
            }
        }
        // Open first, trim afterwards: a trimmed file stays readable through the open descriptor.
        val pfd = ParcelFileDescriptor.open(file, ParcelFileDescriptor.MODE_READ_ONLY)
        if (created) trimCache(dir)
        return pfd
    }

    private fun parseId(uri: Uri): Long? {
        val segs = uri.pathSegments
        if (segs.size != 2 || segs[0] != "art") return null
        return segs[1].removeSuffix(".jpg").toLongOrNull()?.takeIf { it > 0 }
    }

    private fun trimCache(dir: File) {
        val files = dir.listFiles() ?: return
        if (files.size <= MAX_CACHED) return
        files.sortedBy { it.lastModified() }
            .take(files.size - MAX_CACHED)
            .forEach { it.delete() }
    }

    override fun query(
        uri: Uri, projection: Array<out String>?, selection: String?,
        selectionArgs: Array<out String>?, sortOrder: String?,
    ): Cursor? = null

    override fun insert(uri: Uri, values: ContentValues?): Uri? = null
    override fun update(
        uri: Uri, values: ContentValues?, selection: String?, selectionArgs: Array<out String>?,
    ): Int = 0

    override fun delete(uri: Uri, selection: String?, selectionArgs: Array<out String>?): Int = 0

    private companion object {
        const val CACHE_DIR = "provider_art"
        const val ART_SIZE = 512
        const val MAX_CACHED = 500
    }
}