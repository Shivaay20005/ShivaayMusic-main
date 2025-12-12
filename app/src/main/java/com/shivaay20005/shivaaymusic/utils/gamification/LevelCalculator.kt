package com.shivaay20005.shivaaymusic.utils.gamification

import kotlin.math.pow

object LevelCalculator {
    /**
     * Calculate the level from total XP using the formula: levelXP = 100 * level^1.4
     */
    fun calculateLevel(xp: Long): Int {
        if (xp < 0) return 1
        
        var level = 1
        var totalXpRequired = 0L
        
        while (totalXpRequired <= xp) {
            totalXpRequired += calculateXpForLevel(level)
            if (totalXpRequired <= xp) {
                level++
            }
        }
        
        return level
    }
    
    /**
     * Calculate XP required to reach a specific level from the previous level
     */
    fun calculateXpForLevel(level: Int): Long {
        return (100 * level.toDouble().pow(1.4)).toLong()
    }
    
    /**
     * Calculate total XP required to reach a specific level from level 1
     */
    fun calculateTotalXpForLevel(level: Int): Long {
        var totalXp = 0L
        for (i in 1 until level) {
            totalXp += calculateXpForLevel(i)
        }
        return totalXp
    }
    
    /**
     * Get XP progress information for current level
     */
    fun getLevelProgress(currentXp: Long): LevelProgress {
        val currentLevel = calculateLevel(currentXp)
        val totalXpForCurrentLevel = calculateTotalXpForLevel(currentLevel)
        val xpIntoCurrentLevel = currentXp - totalXpForCurrentLevel
        val xpNeededForNextLevel = calculateXpForLevel(currentLevel)
        val percentageToNext = if (xpNeededForNextLevel > 0) {
            (xpIntoCurrentLevel.toFloat() / xpNeededForNextLevel) * 100f
        } else {
            0f
        }
        
        return LevelProgress(
            currentLevel = currentLevel,
            currentXp = currentXp,
            xpIntoCurrentLevel = xpIntoCurrentLevel,
            xpNeededForNextLevel = xpNeededForNextLevel,
            percentageToNextLevel = percentageToNext
        )
    }
}

data class LevelProgress(
    val currentLevel: Int,
    val currentXp: Long,
    val xpIntoCurrentLevel: Long,
    val xpNeededForNextLevel: Long,
    val percentageToNextLevel: Float
)
