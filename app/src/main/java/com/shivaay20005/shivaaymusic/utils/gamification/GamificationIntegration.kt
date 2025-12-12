package com.shivaay20005.shivaaymusic.utils.gamification

import android.content.Context
import com.shivaay20005.shivaaymusic.constants.GamificationEnabledKey
import com.shivaay20005.shivaaymusic.utils.dataStore
import dagger.hilt.android.qualifiers.ApplicationContext
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.launch
import javax.inject.Inject
import javax.inject.Singleton

/**
 * Integration class to hook gamification into the app's lifecycle events
 */
@Singleton
class GamificationIntegration @Inject constructor(
    @ApplicationContext private val context: Context,
    private val gamificationEngine: GamificationEngine
) {
    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.IO)
    
    private suspend fun isGamificationEnabled(): Boolean {
        return context.dataStore.data.first()[GamificationEnabledKey] ?: true
    }

    /**
     * Call when a song is listened to completion or significant duration
     */
    fun onSongListened(songId: String, playDurationMs: Long) {
        scope.launch {
            if (!isGamificationEnabled()) return@launch
            try {
                gamificationEngine.onSongListened(songId = songId, playDurationMs = playDurationMs)
            } catch (e: Exception) {
                // Silently fail to not disrupt music playback
            }
        }
    }

    /**
     * Call when a user likes a song
     */
    fun onSongLiked() {
        scope.launch {
            if (!isGamificationEnabled()) return@launch
            try {
                gamificationEngine.onSongLiked()
            } catch (e: Exception) {
                // Silently fail
            }
        }
    }

    /**
     * Call when a user creates a playlist
     */
    fun onPlaylistCreated() {
        scope.launch {
            if (!isGamificationEnabled()) return@launch
            try {
                gamificationEngine.onPlaylistCreated()
            } catch (e: Exception) {
                // Silently fail
            }
        }
    }

    /**
     * Call when a user discovers a new artist
     */
    fun onArtistDiscovered() {
        scope.launch {
            if (!isGamificationEnabled()) return@launch
            try {
                gamificationEngine.onArtistDiscovered()
            } catch (e: Exception) {
                // Silently fail
            }
        }
    }

    /**
     * Initialize gamification for the user
     */
    fun initialize() {
        scope.launch {
            if (!isGamificationEnabled()) return@launch
            try {
                gamificationEngine.initializeUser()
                // Sync counts from database
                syncCounts()
            } catch (e: Exception) {
                // Silently fail
            }
        }
    }

    /**
     * Sync artist and playlist counts from database
     */
    fun syncCounts() {
        scope.launch {
            if (!isGamificationEnabled()) return@launch
            try {
                gamificationEngine.syncArtistCount()
                gamificationEngine.syncPlaylistCount()
            } catch (e: Exception) {
                // Silently fail
            }
        }
    }
}
