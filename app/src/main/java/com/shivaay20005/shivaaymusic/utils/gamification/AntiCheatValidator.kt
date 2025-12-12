package com.shivaay20005.shivaaymusic.utils.gamification

object AntiCheatValidator {
    // Anti-cheat thresholds
    private const val MIN_PLAY_DURATION_MS = 20_000L // 20 seconds
    private const val MAX_PLAYLISTS_PER_MINUTE = 3
    private const val MIN_TIME_BETWEEN_SAME_SONG_MS = 60_000L // 1 minute
    
    private val recentSongPlays = mutableMapOf<String, Long>()
    private val playlistCreationTimes = mutableListOf<Long>()
    
    /**
     * Validate if listening session should grant XP
     */
    fun validateListeningSession(
        songId: String,
        playDurationMs: Long,
        currentTimeMs: Long = System.currentTimeMillis()
    ): ValidationResult {
        // Check minimum play duration
        if (playDurationMs < MIN_PLAY_DURATION_MS) {
            return ValidationResult.Invalid("Play duration too short (< 20 seconds)")
        }
        
        // Check for repeated plays of same song
        val lastPlayTime = recentSongPlays[songId]
        if (lastPlayTime != null) {
            val timeSinceLastPlay = currentTimeMs - lastPlayTime
            if (timeSinceLastPlay < MIN_TIME_BETWEEN_SAME_SONG_MS) {
                return ValidationResult.Invalid("Same song played too quickly")
            }
        }
        
        // Update tracking
        recentSongPlays[songId] = currentTimeMs
        cleanupOldEntries(currentTimeMs)
        
        return ValidationResult.Valid
    }
    
    /**
     * Validate if playlist creation should grant XP
     */
    fun validatePlaylistCreation(
        currentTimeMs: Long = System.currentTimeMillis()
    ): ValidationResult {
        // Add current creation time
        playlistCreationTimes.add(currentTimeMs)
        
        // Remove entries older than 1 minute
        val oneMinuteAgo = currentTimeMs - 60_000L
        playlistCreationTimes.removeAll { it < oneMinuteAgo }
        
        // Check rate limit
        if (playlistCreationTimes.size > MAX_PLAYLISTS_PER_MINUTE) {
            return ValidationResult.Invalid("Too many playlists created in short time")
        }
        
        return ValidationResult.Valid
    }
    
    /**
     * Clean up old entries to prevent memory leaks
     */
    private fun cleanupOldEntries(currentTimeMs: Long) {
        val fiveMinutesAgo = currentTimeMs - 300_000L
        recentSongPlays.entries.removeIf { it.value < fiveMinutesAgo }
    }
    
    /**
     * Reset validator state (useful for testing)
     */
    fun reset() {
        recentSongPlays.clear()
        playlistCreationTimes.clear()
    }
}

sealed class ValidationResult {
    object Valid : ValidationResult()
    data class Invalid(val reason: String) : ValidationResult()
    
    fun isValid(): Boolean = this is Valid
}
