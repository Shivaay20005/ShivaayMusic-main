package com.shivaay20005.shivaaymusic.utils.gamification

import com.shivaay20005.shivaaymusic.models.Reward
import com.shivaay20005.shivaaymusic.models.RewardDefinitions

class RewardManager {
    /**
     * Get all rewards that should be unlocked at a specific level
     */
    fun getRewardsForLevel(level: Int): List<Reward> {
        return RewardDefinitions.allRewards.filter { it.requiredLevel == level }
    }
    
    /**
     * Get all rewards unlocked up to and including the current level
     */
    fun getAllUnlockedRewards(currentLevel: Int): List<Reward> {
        return RewardDefinitions.allRewards.filter { it.requiredLevel <= currentLevel }
    }
    
    /**
     * Get the next upcoming reward to unlock
     */
    fun getNextReward(currentLevel: Int): Reward? {
        return RewardDefinitions.allRewards
            .filter { it.requiredLevel > currentLevel }
            .minByOrNull { it.requiredLevel }
    }
    
    /**
     * Check if a reward is unlocked at the current level
     */
    fun isRewardUnlocked(reward: Reward, currentLevel: Int): Boolean {
        return reward.requiredLevel <= currentLevel
    }
    
    /**
     * Get all rewards grouped by level
     */
    fun getRewardsByLevel(): Map<Int, List<Reward>> {
        return RewardDefinitions.allRewards.groupBy { it.requiredLevel }
    }
}
