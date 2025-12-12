package com.shivaay20005.shivaaymusic.ui.screens.profile

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.grid.GridCells
import androidx.compose.foundation.lazy.grid.LazyVerticalGrid
import androidx.compose.foundation.lazy.grid.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.navigation.NavController
import com.shivaay20005.shivaaymusic.models.Badge
import com.shivaay20005.shivaaymusic.models.DailyQuest
import com.shivaay20005.shivaaymusic.ui.components.LevelUpDialog
import com.shivaay20005.shivaaymusic.utils.gamification.LevelProgress
import com.shivaay20005.shivaaymusic.viewmodels.GamificationViewModel
import kotlinx.coroutines.launch

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun UserProfileScreen(
    navController: NavController,
    viewModel: GamificationViewModel = hiltViewModel()
) {
    val userStats by viewModel.userStats.collectAsState()
    val levelProgress by viewModel.levelProgress.collectAsState()
    val allBadges by viewModel.allBadges.collectAsState()
    val dailyQuests by viewModel.dailyQuests.collectAsState()
    val nextReward by viewModel.nextReward.collectAsState()
    val levelUpEvent by viewModel.levelUpEvent.collectAsState()

    // Show level-up dialog when event occurs
    LevelUpDialog(
        show = levelUpEvent != null,
        newLevel = levelUpEvent?.newLevel ?: 1,
        unlockedRewards = levelUpEvent?.unlockedRewards ?: emptyList(),
        onDismiss = { viewModel.dismissLevelUpDialog() }
    )

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Profile & Progress") },
                navigationIcon = {
                    IconButton(onClick = { navController.popBackStack() }) {
                        Text("←", fontSize = 24.sp)
                    }
                }
            )
        }
    ) { paddingValues ->
        LazyColumn(
            modifier = Modifier
                .fillMaxSize()
                .padding(paddingValues)
                .padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            // Header Section
            item {
                ProfileHeader(
                    levelProgress = levelProgress,
                    userStats = userStats
                )
            }

            // Daily Quests Section
            item {
                Text(
                    text = "Daily Quests",
                    style = MaterialTheme.typography.titleLarge,
                    fontWeight = FontWeight.Bold
                )
            }
            
            items(dailyQuests.size) { index ->
                DailyQuestCard(quest = dailyQuests[index])
            }

            // Achievements Section
            item {
                Text(
                    text = "Achievements",
                    style = MaterialTheme.typography.titleLarge,
                    fontWeight = FontWeight.Bold,
                    modifier = Modifier.padding(top = 16.dp)
                )
            }

            item {
                LazyVerticalGrid(
                    columns = GridCells.Fixed(3),
                    modifier = Modifier.height(300.dp),
                    horizontalArrangement = Arrangement.spacedBy(12.dp),
                    verticalArrangement = Arrangement.spacedBy(12.dp)
                ) {
                    items(allBadges) { (badge, unlocked) ->
                        BadgeCard(badge = badge, unlocked = unlocked)
                    }
                }
            }

            // Next Reward Section
            item {
                nextReward?.let { reward ->
                    NextRewardCard(
                        reward = reward,
                        currentLevel = levelProgress?.currentLevel ?: 1
                    )
                }
            }

            // Stats Section
            item {
                userStats?.let { stats ->
                    StatsCard(stats = stats)
                }
            }

            // Share Card Section
            item {
                ShareLevelCard(
                    level = levelProgress?.currentLevel ?: 1,
                    stats = userStats
                )
            }
        }
    }
}

@Composable
fun ProfileHeader(
    levelProgress: LevelProgress?,
    userStats: com.shivaay20005.shivaaymusic.db.entities.UserStatsEntity?
) {
    Card(
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(16.dp),
        colors = CardDefaults.cardColors(
            containerColor = MaterialTheme.colorScheme.primaryContainer
        )
    ) {
        Column(
            modifier = Modifier.padding(20.dp),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            // Level Badge
            Box(
                modifier = Modifier
                    .size(80.dp)
                    .clip(CircleShape)
                    .background(
                        Brush.linearGradient(
                            listOf(
                                MaterialTheme.colorScheme.primary,
                                MaterialTheme.colorScheme.secondary
                            )
                        )
                    ),
                contentAlignment = Alignment.Center
            ) {
                Column(horizontalAlignment = Alignment.CenterHorizontally) {
                    Text(
                        text = "LVL",
                        fontSize = 14.sp,
                        color = Color.White
                    )
                    Text(
                        text = "${levelProgress?.currentLevel ?: 1}",
                        fontSize = 24.sp,
                        fontWeight = FontWeight.Bold,
                        color = Color.White
                    )
                }
            }

            Spacer(modifier = Modifier.height(12.dp))

            Text(
                text = "Music Enthusiast",
                style = MaterialTheme.typography.titleLarge,
                fontWeight = FontWeight.Bold
            )

            Spacer(modifier = Modifier.height(8.dp))

            // XP Progress
            levelProgress?.let { progress ->
                Column(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalAlignment = Alignment.CenterHorizontally
                ) {
                    Text(
                        text = "${progress.xpIntoCurrentLevel} / ${progress.xpNeededForNextLevel} XP",
                        style = MaterialTheme.typography.bodyMedium
                    )
                    Spacer(modifier = Modifier.height(8.dp))
                    LinearProgressIndicator(
                        progress = progress.percentageToNextLevel / 100f,
                        modifier = Modifier
                            .fillMaxWidth()
                            .height(8.dp)
                            .clip(RoundedCornerShape(4.dp))
                    )
                }
            }
        }
    }
}

@Composable
fun DailyQuestCard(quest: DailyQuest) {
    Card(
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(12.dp)
    ) {
        Row(
            modifier = Modifier.padding(16.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Column(modifier = Modifier.weight(1f)) {
                Text(
                    text = quest.title,
                    style = MaterialTheme.typography.titleMedium,
                    fontWeight = FontWeight.Bold
                )
                Text(
                    text = quest.description,
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
                Spacer(modifier = Modifier.height(4.dp))
                Text(
                    text = "+${quest.xpReward} XP",
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.primary,
                    fontWeight = FontWeight.Bold
                )
            }
            Spacer(modifier = Modifier.width(12.dp))
            if (quest.isCompleted) {
                Text("✓", fontSize = 24.sp, color = MaterialTheme.colorScheme.primary)
            } else {
                CircularProgressIndicator(
                    progress = quest.progressPercentage / 100f,
                    modifier = Modifier.size(40.dp)
                )
            }
        }
    }
}

@Composable
fun BadgeCard(badge: Badge, unlocked: Boolean) {
    Card(
        modifier = Modifier
            .aspectRatio(1f)
            .fillMaxWidth(),
        shape = RoundedCornerShape(12.dp),
        colors = CardDefaults.cardColors(
            containerColor = if (unlocked)
                MaterialTheme.colorScheme.primaryContainer
            else
                MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.5f)
        )
    ) {
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(8.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.Center
        ) {
            Text(
                text = badge.icon,
                fontSize = 32.sp,
                modifier = Modifier.alpha(if (unlocked) 1f else 0.3f)
            )
            Spacer(modifier = Modifier.height(4.dp))
            Text(
                text = badge.title.substringAfter(" "),
                style = MaterialTheme.typography.bodySmall,
                fontWeight = FontWeight.Bold,
                modifier = Modifier.alpha(if (unlocked) 1f else 0.5f)
            )
        }
    }
}

@Composable
fun NextRewardCard(reward: com.shivaay20005.shivaaymusic.models.Reward, currentLevel: Int) {
    Card(
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(12.dp),
        colors = CardDefaults.cardColors(
            containerColor = MaterialTheme.colorScheme.secondaryContainer
        )
    ) {
        Column(modifier = Modifier.padding(16.dp)) {
            Text(
                text = "Next Unlock",
                style = MaterialTheme.typography.titleMedium,
                fontWeight = FontWeight.Bold
            )
            Spacer(modifier = Modifier.height(8.dp))
            Text(
                text = "Level ${reward.requiredLevel}: ${reward.name}",
                style = MaterialTheme.typography.bodyLarge
            )
            Text(
                text = reward.description,
                style = MaterialTheme.typography.bodySmall,
                color = MaterialTheme.colorScheme.onSecondaryContainer.copy(alpha = 0.7f)
            )
            Spacer(modifier = Modifier.height(4.dp))
            Text(
                text = "${reward.requiredLevel - currentLevel} levels to go!",
                style = MaterialTheme.typography.bodySmall,
                color = MaterialTheme.colorScheme.primary,
                fontWeight = FontWeight.Bold
            )
        }
    }
}

@Composable
fun StatsCard(stats: com.shivaay20005.shivaaymusic.db.entities.UserStatsEntity) {
    Card(
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(12.dp)
    ) {
        Column(modifier = Modifier.padding(16.dp)) {
            Text(
                text = "Your Stats",
                style = MaterialTheme.typography.titleMedium,
                fontWeight = FontWeight.Bold
            )
            Spacer(modifier = Modifier.height(12.dp))
            
            StatRow("🎵 Listening Time", "${stats.totalListeningMs / (1000 * 60 * 60)} hours")
            StatRow("🎤 Artists Discovered", "${stats.uniqueArtists}")
            StatRow("💙 Songs Liked", "${stats.songsLiked}")
            StatRow("📝 Playlists Created", "${stats.playlistsCreated}")
            StatRow("🌍 Genres Explored", "${stats.genresDiscovered}")
            StatRow("📅 Days Active", "${stats.daysActive}")
        }
    }
}

@Composable
fun StatRow(label: String, value: String) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(vertical = 4.dp),
        horizontalArrangement = Arrangement.SpaceBetween
    ) {
        Text(
            text = label,
            style = MaterialTheme.typography.bodyMedium
        )
        Text(
            text = value,
            style = MaterialTheme.typography.bodyMedium,
            fontWeight = FontWeight.Bold,
            color = MaterialTheme.colorScheme.primary
        )
    }
}

@Composable
private fun Modifier.alpha(alpha: Float): Modifier {
    return this.then(Modifier.graphicsLayer { this.alpha = alpha })
}

@Composable
fun ShareLevelCard(
    level: Int,
    stats: com.shivaay20005.shivaaymusic.db.entities.UserStatsEntity?
) {
    val context = LocalContext.current
    val scope = rememberCoroutineScope()
    
    Card(
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(12.dp),
        colors = CardDefaults.cardColors(
            containerColor = MaterialTheme.colorScheme.primaryContainer
        )
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            Text(
                text = "📸 Share Your Progress",
                style = MaterialTheme.typography.titleMedium,
                fontWeight = FontWeight.Bold,
                color = MaterialTheme.colorScheme.onPrimaryContainer
            )
            
            Spacer(modifier = Modifier.height(8.dp))
            
            Text(
                text = "Share your music journey with friends!",
                style = MaterialTheme.typography.bodySmall,
                color = MaterialTheme.colorScheme.onPrimaryContainer.copy(alpha = 0.7f)
            )
            
            Spacer(modifier = Modifier.height(12.dp))
            
            Button(
                onClick = {
                    scope.launch {
                        stats?.let { userStats ->
                            try {
                                val generator = com.shivaay20005.shivaaymusic.utils.gamification.ShareCardGenerator(context)
                                val file = generator.generateLevelCard(
                                    level = level,
                                    username = "Music Enthusiast",
                                    stats = userStats
                                )
                                
                                // Share the file
                                val uri = androidx.core.content.FileProvider.getUriForFile(
                                    context,
                                    "${context.packageName}.fileprovider",
                                    file
                                )
                                
                                val shareIntent = android.content.Intent(android.content.Intent.ACTION_SEND).apply {
                                    type = "image/png"
                                    putExtra(android.content.Intent.EXTRA_STREAM, uri)
                                    addFlags(android.content.Intent.FLAG_GRANT_READ_URI_PERMISSION)
                                }
                                
                                context.startActivity(
                                    android.content.Intent.createChooser(shareIntent, "Share your level")
                                )
                            } catch (e: Exception) {
                                // Handle error silently
                            }
                        }
                    }
                },
                modifier = Modifier.fillMaxWidth()
            ) {
                Text("Share Level Card")
            }
        }
    }
}
