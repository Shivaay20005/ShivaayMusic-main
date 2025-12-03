package com.shivaay20005.shivaaymusic.models

import com.shivaay20005.innertube.models.YTItem

/**
 * ShivaayMusic Exclusive - Smart Recommendation System
 * 
 * This model represents different types of smart recommendations:
 * - Based on currently playing artist
 * - Based on user's mood preferences
 * - Based on listening history patterns
 * - Based on time of day
 * - Based on genre preferences
 */

/**
 * Represents the mood/vibe of music based on listening patterns
 */
enum class MusicMood {
    ENERGETIC,      // Workout, party music
    RELAXED,        // Calm, peaceful music
    HAPPY,          // Upbeat, cheerful music
    SAD,            // Melancholic, emotional music
    FOCUSED,        // Concentration, study music
    ROMANTIC,       // Love songs, romantic ballads
    PARTY,          // Dance, club music
    SLEEPY,         // Sleep, ambient music
    UNKNOWN         // Default when we can't determine
}

/**
 * Represents the time-based context for recommendations
 */
enum class ListeningContext {
    MORNING,        // 6 AM - 12 PM
    AFTERNOON,      // 12 PM - 5 PM
    EVENING,        // 5 PM - 9 PM
    NIGHT,          // 9 PM - 12 AM
    LATE_NIGHT      // 12 AM - 6 AM
}

/**
 * Data class for smart recommendations with context
 */
data class SmartRecommendation(
    val title: String,
    val subtitle: String,
    val emoji: String,
    val items: List<YTItem>,
    val recommendationType: RecommendationType,
    val priority: Int = 0  // Higher priority = shown first
)

/**
 * Types of recommendations the engine can generate
 */
enum class RecommendationType {
    ARTIST_BASED,           // "Because you listen to [Artist]"
    MOOD_BASED,             // "Music for your mood"
    RECENTLY_PLAYED,        // "Recently played"
    SIMILAR_SONGS,          // "Songs like [Song]"
    GENRE_BASED,            // "More [Genre]"
    TIME_BASED,             // "Good morning/evening picks"
    DISCOVER_WEEKLY,        // "Discover new music"
    TOP_PICKS,              // "Your top picks"
    TRENDING,               // "Trending now"
    BASED_ON_HISTORY,       // "Based on your listening"
    MIXED_FOR_YOU           // "Mixed for you"
}

/**
 * User listening profile for personalized recommendations
 */
data class UserListeningProfile(
    val topArtistIds: List<String>,
    val topGenres: List<String>,
    val preferredMood: MusicMood,
    val averageListeningTime: Long,
    val peakListeningHour: Int,
    val totalSongsPlayed: Int,
    val favoriteDecade: String? = null
)

/**
 * Artist similarity score for recommendations
 */
data class ArtistSimilarity(
    val artistId: String,
    val artistName: String,
    val similarityScore: Float,  // 0.0 to 1.0
    val commonGenres: List<String>
)
