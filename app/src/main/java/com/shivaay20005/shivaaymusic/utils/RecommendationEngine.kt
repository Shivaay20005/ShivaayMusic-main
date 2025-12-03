package com.shivaay20005.shivaaymusic.utils

import com.shivaay20005.innertube.YouTube
import com.shivaay20005.innertube.models.AlbumItem
import com.shivaay20005.innertube.models.ArtistItem
import com.shivaay20005.innertube.models.PlaylistItem
import com.shivaay20005.innertube.models.SongItem
import com.shivaay20005.innertube.models.WatchEndpoint
import com.shivaay20005.innertube.models.YTItem
import com.shivaay20005.shivaaymusic.db.MusicDatabase
import com.shivaay20005.shivaaymusic.db.entities.Artist
import com.shivaay20005.shivaaymusic.db.entities.Song
import com.shivaay20005.shivaaymusic.models.ListeningContext
import com.shivaay20005.shivaaymusic.models.MusicMood
import com.shivaay20005.shivaaymusic.models.RecommendationType
import com.shivaay20005.shivaaymusic.models.SmartRecommendation
import com.shivaay20005.shivaaymusic.models.UserListeningProfile
import kotlinx.coroutines.flow.first
import java.util.Calendar

/**
 * ShivaayMusic Exclusive - Smart Recommendation Engine
 * 
 * A next-level recommendation system that provides personalized music recommendations
 * based on:
 * - Current playing artist
 * - User's mood and listening patterns
 * - Time of day
 * - Genre preferences
 * - Recently played songs
 */
object RecommendationEngine {

    /**
     * Get the current listening context based on time of day
     */
    fun getCurrentContext(): ListeningContext {
        val hour = Calendar.getInstance().get(Calendar.HOUR_OF_DAY)
        return when (hour) {
            in 6..11 -> ListeningContext.MORNING
            in 12..16 -> ListeningContext.AFTERNOON
            in 17..20 -> ListeningContext.EVENING
            in 21..23 -> ListeningContext.NIGHT
            else -> ListeningContext.LATE_NIGHT
        }
    }

    /**
     * Get context-based greeting and emoji
     */
    fun getContextGreeting(): Pair<String, String> {
        return when (getCurrentContext()) {
            ListeningContext.MORNING -> "Good Morning" to "🌅"
            ListeningContext.AFTERNOON -> "Good Afternoon" to "☀️"
            ListeningContext.EVENING -> "Good Evening" to "🌆"
            ListeningContext.NIGHT -> "Good Night" to "🌙"
            ListeningContext.LATE_NIGHT -> "Late Night Vibes" to "🌃"
        }
    }

    /**
     * Get mood-based search query for recommendations
     */
    fun getMoodSearchQuery(mood: MusicMood): String {
        return when (mood) {
            MusicMood.ENERGETIC -> "energetic workout pump up songs"
            MusicMood.RELAXED -> "relaxing calm peaceful music"
            MusicMood.HAPPY -> "happy upbeat feel good songs"
            MusicMood.SAD -> "sad emotional songs"
            MusicMood.FOCUSED -> "focus concentration study music"
            MusicMood.ROMANTIC -> "romantic love songs bollywood"
            MusicMood.PARTY -> "party dance club songs"
            MusicMood.SLEEPY -> "sleep ambient relaxing music"
            MusicMood.UNKNOWN -> "trending popular songs"
        }
    }

    /**
     * Get time-based music recommendations query
     */
    fun getTimeBasedQuery(): String {
        return when (getCurrentContext()) {
            ListeningContext.MORNING -> "morning motivation energetic songs"
            ListeningContext.AFTERNOON -> "afternoon chill music"
            ListeningContext.EVENING -> "evening relaxing songs"
            ListeningContext.NIGHT -> "night lofi chill beats"
            ListeningContext.LATE_NIGHT -> "late night peaceful songs"
        }
    }

    /**
     * Generate smart recommendations based on artist
     */
    suspend fun getArtistBasedRecommendations(
        artist: Artist,
        limit: Int = 15
    ): SmartRecommendation? {
        if (!artist.artist.isYouTubeArtist) return null
        
        return try {
            val items = mutableListOf<YTItem>()
            YouTube.artist(artist.id).onSuccess { page ->
                // Get songs from artist's popular section
                page.sections.forEach { section ->
                    items += section.items.take(5)
                }
            }
            
            if (items.isEmpty()) return null
            
            SmartRecommendation(
                title = "Because you listen to ${artist.artist.name}",
                subtitle = "More from artists like ${artist.artist.name}",
                emoji = "🎤",
                items = items.shuffled().take(limit),
                recommendationType = RecommendationType.ARTIST_BASED,
                priority = 10
            )
        } catch (e: Exception) {
            null
        }
    }

    /**
     * Generate recommendations based on a specific song
     */
    suspend fun getSongBasedRecommendations(
        song: Song,
        limit: Int = 15
    ): SmartRecommendation? {
        return try {
            val endpoint = YouTube.next(WatchEndpoint(videoId = song.id))
                .getOrNull()?.relatedEndpoint ?: return null
            
            val page = YouTube.related(endpoint).getOrNull() ?: return null
            
            val items = (page.songs.take(8) + 
                        page.albums.take(4) + 
                        page.artists.take(3))
                .shuffled()
                .take(limit)
            
            if (items.isEmpty()) return null
            
            SmartRecommendation(
                title = "Because you played ${song.title}",
                subtitle = "Songs similar to what you're enjoying",
                emoji = "🎵",
                items = items,
                recommendationType = RecommendationType.SIMILAR_SONGS,
                priority = 9
            )
        } catch (e: Exception) {
            null
        }
    }

    /**
     * Generate time-based recommendations
     */
    suspend fun getTimeBasedRecommendations(limit: Int = 12): SmartRecommendation? {
        return try {
            val (greeting, emoji) = getContextGreeting()
            val query = getTimeBasedQuery()
            
            val items = mutableListOf<YTItem>()
            YouTube.searchSummary(query).onSuccess { page ->
                items += page.songs.take(8)
                items += page.albums.take(4)
            }
            
            if (items.isEmpty()) return null
            
            SmartRecommendation(
                title = "$greeting Picks",
                subtitle = "Perfect music for this time of day",
                emoji = emoji,
                items = items.shuffled().take(limit),
                recommendationType = RecommendationType.TIME_BASED,
                priority = 7
            )
        } catch (e: Exception) {
            null
        }
    }

    /**
     * Generate trending/popular recommendations
     */
    suspend fun getTrendingRecommendations(limit: Int = 15): SmartRecommendation? {
        return try {
            val items = mutableListOf<YTItem>()
            YouTube.home().onSuccess { page ->
                page.sections.forEach { section ->
                    items += section.items.take(4)
                }
            }
            
            if (items.isEmpty()) return null
            
            SmartRecommendation(
                title = "Trending Now",
                subtitle = "What's popular right now",
                emoji = "🔥",
                items = items.shuffled().take(limit),
                recommendationType = RecommendationType.TRENDING,
                priority = 6
            )
        } catch (e: Exception) {
            null
        }
    }

    /**
     * Generate "Discover New" recommendations for exploration
     */
    suspend fun getDiscoverRecommendations(limit: Int = 12): SmartRecommendation? {
        return try {
            val currentYear = java.util.Calendar.getInstance().get(java.util.Calendar.YEAR)
            val queries = listOf(
                "new music $currentYear",
                "indie music discovery",
                "underground artists",
                "fresh releases",
                "new artists to discover"
            )
            
            val items = mutableListOf<YTItem>()
            val randomQuery = queries.random()
            
            YouTube.searchSummary(randomQuery).onSuccess { page ->
                items += page.songs.take(8)
                items += page.albums.take(4)
            }
            
            if (items.isEmpty()) return null
            
            SmartRecommendation(
                title = "Discover Something New",
                subtitle = "Explore fresh music you haven't heard",
                emoji = "✨",
                items = items.shuffled().take(limit),
                recommendationType = RecommendationType.DISCOVER_WEEKLY,
                priority = 5
            )
        } catch (e: Exception) {
            null
        }
    }

    /**
     * Generate mood-based mix
     */
    suspend fun getMoodMix(mood: MusicMood, limit: Int = 12): SmartRecommendation? {
        return try {
            val query = getMoodSearchQuery(mood)
            val items = mutableListOf<YTItem>()
            
            YouTube.searchSummary(query).onSuccess { page ->
                items += page.songs.take(10)
                items += page.albums.take(4)
            }
            
            if (items.isEmpty()) return null
            
            val (title, emoji) = when (mood) {
                MusicMood.ENERGETIC -> "Energy Boost" to "⚡"
                MusicMood.RELAXED -> "Chill Vibes" to "😌"
                MusicMood.HAPPY -> "Feel Good Mix" to "😊"
                MusicMood.SAD -> "In My Feelings" to "💙"
                MusicMood.FOCUSED -> "Deep Focus" to "🎯"
                MusicMood.ROMANTIC -> "Love Songs" to "💕"
                MusicMood.PARTY -> "Party Mode" to "🎉"
                MusicMood.SLEEPY -> "Sleep Sounds" to "🌙"
                MusicMood.UNKNOWN -> "Your Mix" to "🎶"
            }
            
            SmartRecommendation(
                title = title,
                subtitle = "Curated for your current mood",
                emoji = emoji,
                items = items.shuffled().take(limit),
                recommendationType = RecommendationType.MOOD_BASED,
                priority = 8
            )
        } catch (e: Exception) {
            null
        }
    }

    /**
     * Generate "Mixed For You" personalized playlist
     */
    suspend fun getMixedForYou(
        database: MusicDatabase,
        limit: Int = 20
    ): SmartRecommendation? {
        return try {
            val fromTimeStamp = System.currentTimeMillis() - 86400000 * 14 // 2 weeks
            
            // Get top artists
            val topArtists = database.mostPlayedArtists(fromTimeStamp, limit = 5)
                .first()
                .filter { it.artist.isYouTubeArtist }
            
            // Get songs from each artist
            val items = mutableListOf<YTItem>()
            topArtists.shuffled().take(3).forEach { artist ->
                YouTube.artist(artist.id).onSuccess { page ->
                    page.sections.firstOrNull()?.items?.take(4)?.let { songs ->
                        items += songs
                    }
                }
            }
            
            // Add some trending items
            YouTube.home().onSuccess { page ->
                page.sections.firstOrNull()?.items?.take(6)?.let { trending ->
                    items += trending
                }
            }
            
            if (items.isEmpty()) return null
            
            SmartRecommendation(
                title = "Mixed For You",
                subtitle = "A personalized mix based on your taste",
                emoji = "💫",
                items = items.shuffled().take(limit),
                recommendationType = RecommendationType.MIXED_FOR_YOU,
                priority = 10
            )
        } catch (e: Exception) {
            null
        }
    }

    /**
     * Get all smart recommendations for the home screen
     */
    suspend fun getAllSmartRecommendations(
        database: MusicDatabase,
        currentSong: Song? = null
    ): List<SmartRecommendation> {
        val recommendations = mutableListOf<SmartRecommendation>()
        
        val fromTimeStamp = System.currentTimeMillis() - 86400000 * 14 // 2 weeks
        
        // 1. Mixed For You (highest priority)
        getMixedForYou(database)?.let { recommendations += it }
        
        // 2. Based on current song
        currentSong?.let { song ->
            getSongBasedRecommendations(song)?.let { recommendations += it }
        }
        
        // 3. Based on top artists
        val topArtists = database.mostPlayedArtists(fromTimeStamp, limit = 3)
            .first()
            .filter { it.artist.isYouTubeArtist }
        
        topArtists.shuffled().take(2).forEach { artist ->
            getArtistBasedRecommendations(artist)?.let { recommendations += it }
        }
        
        // 4. Time-based recommendations
        getTimeBasedRecommendations()?.let { recommendations += it }
        
        // 5. Trending
        getTrendingRecommendations()?.let { recommendations += it }
        
        // 6. Discover new
        getDiscoverRecommendations()?.let { recommendations += it }
        
        // Sort by priority (higher first)
        return recommendations.sortedByDescending { it.priority }
    }
}
