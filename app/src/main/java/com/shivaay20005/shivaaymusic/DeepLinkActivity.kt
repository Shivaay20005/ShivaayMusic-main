package com.shivaay20005.shivaaymusic

import android.content.Intent
import android.net.Uri
import android.os.Bundle
import android.util.Log
import android.widget.Toast
import androidx.activity.ComponentActivity
import androidx.core.net.toUri
import androidx.lifecycle.lifecycleScope
import com.shivaay20005.innertube.YouTube
import com.shivaay20005.innertube.models.WatchEndpoint
import com.shivaay20005.shivaaymusic.db.MusicDatabase
import com.shivaay20005.shivaaymusic.models.toMediaMetadata
import com.shivaay20005.shivaaymusic.playback.MusicService
import com.shivaay20005.shivaaymusic.playback.PlayerConnection
import com.shivaay20005.shivaaymusic.playback.queues.YouTubeQueue
import com.shivaay20005.shivaaymusic.utils.reportException
import dagger.hilt.android.AndroidEntryPoint
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import java.net.URLDecoder
import javax.inject.Inject

/**
 * Activity to handle deep links from https://shivaaymusic.app/play and shivaaymusic:// scheme.
 * Extracts videoId or playlistId from the URL parameter and starts playback.
 */
@AndroidEntryPoint
class DeepLinkActivity : ComponentActivity() {

    @Inject
    lateinit var database: MusicDatabase

    companion object {
        private const val TAG = "DeepLinkActivity"
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        handleDeepLink(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        handleDeepLink(intent)
    }

    private fun handleDeepLink(intent: Intent?) {
        val uri = intent?.data
        if (uri == null) {
            Log.w(TAG, "No URI in intent")
            launchMainActivity()
            return
        }

        Log.d(TAG, "Handling deep link: $uri")

        // Extract the url parameter
        val encodedUrl = uri.getQueryParameter("url")
        if (encodedUrl.isNullOrBlank()) {
            Log.w(TAG, "No url parameter found")
            launchMainActivity()
            return
        }

        val decodedUrl = try {
            URLDecoder.decode(encodedUrl, "UTF-8")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to decode URL", e)
            launchMainActivity()
            return
        }

        Log.d(TAG, "Decoded URL: $decodedUrl")

        // Parse the YouTube URL
        val youtubeUri = decodedUrl.toUri()
        parseAndPlayYouTubeUrl(youtubeUri)
    }

    private fun parseAndPlayYouTubeUrl(uri: Uri) {
        val host = uri.host ?: ""
        val path = uri.pathSegments.firstOrNull() ?: ""

        when {
            // Playlist: youtube.com/playlist?list=...
            path == "playlist" -> {
                val playlistId = uri.getQueryParameter("list")
                if (playlistId != null) {
                    handlePlaylist(playlistId)
                } else {
                    Log.w(TAG, "No playlist ID found")
                    launchMainActivity()
                }
            }

            // Video: youtube.com/watch?v=... or youtu.be/...
            path == "watch" -> {
                val videoId = uri.getQueryParameter("v")
                val playlistId = uri.getQueryParameter("list")
                if (videoId != null) {
                    handleVideo(videoId, playlistId)
                } else {
                    Log.w(TAG, "No video ID found")
                    launchMainActivity()
                }
            }

            // Short URL: youtu.be/VIDEO_ID
            host == "youtu.be" -> {
                val videoId = uri.pathSegments.firstOrNull()
                val playlistId = uri.getQueryParameter("list")
                if (videoId != null) {
                    handleVideo(videoId, playlistId)
                } else {
                    Log.w(TAG, "No video ID found in short URL")
                    launchMainActivity()
                }
            }

            // Embed: youtube.com/embed/VIDEO_ID
            path == "embed" -> {
                val videoId = uri.pathSegments.getOrNull(1)
                if (videoId != null) {
                    handleVideo(videoId, null)
                } else {
                    Log.w(TAG, "No video ID found in embed URL")
                    launchMainActivity()
                }
            }

            // Channel: youtube.com/channel/... or youtube.com/c/...
            path == "channel" || path == "c" || path == "user" -> {
                val artistId = uri.pathSegments.getOrNull(1) ?: uri.lastPathSegment
                if (artistId != null) {
                    handleArtist(artistId)
                } else {
                    Log.w(TAG, "No artist ID found")
                    launchMainActivity()
                }
            }

            // Album browse: youtube.com/browse/MPREb_...
            path == "browse" -> {
                val browseId = uri.lastPathSegment
                if (browseId != null) {
                    handleAlbum(browseId)
                } else {
                    Log.w(TAG, "No browse ID found")
                    launchMainActivity()
                }
            }

            else -> {
                Log.w(TAG, "Unknown URL format: $uri")
                launchMainActivity()
            }
        }
    }

    private fun handleVideo(videoId: String, playlistId: String?) {
        Log.d(TAG, "Playing video: $videoId, playlist: $playlistId")

        // Start music service
        startService(Intent(this, MusicService::class.java))

        lifecycleScope.launch {
            try {
                withContext(Dispatchers.IO) {
                    YouTube.queue(listOf(videoId))
                }.onSuccess { songs ->
                    val firstSong = songs.firstOrNull()
                    if (firstSong != null) {
                        PlayerConnection.instance?.playQueue(
                            YouTubeQueue(
                                WatchEndpoint(
                                    videoId = firstSong.id,
                                    playlistId = playlistId
                                ),
                                firstSong.toMediaMetadata()
                            )
                        )
                        Toast.makeText(
                            this@DeepLinkActivity,
                            getString(R.string.now_playing_format, firstSong.title),
                            Toast.LENGTH_SHORT
                        ).show()
                    }
                    launchMainActivity()
                }.onFailure { e ->
                    Log.e(TAG, "Failed to load video", e)
                    reportException(e)
                    Toast.makeText(
                        this@DeepLinkActivity,
                        getString(R.string.error_loading_content),
                        Toast.LENGTH_SHORT
                    ).show()
                    launchMainActivity()
                }
            } catch (e: Exception) {
                Log.e(TAG, "Error playing video", e)
                reportException(e)
                launchMainActivity()
            }
        }
    }

    private fun handlePlaylist(playlistId: String) {
        Log.d(TAG, "Opening playlist: $playlistId")

        val intent = Intent(this, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_CLEAR_TOP or Intent.FLAG_ACTIVITY_SINGLE_TOP
            action = Intent.ACTION_VIEW
            data = "shivaaymusic://playlist/$playlistId".toUri()
        }
        startActivity(intent)
        finish()
    }

    private fun handleArtist(artistId: String) {
        Log.d(TAG, "Opening artist: $artistId")

        val intent = Intent(this, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_CLEAR_TOP or Intent.FLAG_ACTIVITY_SINGLE_TOP
            action = Intent.ACTION_VIEW
            data = "shivaaymusic://artist/$artistId".toUri()
        }
        startActivity(intent)
        finish()
    }

    private fun handleAlbum(browseId: String) {
        Log.d(TAG, "Opening album: $browseId")

        val intent = Intent(this, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_CLEAR_TOP or Intent.FLAG_ACTIVITY_SINGLE_TOP
            action = Intent.ACTION_VIEW
            data = "shivaaymusic://album/$browseId".toUri()
        }
        startActivity(intent)
        finish()
    }

    private fun launchMainActivity() {
        val intent = Intent(this, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_CLEAR_TOP or Intent.FLAG_ACTIVITY_SINGLE_TOP
        }
        startActivity(intent)
        finish()
    }
}
