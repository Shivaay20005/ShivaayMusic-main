package com.shivaay20005.shivaaymusic.models

data class DailyQuest(
    val key: String,
    val title: String,
    val description: String,
    val targetValue: Int,
    val xpReward: Int,
    val progress: Int = 0
) {
    val isCompleted: Boolean
        get() = progress >= targetValue
    
    val progressPercentage: Float
        get() = if (targetValue > 0) (progress.toFloat() / targetValue) * 100f else 0f
}

object DailyQuestDefinitions {
    val allQuests = listOf(
        DailyQuest(
            key = "listen_20_minutes",
            title = "Music Time",
            description = "Listen to music for 20 minutes",
            targetValue = 20 * 60 * 1000, // in milliseconds
            xpReward = 20
        ),
        DailyQuest(
            key = "like_5_songs",
            title = "Show Some Love",
            description = "Like 5 songs",
            targetValue = 5,
            xpReward = 10
        ),
        DailyQuest(
            key = "discover_artist",
            title = "Music Discovery",
            description = "Discover 1 new artist",
            targetValue = 1,
            xpReward = 20
        )
    )
}
