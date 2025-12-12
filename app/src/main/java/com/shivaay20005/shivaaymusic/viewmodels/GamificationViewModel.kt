package com.shivaay20005.shivaaymusic.viewmodels

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.shivaay20005.shivaaymusic.db.MusicDatabase
import com.shivaay20005.shivaaymusic.db.entities.*
import com.shivaay20005.shivaaymusic.models.Badge
import com.shivaay20005.shivaaymusic.models.BadgeDefinitions
import com.shivaay20005.shivaaymusic.models.DailyQuest
import com.shivaay20005.shivaaymusic.models.DailyQuestDefinitions
import com.shivaay20005.shivaaymusic.models.Reward
import com.shivaay20005.shivaaymusic.models.RewardDefinitions
import com.shivaay20005.shivaaymusic.utils.gamification.GamificationEngine
import com.shivaay20005.shivaaymusic.utils.gamification.LevelCalculator
import com.shivaay20005.shivaaymusic.utils.gamification.LevelProgress
import com.shivaay20005.shivaaymusic.utils.gamification.LevelUpResult
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.*
import kotlinx.coroutines.launch
import java.time.LocalDate
import javax.inject.Inject

@HiltViewModel
class GamificationViewModel @Inject constructor(
    private val database: MusicDatabase,
    private val gamificationEngine: GamificationEngine
) : ViewModel() {

    private val userId = GamificationEngine.DEFAULT_USER_ID

    // Level up state for showing dialog
    private val _levelUpEvent = MutableStateFlow<LevelUpResult?>(null)
    val levelUpEvent: StateFlow<LevelUpResult?> = _levelUpEvent.asStateFlow()

    // User stats
    val userStats: StateFlow<UserStatsEntity?> = database.getUserStats(userId)
        .stateIn(viewModelScope, SharingStarted.Lazily, null)

    // User level
    val userLevel: StateFlow<UserLevelEntity?> = database.getUserLevel(userId)
        .stateIn(viewModelScope, SharingStarted.Lazily, null)

    // Level progress
    val levelProgress: StateFlow<LevelProgress?> = userLevel
        .map { level ->
            level?.let { LevelCalculator.getLevelProgress(it.currentXp) }
        }
        .stateIn(viewModelScope, SharingStarted.Lazily, null)

    // Unlocked badges
    val unlockedBadges: StateFlow<List<Badge>> = database.getUserAchievements(userId)
        .map { achievements ->
            BadgeDefinitions.allBadges.filter { badge ->
                achievements.any { it.badgeKey == badge.key }
            }
        }
        .stateIn(viewModelScope, SharingStarted.Lazily, emptyList())

    // Unlocked rewards
    val unlockedRewards: StateFlow<List<Reward>> = database.getUserRewards(userId)
        .map { rewardEntities ->
            RewardDefinitions.allRewards.filter { reward ->
                rewardEntities.any { it.rewardKey == reward.key }
            }
        }
        .stateIn(viewModelScope, SharingStarted.Lazily, emptyList())

    // Daily quests
    val dailyQuests: StateFlow<List<DailyQuest>> = database.getDailyQuests(userId, LocalDate.now())
        .map { questEntities ->
            questEntities.map { entity ->
                val definition = DailyQuestDefinitions.allQuests.find { it.key == entity.questKey }
                DailyQuest(
                    key = entity.questKey,
                    title = definition?.title ?: "Quest",
                    description = definition?.description ?: "",
                    targetValue = entity.targetValue,
                    xpReward = entity.xpReward,
                    progress = entity.progress
                )
            }
        }
        .stateIn(viewModelScope, SharingStarted.Lazily, emptyList())

    // Next reward to unlock
    val nextReward: StateFlow<Reward?> = userLevel
        .map { level ->
            level?.let { RewardDefinitions.allRewards.filter { r -> r.requiredLevel > it.currentLevel }.minByOrNull { r -> r.requiredLevel } }
        }
        .stateIn(viewModelScope, SharingStarted.Lazily, null)

    // All badges (for display grid)
    val allBadges: StateFlow<List<Pair<Badge, Boolean>>> = unlockedBadges
        .map { unlocked ->
            BadgeDefinitions.allBadges.map { badge ->
                badge to unlocked.any { it.key == badge.key }
            }
        }
        .stateIn(viewModelScope, SharingStarted.Lazily, emptyList())

    init {
        viewModelScope.launch {
            gamificationEngine.initializeUser(userId)
        }
    }

    fun refreshQuests() {
        viewModelScope.launch {
            gamificationEngine.initializeDailyQuests(userId)
        }
    }

    fun testAddXp(amount: Long) {
        viewModelScope.launch {
            val result = gamificationEngine.addXp(userId, amount, "Test XP")
            if (result.leveledUp) {
                _levelUpEvent.value = result
            }
        }
    }

    fun dismissLevelUpDialog() {
        _levelUpEvent.value = null
    }

    suspend fun trackLevelUp(result: LevelUpResult) {
        if (result.leveledUp) {
            _levelUpEvent.value = result
        }
    }
}
