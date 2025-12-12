package com.shivaay20005.shivaaymusic.utils

import android.content.Context
import android.net.Uri
import androidx.core.content.edit
import androidx.core.net.toUri
import timber.log.Timber
import java.io.File
import java.io.FileOutputStream
import java.io.IOException

/** Saves a custom image for a playlist */
fun saveCustomPlaylistImage(context: Context, playlistId: String, imageUri: Uri) {
    try {
        // Create directory for playlist images if it doesn't exist
        val playlistImagesDir = File(context.filesDir, "playlist_images")
        if (!playlistImagesDir.exists()) {
            playlistImagesDir.mkdirs()
        }

        // File name based on the playlist ID (using the ID as String)
        val imageFile = File(playlistImagesDir, "playlist_${playlistId}.jpg")

        // Copy the selected image to the internal directory
        context.contentResolver.openInputStream(imageUri)?.use { input ->
            FileOutputStream(imageFile).use { output ->
                input.copyTo(output)
            }
        }

        // Save the reference in SharedPreferences
        context.getSharedPreferences("playlist_images", Context.MODE_PRIVATE).edit {
            putString("playlist_$playlistId", imageFile.toUri().toString())
        }
    } catch (e: IOException) {
        Timber.e(e, "Error saving playlist image")
    }
}

/** Gets the URI of the custom image for a playlist */
fun getPlaylistImageUri(context: Context, playlistId: String): Uri? {
    val uriString = context.getSharedPreferences("playlist_images", Context.MODE_PRIVATE)
        .getString("playlist_$playlistId", null)

    return if (uriString != null) {
        val uri = uriString.toUri()
        // Verify that the file exists
        val file = File(uri.path ?: "")
        if (file.exists()) uri else null
    } else null
}

/** Deletes the custom image of a playlist */
fun deletePlaylistImage(context: Context, playlistId: String) {
    val uriString = context.getSharedPreferences("playlist_images", Context.MODE_PRIVATE)
        .getString("playlist_$playlistId", null)

    if (uriString != null) {
        val file = File(uriString.toUri().path ?: "")
        if (file.exists()) {
            file.delete()
        }

        // Remove reference from SharedPreferences
        context.getSharedPreferences("playlist_images", Context.MODE_PRIVATE).edit {
            remove("playlist_$playlistId")
        }
    }
}
