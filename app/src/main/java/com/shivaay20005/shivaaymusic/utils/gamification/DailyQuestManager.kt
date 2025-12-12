package com.shivaay20005.shivaaymusic.utils.gamification

import com.shivaay20005.shivaaymusic.models.DailyQuest
import com.shivaay20005.shivaaymusic.models.DailyQuestDefinitions
import java.time.LocalDate

class DailyQuestManager {
    /**
     * Generate daily quests for a specific date
     */
    fun generateDailyQuests(date: LocalDate = LocalDate.now()): List<DailyQuest> {
        // Return all available quests
        return DailyQuestDefinitions.allQuests
    }
    
    /**
     * Check if quests should be reset (new day)
     */
    fun shouldResetQuests(lastQuestDate: LocalDate, currentDate: LocalDate = LocalDate.now()): Boolean {
        return lastQuestDate.isBefore(currentDate)
    }
    
    /**
     * Update quest progress
     */
    fun updateQuestProgress(
        quest: DailyQuest,
        progressIncrement: Int
    ): DailyQuest {
        val newProgress = (quest.progress + progressIncrement).coerceAtMost(quest.targetValue)
        return quest.copy(progress = newProgress)
    }
    
    /**
     * Calculate total XP reward from completed quests
     */
    fun calculateTotalQuestXp(quests: List<DailyQuest>): Int {
        return quests.filter { it.isCompleted }.sumOf { it.xpReward }
    }
    
    /**
     * Get incomplete quests
     */
    fun getIncompleteQuests(quests: List<DailyQuest>): List<DailyQuest> {
        return quests.filter { !it.isCompleted }
    }
    
    /**
     * Get completed quests
     */
    fun getCompletedQuests(quests: List<DailyQuest>): List<DailyQuest> {
        return quests.filter { it.isCompleted }
    }
}
