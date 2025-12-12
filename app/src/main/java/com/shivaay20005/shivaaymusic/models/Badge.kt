package com.shivaay20005.shivaaymusic.models

data class Badge(
    val key: String,
    val title: String,
    val icon: String,
    val description: String,
    val unlockCondition: UnlockCondition
)

sealed class UnlockCondition {
    data class ListeningHours(val hours: Int) : UnlockCondition()
    data class ListeningStreak(val days: Int) : UnlockCondition()
    data class SongsLiked(val count: Int) : UnlockCondition()
    data class PlaylistsCreated(val count: Int) : UnlockCondition()
    data class GenresExplored(val count: Int) : UnlockCondition()
    data class ArtistFan(val artistId: String, val hours: Int) : UnlockCondition()
    data class NightOwl(val listensAt2AM: Int) : UnlockCondition()
    data class WeeklyWarrior(val weekStreaks: Int) : UnlockCondition()
}

object BadgeDefinitions {
    val allBadges = listOf(
        Badge(
            key = "1_hour_listener",
            title = "🎧 1 Hour Listener",
            icon = "🎧",
            description = "Listened to music for 1 hour total",
            unlockCondition = UnlockCondition.ListeningHours(1)
        ),
        Badge(
            key = "10_hour_streak",
            title = "🔥 10 Hour Streak",
            icon = "🔥",
            description = "Listened for 10 hours in total",
            unlockCondition = UnlockCondition.ListeningHours(10)
        ),
        Badge(
            key = "100_likes_club",
            title = "💙 100 Likes Club",
            icon = "💙",
            description = "Liked 100 songs",
            unlockCondition = UnlockCondition.SongsLiked(100)
        ),
        Badge(
            key = "playlist_maker",
            title = "🧩 Playlist Maker",
            icon = "🧩",
            description = "Created 5 playlists",
            unlockCondition = UnlockCondition.PlaylistsCreated(5)
        ),
        Badge(
            key = "genre_explorer",
            title = "🌎 Genre Explorer",
            icon = "🌎",
            description = "Discovered 10 different genres",
            unlockCondition = UnlockCondition.GenresExplored(10)
        ),
        Badge(
            key = "night_owl",
            title = "🕒 Night Owl",
            icon = "🕒",
            description = "Listened to music at 2 AM multiple times",
            unlockCondition = UnlockCondition.NightOwl(5)
        ),
        Badge(
            key = "weekly_warrior",
            title = "🚀 Weekly Warrior",
            icon = "🚀",
            description = "Maintained a 7-day listening streak",
            unlockCondition = UnlockCondition.WeeklyWarrior(1)
        )
    )
}
