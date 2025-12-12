package com.shivaay20005.shivaaymusic.utils.gamification

import com.shivaay20005.shivaaymusic.db.MusicDatabase
import com.shivaay20005.shivaaymusic.db.entities.*
import com.shivaay20005.shivaaymusic.models.Badge
import com.shivaay20005.shivaaymusic.models.BadgeDefinitions
import com.shivaay20005.shivaaymusic.models.Reward
import com.shivaay20005.shivaaymusic.models.RewardDefinitions
import kotlinx.coroutines.flow.first
import java.time.LocalDate
import java.time.LocalDateTime
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class GamificationEngine @Inject constructor(
    private val database: MusicDatabase
) {
    companion object {
        const val DEFAULT_USER_ID = "default_user"
    }

    private val achievementManager = AchievementManager()
    private val rewardManager = RewardManager()
    private val dailyQuestManager = DailyQuestManager()

    /**
     * Initialize gamification data for a user
     */
    suspend fun initializeUser(userId: String = DEFAULT_USER_ID) {
        val stats = database.getUserStats(userId).first()
        if (stats == null) {
            database.insertUserStats(UserStatsEntity(userId = userId))
        }

        val level = database.getUserLevel(userId).first()
        if (level == null) {
            database.insertUserLevel(UserLevelEntity(userId = userId))
        }

        // Initialize daily quests if needed
        initializeDailyQuests(userId)
    }

    /**
     * Add XP to a user and handle level ups
     */
    suspend fun addXp(
        userId: String = DEFAULT_USER_ID,
        xpAmount: Long,
        reason: String = ""
    ): LevelUpResult {
        val userLevel = database.getUserLevel(userId).first()
            ?: UserLevelEntity(userId = userId)

        val oldLevel = userLevel.currentLevel
        val newXp = userLevel.currentXp + xpAmount
        val levelProgress = LevelCalculator.getLevelProgress(newXp)
        val newLevel = levelProgress.currentLevel

        val updatedUserLevel = userLevel.copy(
            currentXp = newXp,
            currentLevel = newLevel,
            nextLevelXp = levelProgress.xpNeededForNextLevel,
            lastLevelUp = if (newLevel > oldLevel) LocalDateTime.now() else userLevel.lastLevelUp
        )

        database.insertUserLevel(updatedUserLevel)

        // Check for new rewards if leveled up
        val newRewards = if (newLevel > oldLevel) {
            rewardManager.getRewardsForLevel(newLevel).also { rewards ->
                rewards.forEach { reward ->
                    database.insertUserReward(
                        UserRewardEntity(
                            userId = userId,
                            rewardKey = reward.key,
                            unlockedLevel = newLevel
                        )
                    )
                }
            }
        } else {
            emptyList()
        }

        return LevelUpResult(
            leveledUp = newLevel > oldLevel,
            oldLevel = oldLevel,
            newLevel = newLevel,
            newXp = newXp,
            unlockedRewards = newRewards
        )
    }

    /**
     * Update user stats and recalculate XP
     */
    suspend fun updateStats(
        userId: String = DEFAULT_USER_ID,
        totalListeningMs: Long? = null,
        uniqueArtists: Int? = null,
        songsLiked: Int? = null,
        playlistsCreated: Int? = null,
        daysActive: Int? = null,
        genresDiscovered: Int? = null
    ) {
        val currentStats = database.getUserStats(userId).first()
            ?: UserStatsEntity(userId = userId)

        val updatedStats = currentStats.copy(
            totalListeningMs = totalListeningMs ?: currentStats.totalListeningMs,
            uniqueArtists = uniqueArtists ?: currentStats.uniqueArtists,
            songsLiked = songsLiked ?: currentStats.songsLiked,
            playlistsCreated = playlistsCreated ?: currentStats.playlistsCreated,
            daysActive = daysActive ?: currentStats.daysActive,
            genresDiscovered = genresDiscovered ?: currentStats.genresDiscovered,
            updatedAt = LocalDateTime.now()
        )

        database.insertUserStats(updatedStats)

        // Recalculate total XP from stats
        val totalXp = XpCalculator.calculateTotalXp(
            totalListeningMs = updatedStats.totalListeningMs,
            uniqueArtists = updatedStats.uniqueArtists,
            songsLiked = updatedStats.songsLiked,
            playlistsCreated = updatedStats.playlistsCreated,
            daysActive = updatedStats.daysActive,
            genresDiscovered = updatedStats.genresDiscovered
        )

        // Update level based on total XP
        val levelProgress = LevelCalculator.getLevelProgress(totalXp)
        val currentLevel = database.getUserLevel(userId).first()
            ?: UserLevelEntity(userId = userId)

        database.insertUserLevel(
            currentLevel.copy(
                currentXp = totalXp,
                currentLevel = levelProgress.currentLevel,
                nextLevelXp = levelProgress.xpNeededForNextLevel
            )
        )

        // Check for newly unlocked badges
        checkAndUnlockBadges(userId, updatedStats)
    }

    /**
     * Check and unlock badges based on current stats
     */
    private suspend fun checkAndUnlockBadges(
        userId: String,
        stats: UserStatsEntity
    ) {
        val unlockedBadges = achievementManager.checkUnlockedBadges(
            totalListeningMs = stats.totalListeningMs,
            uniqueArtists = stats.uniqueArtists,
            songsLiked = stats.songsLiked,
            playlistsCreated = stats.playlistsCreated,
            genresDiscovered = stats.genresDiscovered,
            nightOwlListens = 0, // TODO: Track this separately
            currentStreak = 0 // TODO: Track this separately
        )

        unlockedBadges.forEach { badge ->
            if (database.hasAchievement(userId, badge.key) == 0) {
                database.insertUserAchievement(
                    UserAchievementEntity(
                        userId = userId,
                        badgeKey = badge.key
                    )
                )
            }
        }
    }

    /**
     * Initialize daily quests for a user
     */
    suspend fun initializeDailyQuests(userId: String = DEFAULT_USER_ID) {
        val today = LocalDate.now()
        val existingQuests = database.getDailyQuests(userId, today).first()

        if (existingQuests.isEmpty()) {
            dailyQuestManager.generateDailyQuests(today).forEach { quest ->
                database.insertDailyQuest(
                    DailyQuestEntity(
                        userId = userId,
                        questKey = quest.key,
                        questDate = today,
                        progress = 0,
                        targetValue = quest.targetValue,
                        xpReward = quest.xpReward,
                        completed = false
                    )
                )
            }
        }

        // Clean up old quests
        database.deleteOldQuests(userId, today.minusDays(7))
    }

    /**
     * Update quest progress
     */
    suspend fun updateQuestProgress(
        userId: String = DEFAULT_USER_ID,
        questKey: String,
        progressIncrement: Int
    ) {
        val today = LocalDate.now()
        val quests = database.getDailyQuests(userId, today).first()
        val quest = quests.find { it.questKey == questKey } ?: return

        if (!quest.completed) {
            val newProgress = (quest.progress + progressIncrement).coerceAtMost(quest.targetValue)
            val completed = newProgress >= quest.targetValue

            val updatedQuest = quest.copy(
                progress = newProgress,
                completed = completed
            )

            database.updateDailyQuest(updatedQuest)

            // Award XP if quest just completed
            if (completed && !quest.completed) {
                addXp(userId, quest.xpReward.toLong(), "Completed quest: $questKey")
            }
        }
    }

    /**
     * Handle song listen event for XP and quests
     */
    suspend fun onSongListened(
        userId: String = DEFAULT_USER_ID,
        songId: String,
        playDurationMs: Long
    ) {
        // Validate with anti-cheat
        val validation = AntiCheatValidator.validateListeningSession(songId, playDurationMs)
        if (!validation.isValid()) return

        // Update stats
        val stats = database.getUserStats(userId).first()
            ?: UserStatsEntity(userId = userId)

        updateStats(
            userId = userId,
            totalListeningMs = stats.totalListeningMs + playDurationMs
        )

        // Update listening quest
        updateQuestProgress(userId, "listen_20_minutes", playDurationMs.toInt())
    }

    /**
     * Handle song liked event
     */
    suspend fun onSongLiked(userId: String = DEFAULT_USER_ID) {
        val stats = database.getUserStats(userId).first()
            ?: UserStatsEntity(userId = userId)

        updateStats(
            userId = userId,
            songsLiked = stats.songsLiked + 1
        )

        updateQuestProgress(userId, "like_5_songs", 1)
    }

    /**
     * Handle playlist created event
     */
    suspend fun onPlaylistCreated(userId: String = DEFAULT_USER_ID) {
        val validation = AntiCheatValidator.validatePlaylistCreation()
        if (!validation.isValid()) return

        val stats = database.getUserStats(userId).first()
            ?: UserStatsEntity(userId = userId)

        updateStats(
            userId = userId,
            playlistsCreated = stats.playlistsCreated + 1
        )
    }

    /**
     * Handle artist discovered event
     */
    suspend fun onArtistDiscovered(userId: String = DEFAULT_USER_ID) {
        val stats = database.getUserStats(userId).first()
            ?: UserStatsEntity(userId = userId)

        updateStats(
            userId = userId,
            uniqueArtists = stats.uniqueArtists + 1
        )

        updateQuestProgress(userId, "discover_artist", 1)
    }
}

data class LevelUpResult(
    val leveledUp: Boolean,
    val oldLevel: Int,
    val newLevel: Int,
    val newXp: Long,
    val unlockedRewards: List<Reward>
)
