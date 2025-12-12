package com.shivaay20005.shivaaymusic.utils

import android.content.Context
import android.content.Intent
import android.net.Uri
import java.net.URLEncoder
import java.nio.charset.StandardCharsets

/**
 * Utility class for generating and handling ShivaayMusic deep links.
 */
object DeepLinkUtils {

    private const val BASE_URL = "https://shivaaymusic.com"

    /**
     * Generate a share link for a YouTube video ID.
     *
     * @param videoId The YouTube video ID
     * @param playlistId Optional playlist ID
     * @return The ShivaayMusic share link URL
     */
    fun generateVideoShareLink(videoId: String, playlistId: String? = null): String {
        return buildString {
            append("$BASE_URL/watch?v=")
            append(videoId)
            if (playlistId != null) {
                append("&list=")
                append(playlistId)
            }
        }
    }

    /**
     * Generate a share link for a YouTube playlist ID.
     *
     * @param playlistId The YouTube playlist ID
     * @return The ShivaayMusic share link URL
     */
    fun generatePlaylistShareLink(playlistId: String): String {
        return "$BASE_URL/playlist?list=$playlistId"
    }

    /**
     * Generate a share link for a YouTube channel/artist ID.
     *
     * @param channelId The YouTube channel ID
     * @return The ShivaayMusic share link URL
     */
    fun generateArtistShareLink(channelId: String): String {
        return "$BASE_URL/channel/$channelId"
    }

    /**
     * Generate a share link for a YouTube Music album browse ID.
     *
     * @param browseId The YouTube Music browse ID (album)
     * @return The ShivaayMusic share link URL
     */
    fun generateAlbumShareLink(browseId: String): String {
        return "$BASE_URL/browse/$browseId"
    }

    /**
     * Share a YouTube video using ShivaayMusic deep link.
     *
     * @param context The context
     * @param videoId The YouTube video ID
     * @param title Optional title for the share intent
     * @param playlistId Optional playlist ID
     */
    fun shareVideo(
        context: Context,
        videoId: String,
        title: String? = null,
        playlistId: String? = null
    ) {
        val shareLink = generateVideoShareLink(videoId, playlistId)
        share(context, shareLink, title)
    }

    /**
     * Share a YouTube playlist using ShivaayMusic deep link.
     *
     * @param context The context
     * @param playlistId The YouTube playlist ID
     * @param title Optional title for the share intent
     */
    fun sharePlaylist(context: Context, playlistId: String, title: String? = null) {
        val shareLink = generatePlaylistShareLink(playlistId)
        share(context, shareLink, title)
    }

    /**
     * Share an artist/channel using ShivaayMusic deep link.
     *
     * @param context The context
     * @param channelId The YouTube channel ID
     * @param name Optional artist name for the share intent
     */
    fun shareArtist(context: Context, channelId: String, name: String? = null) {
        val shareLink = generateArtistShareLink(channelId)
        share(context, shareLink, name)
    }

    /**
     * Share an album using ShivaayMusic deep link.
     *
     * @param context The context
     * @param browseId The YouTube Music browse ID
     * @param title Optional album title for the share intent
     */
    fun shareAlbum(context: Context, browseId: String, title: String? = null) {
        val shareLink = generateAlbumShareLink(browseId)
        share(context, shareLink, title)
    }

    /**
     * Generic share function.
     *
     * @param context The context
     * @param link The link to share
     * @param title Optional title/subject
     */
    private fun share(context: Context, link: String, title: String? = null) {
        val shareIntent = Intent(Intent.ACTION_SEND).apply {
            type = "text/plain"
            putExtra(Intent.EXTRA_TEXT, link)
            if (title != null) {
                putExtra(Intent.EXTRA_SUBJECT, title)
            }
        }
        context.startActivity(Intent.createChooser(shareIntent, null))
    }

    /**
     * Check if a URL is a valid YouTube or ShivaayMusic URL.
     *
     * @param url The URL to check
     * @return true if valid URL
     */
    fun isValidShareUrl(url: String): Boolean {
        return try {
            val uri = Uri.parse(url)
            val host = uri.host ?: return false
            val validHosts = listOf(
                "youtube.com", "www.youtube.com", "m.youtube.com",
                "music.youtube.com", "youtu.be",
                "shivaaymusic.com", "www.shivaaymusic.com"
            )
            validHosts.any { host == it || host.endsWith(".$it") }
        } catch (e: Exception) {
            false
        }
    }

    /**
     * Extract video ID from a YouTube or ShivaayMusic URL.
     *
     * @param url The URL
     * @return The video ID or null if not found
     */
    fun extractVideoId(url: String): String? {
        return try {
            val uri = Uri.parse(url)
            when {
                uri.host == "youtu.be" -> uri.pathSegments.firstOrNull()
                uri.pathSegments.firstOrNull() == "watch" -> uri.getQueryParameter("v")
                uri.pathSegments.firstOrNull() == "embed" -> uri.pathSegments.getOrNull(1)
                uri.pathSegments.firstOrNull() == "v" -> uri.pathSegments.getOrNull(1)
                else -> null
            }
        } catch (e: Exception) {
            null
        }
    }

    /**
     * Extract playlist ID from a URL.
     *
     * @param url The URL
     * @return The playlist ID or null if not found
     */
    fun extractPlaylistId(url: String): String? {
        return try {
            val uri = Uri.parse(url)
            uri.getQueryParameter("list")
        } catch (e: Exception) {
            null
        }
    }
}
