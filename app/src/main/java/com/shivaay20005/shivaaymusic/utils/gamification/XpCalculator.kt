package com.shivaay20005.shivaaymusic.utils.gamification

object XpCalculator {
    // XP values for different actions
    const val XP_PER_LISTENING_HOUR = 10L
    const val XP_PER_UNIQUE_ARTIST = 20L
    const val XP_PER_SONG_LIKED = 5L
    const val XP_PER_PLAYLIST_CREATED = 30L
    const val XP_PER_DAY_ACTIVE = 15L
    const val XP_PER_NEW_GENRE = 25L
    const val XP_PER_SHARE = 40L
    const val XP_PER_NEW_FEATURE = 50L
    
    /**
     * Calculate XP from listening time in milliseconds
     */
    fun calculateListeningXp(listeningTimeMs: Long): Long {
        val hours = listeningTimeMs / (1000 * 60 * 60)
        return hours * XP_PER_LISTENING_HOUR
    }
    
    /**
     * Calculate total XP from all user stats
     */
    fun calculateTotalXp(
        totalListeningMs: Long,
        uniqueArtists: Int,
        songsLiked: Int,
        playlistsCreated: Int,
        daysActive: Int,
        genresDiscovered: Int
    ): Long {
        val listeningXp = calculateListeningXp(totalListeningMs)
        val artistXp = uniqueArtists * XP_PER_UNIQUE_ARTIST
        val likedXp = songsLiked * XP_PER_SONG_LIKED
        val playlistXp = playlistsCreated * XP_PER_PLAYLIST_CREATED
        val activeXp = daysActive * XP_PER_DAY_ACTIVE
        val genreXp = genresDiscovered * XP_PER_NEW_GENRE
        
        return listeningXp + artistXp + likedXp + playlistXp + activeXp + genreXp
    }
    
    /**
     * Calculate XP for a single action
     */
    fun getXpForAction(action: UserAction): Long {
        return when (action) {
            is UserAction.ListenedForHours -> action.hours * XP_PER_LISTENING_HOUR
            is UserAction.DiscoveredArtist -> XP_PER_UNIQUE_ARTIST
            is UserAction.LikedSong -> XP_PER_SONG_LIKED
            is UserAction.CreatedPlaylist -> XP_PER_PLAYLIST_CREATED
            is UserAction.ActiveDay -> XP_PER_DAY_ACTIVE
            is UserAction.DiscoveredGenre -> XP_PER_NEW_GENRE
            is UserAction.SharedContent -> XP_PER_SHARE
            is UserAction.TriedNewFeature -> XP_PER_NEW_FEATURE
        }
    }
}

sealed class UserAction {
    data class ListenedForHours(val hours: Long) : UserAction()
    object DiscoveredArtist : UserAction()
    object LikedSong : UserAction()
    object CreatedPlaylist : UserAction()
    object ActiveDay : UserAction()
    object DiscoveredGenre : UserAction()
    object SharedContent : UserAction()
    object TriedNewFeature : UserAction()
}
