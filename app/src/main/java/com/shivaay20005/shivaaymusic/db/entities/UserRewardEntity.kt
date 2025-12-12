package com.shivaay20005.shivaaymusic.db.entities

import androidx.compose.runtime.Immutable
import androidx.room.Entity
import java.time.LocalDateTime

@Immutable
@Entity(
    tableName = "user_rewards",
    primaryKeys = ["userId", "rewardKey"]
)
data class UserRewardEntity(
    val userId: String,
    val rewardKey: String,
    val unlockedLevel: Int,
    val unlockedAt: LocalDateTime = LocalDateTime.now()
)
