package com.shivaay20005.shivaaymusic.db.entities

import androidx.compose.runtime.Immutable
import androidx.room.Entity
import java.time.LocalDateTime

@Immutable
@Entity(
    tableName = "user_achievements",
    primaryKeys = ["userId", "badgeKey"]
)
data class UserAchievementEntity(
    val userId: String,
    val badgeKey: String,
    val unlockedAt: LocalDateTime = LocalDateTime.now()
)
