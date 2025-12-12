package com.shivaay20005.shivaaymusic.db.entities

import androidx.compose.runtime.Immutable
import androidx.room.Entity
import androidx.room.PrimaryKey
import java.time.LocalDateTime

@Immutable
@Entity(tableName = "user_stats")
data class UserStatsEntity(
    @PrimaryKey val userId: String,
    val totalListeningMs: Long = 0,
    val uniqueArtists: Int = 0,
    val songsLiked: Int = 0,
    val playlistsCreated: Int = 0,
    val daysActive: Int = 0,
    val genresDiscovered: Int = 0,
    val updatedAt: LocalDateTime = LocalDateTime.now()
)
