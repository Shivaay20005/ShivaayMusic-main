package com.shivaay20005.shivaaymusic.ui.screens

import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.core.FastOutSlowInEasing
import androidx.compose.animation.core.RepeatMode
import androidx.compose.animation.core.animateFloat
import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.infiniteRepeatable
import androidx.compose.animation.core.rememberInfiniteTransition
import androidx.compose.animation.core.tween
import androidx.compose.animation.fadeIn
import androidx.compose.animation.slideInVertically
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.WindowInsets
import androidx.compose.foundation.layout.asPaddingValues
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.systemBars
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.alpha
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.scale
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.navigation.NavController
import com.shivaay20005.shivaaymusic.LocalDatabase
import com.shivaay20005.shivaaymusic.R
import com.shivaay20005.shivaaymusic.constants.SongSortType
import com.shivaay20005.shivaaymusic.ui.component.AchievementBadge
import com.shivaay20005.shivaaymusic.ui.component.ListeningStreakCard
import com.shivaay20005.shivaaymusic.ui.component.NavigationTitle
import com.shivaay20005.shivaaymusic.ui.component.WeeklyListeningSummaryCard

/**
 * ShivaayMusic Exclusive - Music Journey Screen
 * Shows the user's complete music journey with stats, achievements, and memories
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun MusicJourneyScreen(
    navController: NavController,
) {
    val database = LocalDatabase.current
    
    // Collect stats from database using existing queries
    val songs by database.songs(SongSortType.CREATE_DATE, true).collectAsState(initial = emptyList())
    val totalSongsPlayed = songs.size
    
    // Get unique artists from songs
    val totalArtists = remember(songs) { 
        songs.flatMap { it.artists }.distinctBy { it.id }.size 
    }
    
    // Sample data - in real implementation, this would come from database
    val currentStreak = remember { 5 } // Would be calculated from listening history
    val longestStreak = remember { 12 }
    val todayListeningMinutes = remember { 45 }
    val weeklyMinutes = remember { listOf(30, 45, 60, 20, 55, 90, 75) }
    
    // Calculate achievements
    val achievements = remember(totalSongsPlayed, currentStreak) {
        listOf(
            AchievementData(
                emoji = "🎵",
                titleResId = R.string.achievement_first_song,
                descResId = R.string.achievement_first_song_desc,
                isUnlocked = totalSongsPlayed >= 1
            ),
            AchievementData(
                emoji = "❤️",
                titleResId = R.string.achievement_10_songs,
                descResId = R.string.achievement_10_songs_desc,
                isUnlocked = totalSongsPlayed >= 10
            ),
            AchievementData(
                emoji = "🎹",
                titleResId = R.string.achievement_100_songs,
                descResId = R.string.achievement_100_songs_desc,
                isUnlocked = totalSongsPlayed >= 100
            ),
            AchievementData(
                emoji = "👑",
                titleResId = R.string.achievement_1000_songs,
                descResId = R.string.achievement_1000_songs_desc,
                isUnlocked = totalSongsPlayed >= 1000
            ),
            AchievementData(
                emoji = "🔥",
                titleResId = R.string.achievement_streak_7,
                descResId = R.string.achievement_streak_7_desc,
                isUnlocked = currentStreak >= 7
            ),
            AchievementData(
                emoji = "🏆",
                titleResId = R.string.achievement_streak_30,
                descResId = R.string.achievement_streak_30_desc,
                isUnlocked = currentStreak >= 30
            ),
        )
    }
    
    Scaffold(
        topBar = {
            TopAppBar(
                title = {
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        Text(
                            text = "✨",
                            fontSize = 24.sp,
                        )
                        Spacer(modifier = Modifier.width(8.dp))
                        Text(
                            text = stringResource(R.string.music_journey),
                            style = MaterialTheme.typography.titleLarge,
                            fontWeight = FontWeight.Bold,
                        )
                    }
                },
                navigationIcon = {
                    IconButton(onClick = { navController.navigateUp() }) {
                        Icon(
                            painter = painterResource(R.drawable.arrow_back),
                            contentDescription = null
                        )
                    }
                }
            )
        }
    ) { paddingValues ->
        LazyColumn(
            modifier = Modifier
                .fillMaxSize()
                .padding(paddingValues),
            contentPadding = WindowInsets.systemBars.asPaddingValues()
        ) {
            // Listening Streak Card
            item {
                ListeningStreakCard(
                    currentStreak = currentStreak,
                    longestStreak = longestStreak,
                    todayListeningMinutes = todayListeningMinutes,
                    dailyGoalMinutes = 30,
                )
            }
            
            // Weekly Summary
            item {
                WeeklyListeningSummaryCard(
                    weeklyMinutes = weeklyMinutes,
                )
            }
            
            // Stats Overview
            item {
                Spacer(modifier = Modifier.height(8.dp))
                NavigationTitle(title = stringResource(R.string.stats))
            }
            
            item {
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(horizontal = 16.dp),
                    horizontalArrangement = Arrangement.SpaceEvenly,
                ) {
                    StatCard(
                        emoji = "🎵",
                        value = "$totalSongsPlayed",
                        label = stringResource(R.string.songs),
                        modifier = Modifier.weight(1f)
                    )
                    Spacer(modifier = Modifier.width(12.dp))
                    StatCard(
                        emoji = "🎤",
                        value = "$totalArtists",
                        label = stringResource(R.string.artists),
                        modifier = Modifier.weight(1f)
                    )
                    Spacer(modifier = Modifier.width(12.dp))
                    StatCard(
                        emoji = "⏱️",
                        value = "${weeklyMinutes.sum() / 60}h",
                        label = stringResource(R.string.music_journey_total_hours),
                        modifier = Modifier.weight(1f)
                    )
                }
            }
            
            // Achievements Section
            item {
                Spacer(modifier = Modifier.height(16.dp))
                NavigationTitle(title = stringResource(R.string.achievements))
            }
            
            item {
                LazyRow(
                    modifier = Modifier.padding(horizontal = 8.dp),
                    horizontalArrangement = Arrangement.spacedBy(12.dp)
                ) {
                    items(achievements) { achievement ->
                        AchievementBadge(
                            emoji = achievement.emoji,
                            title = stringResource(achievement.titleResId),
                            description = stringResource(achievement.descResId),
                            isUnlocked = achievement.isUnlocked,
                            modifier = Modifier.width(100.dp)
                        )
                    }
                }
            }
            
            // Music Memories (placeholder for future)
            item {
                Spacer(modifier = Modifier.height(16.dp))
                NavigationTitle(title = stringResource(R.string.music_memories))
            }
            
            item {
                Card(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(horizontal = 16.dp, vertical = 8.dp),
                    shape = RoundedCornerShape(16.dp),
                    colors = CardDefaults.cardColors(
                        containerColor = MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.5f)
                    )
                ) {
                    Column(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(24.dp),
                        horizontalAlignment = Alignment.CenterHorizontally,
                    ) {
                        Text(
                            text = "📝",
                            fontSize = 48.sp,
                        )
                        Spacer(modifier = Modifier.height(12.dp))
                        Text(
                            text = stringResource(R.string.music_memories_empty),
                            style = MaterialTheme.typography.bodyMedium,
                            textAlign = TextAlign.Center,
                            color = MaterialTheme.colorScheme.onSurfaceVariant.copy(alpha = 0.7f),
                        )
                    }
                }
            }
            
            // Bottom spacing
            item {
                Spacer(modifier = Modifier.height(100.dp))
            }
        }
    }
}

@Composable
fun StatCard(
    emoji: String,
    value: String,
    label: String,
    modifier: Modifier = Modifier,
) {
    val infiniteTransition = rememberInfiniteTransition(label = "statAnimation")
    val scale by infiniteTransition.animateFloat(
        initialValue = 1f,
        targetValue = 1.05f,
        animationSpec = infiniteRepeatable(
            animation = tween(2000, easing = FastOutSlowInEasing),
            repeatMode = RepeatMode.Reverse
        ),
        label = "scale"
    )
    
    Card(
        modifier = modifier,
        shape = RoundedCornerShape(16.dp),
        colors = CardDefaults.cardColors(
            containerColor = MaterialTheme.colorScheme.primaryContainer.copy(alpha = 0.5f)
        )
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
        ) {
            Text(
                text = emoji,
                fontSize = 28.sp,
                modifier = Modifier.scale(scale)
            )
            Spacer(modifier = Modifier.height(8.dp))
            Text(
                text = value,
                style = MaterialTheme.typography.headlineSmall,
                fontWeight = FontWeight.Bold,
                color = MaterialTheme.colorScheme.primary,
            )
            Text(
                text = label,
                style = MaterialTheme.typography.labelSmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant.copy(alpha = 0.7f),
            )
        }
    }
}

data class AchievementData(
    val emoji: String,
    val titleResId: Int,
    val descResId: Int,
    val isUnlocked: Boolean,
)
