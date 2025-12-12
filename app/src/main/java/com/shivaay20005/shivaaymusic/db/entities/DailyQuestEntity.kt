package com.shivaay20005.shivaaymusic.db.entities

import androidx.compose.runtime.Immutable
import androidx.room.Entity
import androidx.room.PrimaryKey
import java.time.LocalDate

@Immutable
@Entity(tableName = "daily_quests")
data class DailyQuestEntity(
    @PrimaryKey(autoGenerate = true) val id: Long = 0,
    val userId: String,
    val questKey: String,
    val questDate: LocalDate,
    val progress: Int = 0,
    val targetValue: Int,
    val xpReward: Int,
    val completed: Boolean = false
)
