package com.shivaay20005.shivaaymusic.db.entities

import androidx.compose.runtime.Immutable
import androidx.room.Entity
import androidx.room.PrimaryKey
import java.time.LocalDateTime

@Immutable
@Entity(tableName = "user_level")
data class UserLevelEntity(
    @PrimaryKey val userId: String,
    val currentLevel: Int = 1,
    val currentXp: Long = 0,
    val nextLevelXp: Long = 100,
    val lastLevelUp: LocalDateTime? = null
)
