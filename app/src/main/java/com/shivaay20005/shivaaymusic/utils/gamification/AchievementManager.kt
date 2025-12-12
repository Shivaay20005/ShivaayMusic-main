package com.shivaay20005.shivaaymusic.utils.gamification

import com.shivaay20005.shivaaymusic.models.Badge
import com.shivaay20005.shivaaymusic.models.BadgeDefinitions
import com.shivaay20005.shivaaymusic.models.UnlockCondition

class AchievementManager {
    /**
     * Check which badges should be unlocked based on current stats
     */
    fun checkUnlockedBadges(
        totalListeningMs: Long,
        uniqueArtists: Int,
        songsLiked: Int,
        playlistsCreated: Int,
        genresDiscovered: Int,
        nightOwlListens: Int,
        currentStreak: Int
    ): List<Badge> {
        val unlockedBadges = mutableListOf<Badge>()
        val totalHours = totalListeningMs / (1000 * 60 * 60)
        
        BadgeDefinitions.allBadges.forEach { badge ->
            val shouldUnlock = when (val condition = badge.unlockCondition) {
                is UnlockCondition.ListeningHours -> totalHours >= condition.hours
                is UnlockCondition.ListeningStreak -> totalHours >= condition.days
                is UnlockCondition.SongsLiked -> songsLiked >= condition.count
                is UnlockCondition.PlaylistsCreated -> playlistsCreated >= condition.count
                is UnlockCondition.GenresExplored -> genresDiscovered >= condition.count
                is UnlockCondition.ArtistFan -> false // Requires artist-specific tracking
                is UnlockCondition.NightOwl -> nightOwlListens >= condition.listensAt2AM
                is UnlockCondition.WeeklyWarrior -> currentStreak >= condition.weekStreaks * 7
            }
            
            if (shouldUnlock) {
                unlockedBadges.add(badge)
            }
        }
        
        return unlockedBadges
    }
    
    /**
     * Check if a specific badge should be unlocked
     */
    fun shouldUnlockBadge(
        badge: Badge,
        totalListeningMs: Long,
        uniqueArtists: Int,
        songsLiked: Int,
        playlistsCreated: Int,
        genresDiscovered: Int,
        nightOwlListens: Int = 0,
        currentStreak: Int = 0
    ): Boolean {
        val totalHours = totalListeningMs / (1000 * 60 * 60)
        
        return when (val condition = badge.unlockCondition) {
            is UnlockCondition.ListeningHours -> totalHours >= condition.hours
            is UnlockCondition.ListeningStreak -> totalHours >= condition.days
            is UnlockCondition.SongsLiked -> songsLiked >= condition.count
            is UnlockCondition.PlaylistsCreated -> playlistsCreated >= condition.count
            is UnlockCondition.GenresExplored -> genresDiscovered >= condition.count
            is UnlockCondition.ArtistFan -> false
            is UnlockCondition.NightOwl -> nightOwlListens >= condition.listensAt2AM
            is UnlockCondition.WeeklyWarrior -> currentStreak >= condition.weekStreaks * 7
        }
    }
}
