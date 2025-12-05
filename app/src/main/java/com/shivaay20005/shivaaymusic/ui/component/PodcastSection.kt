package com.shivaay20005.shivaaymusic.ui.component

import androidx.compose.animation.core.FastOutSlowInEasing
import androidx.compose.animation.core.RepeatMode
import androidx.compose.animation.core.animateFloat
import androidx.compose.animation.core.infiniteRepeatable
import androidx.compose.animation.core.rememberInfiniteTransition
import androidx.compose.animation.core.tween
import androidx.compose.foundation.ExperimentalFoundationApi
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.combinedClickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.aspectRatio
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.offset
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.grid.GridCells
import androidx.compose.foundation.lazy.grid.LazyHorizontalGrid
import androidx.compose.foundation.lazy.grid.items
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.scale
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.shivaay20005.shivaaymusic.R

/**
 * ShivaayMusic Exclusive - Podcast Categories
 */
data class PodcastCategory(
    val nameResId: Int,
    val emoji: String,
    val searchQuery: String,
    val gradientColors: List<Color>
)

val podcastCategories = listOf(
    PodcastCategory(
        R.string.podcast_entertainment,
        "🎭",
        "entertainment podcast hindi",
        listOf(Color(0xFFFF6B6B), Color(0xFFFF8E53))
    ),
    PodcastCategory(
        R.string.podcast_education,
        "📚",
        "education podcast learning",
        listOf(Color(0xFF4ECDC4), Color(0xFF44A08D))
    ),
    PodcastCategory(
        R.string.podcast_comedy,
        "😂",
        "comedy podcast funny",
        listOf(Color(0xFFFFD93D), Color(0xFFFF6B6B))
    ),
    PodcastCategory(
        R.string.podcast_motivation,
        "💪",
        "motivation podcast inspiration",
        listOf(Color(0xFF667EEA), Color(0xFF764BA2))
    ),
    PodcastCategory(
        R.string.podcast_technology,
        "💻",
        "technology podcast tech news",
        listOf(Color(0xFF11998E), Color(0xFF38EF7D))
    ),
    PodcastCategory(
        R.string.podcast_business,
        "💼",
        "business podcast entrepreneurship",
        listOf(Color(0xFF3A1C71), Color(0xFFD76D77))
    ),
    PodcastCategory(
        R.string.podcast_stories,
        "📖",
        "storytelling podcast stories hindi",
        listOf(Color(0xFFFC466B), Color(0xFF3F5EFB))
    ),
    PodcastCategory(
        R.string.podcast_health,
        "🧘",
        "health wellness podcast",
        listOf(Color(0xFF00B4DB), Color(0xFF0083B0))
    ),
    PodcastCategory(
        R.string.podcast_hindi,
        "🇮🇳",
        "hindi podcast india",
        listOf(Color(0xFFFF9933), Color(0xFF138808))
    ),
    PodcastCategory(
        R.string.podcast_news,
        "📰",
        "news podcast daily",
        listOf(Color(0xFF434343), Color(0xFF000000))
    ),
)

/**
 * ShivaayMusic Exclusive - Podcast Section Header
 */
@Composable
fun PodcastSectionHeader(
    onExploreAllClick: () -> Unit,
    modifier: Modifier = Modifier,
) {
    val infiniteTransition = rememberInfiniteTransition(label = "podcastPulse")
    val scale by infiniteTransition.animateFloat(
        initialValue = 1f,
        targetValue = 1.1f,
        animationSpec = infiniteRepeatable(
            animation = tween(1000, easing = FastOutSlowInEasing),
            repeatMode = RepeatMode.Reverse
        ),
        label = "podcastScale"
    )
    
    Card(
        modifier = modifier
            .fillMaxWidth()
            .padding(horizontal = 16.dp, vertical = 8.dp),
        shape = RoundedCornerShape(24.dp),
        colors = CardDefaults.cardColors(
            containerColor = Color.Transparent
        ),
        elevation = CardDefaults.cardElevation(defaultElevation = 0.dp)
    ) {
        Box(
            modifier = Modifier
                .fillMaxWidth()
                .background(
                    brush = Brush.linearGradient(
                        colors = listOf(
                            Color(0xFF667EEA),
                            Color(0xFF764BA2),
                            Color(0xFFFC466B)
                        )
                    )
                )
                .padding(20.dp)
        ) {
            Row(
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.SpaceBetween,
                modifier = Modifier.fillMaxWidth()
            ) {
                Row(
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Box(
                        contentAlignment = Alignment.Center,
                        modifier = Modifier
                            .size(56.dp)
                            .scale(scale)
                            .clip(CircleShape)
                            .background(Color.White.copy(alpha = 0.2f))
                    ) {
                        Icon(
                            painter = painterResource(R.drawable.podcast),
                            contentDescription = null,
                            tint = Color.White,
                            modifier = Modifier.size(32.dp)
                        )
                    }
                    
                    Spacer(modifier = Modifier.width(16.dp))
                    
                    Column {
                        Text(
                            text = stringResource(R.string.podcasts),
                            style = MaterialTheme.typography.headlineSmall,
                            fontWeight = FontWeight.Bold,
                            color = Color.White
                        )
                        Text(
                            text = stringResource(R.string.podcast_discover),
                            style = MaterialTheme.typography.bodyMedium,
                            color = Color.White.copy(alpha = 0.8f)
                        )
                    }
                }
                
                Surface(
                    onClick = onExploreAllClick,
                    shape = RoundedCornerShape(20.dp),
                    color = Color.White.copy(alpha = 0.2f)
                ) {
                    Text(
                        text = stringResource(R.string.podcast_explore_all),
                        style = MaterialTheme.typography.labelLarge,
                        color = Color.White,
                        fontWeight = FontWeight.SemiBold,
                        modifier = Modifier.padding(horizontal = 16.dp, vertical = 8.dp)
                    )
                }
            }
        }
    }
}

/**
 * ShivaayMusic Exclusive - YouTube Video Categories
 */
data class YouTubeVideoCategory(
    val nameResId: Int,
    val emoji: String,
    val searchQuery: String,
    val gradientColors: List<Color>
)

val youtubeVideoCategories = listOf(
    YouTubeVideoCategory(
        R.string.youtube_trending,
        "🔥",
        "trending videos india",
        listOf(Color(0xFFFF0000), Color(0xFFCC0000))
    ),
    YouTubeVideoCategory(
        R.string.youtube_music_videos,
        "🎵",
        "music video hindi latest",
        listOf(Color(0xFF9B59B6), Color(0xFF8E44AD))
    ),
    YouTubeVideoCategory(
        R.string.youtube_gaming,
        "🎮",
        "gaming videos hindi",
        listOf(Color(0xFF2ECC71), Color(0xFF27AE60))
    ),
    YouTubeVideoCategory(
        R.string.youtube_vlogs,
        "📹",
        "vlogs hindi india",
        listOf(Color(0xFF3498DB), Color(0xFF2980B9))
    ),
    YouTubeVideoCategory(
        R.string.youtube_tech_reviews,
        "📱",
        "tech review hindi",
        listOf(Color(0xFF1ABC9C), Color(0xFF16A085))
    ),
    YouTubeVideoCategory(
        R.string.youtube_comedy,
        "🤣",
        "comedy videos hindi funny",
        listOf(Color(0xFFF39C12), Color(0xFFE67E22))
    ),
)

/**
 * ShivaayMusic Exclusive - Podcast Category Chip - Vertical Layout Compatible
 */
@Composable
fun PodcastCategoryChip(
    category: PodcastCategory,
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
) {
    Card(
        modifier = modifier
            .height(100.dp)
            .clickable { onClick() },
        shape = RoundedCornerShape(20.dp),
        elevation = CardDefaults.cardElevation(defaultElevation = 8.dp)
    ) {
        Box(
            modifier = Modifier
                .fillMaxSize()
                .background(
                    brush = Brush.linearGradient(category.gradientColors)
                ),
            contentAlignment = Alignment.Center
        ) {
            Row(
                horizontalArrangement = Arrangement.Center,
                verticalAlignment = Alignment.CenterVertically,
                modifier = Modifier.padding(16.dp)
            ) {
                Text(
                    text = category.emoji,
                    fontSize = 32.sp
                )
                Spacer(modifier = Modifier.width(12.dp))
                Text(
                    text = stringResource(category.nameResId),
                    style = MaterialTheme.typography.labelLarge,
                    fontWeight = FontWeight.Bold,
                    color = Color.White,
                    textAlign = TextAlign.Start,
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis
                )
            }
        }
    }
}

/**
 * ShivaayMusic Exclusive - Podcast Categories Row - Vertical Layout
 */
@Composable
fun PodcastCategoriesSection(
    onCategoryClick: (PodcastCategory) -> Unit,
    modifier: Modifier = Modifier,
) {
    Column(modifier = modifier.fillMaxWidth()) {
        Text(
            text = stringResource(R.string.podcast_categories),
            style = MaterialTheme.typography.titleMedium,
            fontWeight = FontWeight.Bold,
            modifier = Modifier.padding(horizontal = 16.dp, vertical = 8.dp)
        )
        
        // Vertical layout with 2 items per row
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 12.dp),
            verticalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            podcastCategories.chunked(2).forEach { row ->
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.spacedBy(12.dp)
                ) {
                    row.forEach { category ->
                        PodcastCategoryChip(
                            category = category,
                            onClick = { onCategoryClick(category) },
                            modifier = Modifier.weight(1f)
                        )
                    }
                    // Fill remaining space if odd number of items
                    if (row.size == 1) {
                        Spacer(modifier = Modifier.weight(1f))
                    }
                }
            }
        }
    }
}

/**
 * ShivaayMusic Exclusive - Featured Podcast Card (Vertical Layout Compatible)
 */
@Composable
fun FeaturedPodcastCard(
    title: String,
    subtitle: String,
    emoji: String,
    gradientColors: List<Color>,
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
) {
    Card(
        modifier = modifier
            .height(140.dp)
            .clickable { onClick() },
        shape = RoundedCornerShape(24.dp),
        elevation = CardDefaults.cardElevation(defaultElevation = 12.dp)
    ) {
        Box(
            modifier = Modifier
                .fillMaxSize()
                .background(
                    brush = Brush.linearGradient(gradientColors)
                )
        ) {
            // Decorative circles - larger and more prominent
            Box(
                modifier = Modifier
                    .size(120.dp)
                    .align(Alignment.TopEnd)
                    .offset(x = 40.dp, y = (-40).dp)
                    .clip(CircleShape)
                    .background(Color.White.copy(alpha = 0.15f))
            )
            Box(
                modifier = Modifier
                    .size(80.dp)
                    .align(Alignment.BottomStart)
                    .offset(x = (-30).dp, y = 30.dp)
                    .clip(CircleShape)
                    .background(Color.White.copy(alpha = 0.1f))
            )
            Box(
                modifier = Modifier
                    .size(40.dp)
                    .align(Alignment.CenterStart)
                    .offset(x = 20.dp, y = (-20).dp)
                    .clip(CircleShape)
                    .background(Color.White.copy(alpha = 0.08f))
            )
            
            Row(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(20.dp),
                verticalAlignment = Alignment.CenterVertically
            ) {
                Column(
                    modifier = Modifier.weight(1f)
                ) {
                    Text(
                        text = title,
                        style = MaterialTheme.typography.titleMedium,
                        fontWeight = FontWeight.ExtraBold,
                        color = Color.White,
                        maxLines = 2,
                        overflow = TextOverflow.Ellipsis
                    )
                    Spacer(modifier = Modifier.height(4.dp))
                    Text(
                        text = subtitle,
                        style = MaterialTheme.typography.bodyMedium,
                        color = Color.White.copy(alpha = 0.85f),
                        maxLines = 1,
                        overflow = TextOverflow.Ellipsis
                    )
                    Spacer(modifier = Modifier.height(12.dp))
                    Surface(
                        shape = RoundedCornerShape(20.dp),
                        color = Color.White,
                        shadowElevation = 4.dp
                    ) {
                        Row(
                            verticalAlignment = Alignment.CenterVertically,
                            modifier = Modifier.padding(horizontal = 14.dp, vertical = 8.dp)
                        ) {
                            Icon(
                                painter = painterResource(R.drawable.play),
                                contentDescription = null,
                                tint = gradientColors[0],
                                modifier = Modifier.size(18.dp)
                            )
                            Spacer(modifier = Modifier.width(6.dp))
                            Text(
                                text = stringResource(R.string.podcast_listen_now),
                                style = MaterialTheme.typography.labelMedium,
                                fontWeight = FontWeight.Bold,
                                color = gradientColors[0]
                            )
                        }
                    }
                }
                
                Spacer(modifier = Modifier.width(12.dp))
                
                Text(
                    text = emoji,
                    fontSize = 48.sp
                )
            }
        }
    }
}

/**
 * ShivaayMusic Exclusive - Featured Podcasts Section - Vertical Layout
 */
@Composable
fun FeaturedPodcastsSection(
    onPodcastClick: (String) -> Unit,
    modifier: Modifier = Modifier,
) {
    val featuredPodcasts = listOf(
        Triple("Trending Hindi Podcasts", "Best podcasts in Hindi", "🎙️") to 
            (listOf(Color(0xFFFF6B6B), Color(0xFFFF8E53)) to "trending hindi podcast"),
        Triple("Comedy Podcasts", "Laugh out loud shows", "😂") to 
            (listOf(Color(0xFFFFD93D), Color(0xFFFF6B6B)) to "comedy podcast hindi funny"),
        Triple("Business & Startup", "Entrepreneurship insights", "💼") to 
            (listOf(Color(0xFF667EEA), Color(0xFF764BA2)) to "business startup podcast india"),
        Triple("True Crime Stories", "Thrilling mysteries", "🔍") to 
            (listOf(Color(0xFF434343), Color(0xFF000000)) to "true crime podcast hindi"),
        Triple("Self Improvement", "Grow every day", "🌟") to 
            (listOf(Color(0xFF11998E), Color(0xFF38EF7D)) to "self improvement podcast motivation"),
    )
    
    Column(modifier = modifier.fillMaxWidth()) {
        Text(
            text = stringResource(R.string.podcast_featured),
            style = MaterialTheme.typography.titleMedium,
            fontWeight = FontWeight.Bold,
            modifier = Modifier.padding(horizontal = 16.dp, vertical = 8.dp)
        )
        
        // Vertical layout for featured podcasts
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 12.dp),
            verticalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            featuredPodcasts.forEach { (info, details) ->
                val (title, subtitle, emoji) = info
                val (colors, query) = details
                FeaturedPodcastCard(
                    title = title,
                    subtitle = subtitle,
                    emoji = emoji,
                    gradientColors = colors,
                    onClick = { onPodcastClick(query) },
                    modifier = Modifier.fillMaxWidth()
                )
            }
        }
    }
}

/**
 * ShivaayMusic Exclusive - YouTube Video Section Header
 */
@Composable
fun YouTubeVideoSectionHeader(
    onExploreAllClick: () -> Unit,
    modifier: Modifier = Modifier,
) {
    val infiniteTransition = rememberInfiniteTransition(label = "youtubePulse")
    val scale by infiniteTransition.animateFloat(
        initialValue = 1f,
        targetValue = 1.1f,
        animationSpec = infiniteRepeatable(
            animation = tween(800, easing = FastOutSlowInEasing),
            repeatMode = RepeatMode.Reverse
        ),
        label = "youtubeScale"
    )
    
    Card(
        modifier = modifier
            .fillMaxWidth()
            .padding(horizontal = 16.dp, vertical = 8.dp),
        shape = RoundedCornerShape(24.dp),
        colors = CardDefaults.cardColors(
            containerColor = Color.Transparent
        ),
        elevation = CardDefaults.cardElevation(defaultElevation = 0.dp)
    ) {
        Box(
            modifier = Modifier
                .fillMaxWidth()
                .background(
                    brush = Brush.linearGradient(
                        colors = listOf(
                            Color(0xFFFF0000),
                            Color(0xFFCC0000),
                            Color(0xFF990000)
                        )
                    )
                )
                .padding(24.dp)
        ) {
            Row(
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.SpaceBetween,
                modifier = Modifier.fillMaxWidth()
            ) {
                Row(
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Box(
                        contentAlignment = Alignment.Center,
                        modifier = Modifier
                            .size(64.dp)
                            .scale(scale)
                            .clip(RoundedCornerShape(16.dp))
                            .background(Color.White.copy(alpha = 0.2f))
                    ) {
                        Icon(
                            painter = painterResource(R.drawable.play),
                            contentDescription = null,
                            tint = Color.White,
                            modifier = Modifier.size(36.dp)
                        )
                    }
                    
                    Spacer(modifier = Modifier.width(16.dp))
                    
                    Column {
                        Text(
                            text = stringResource(R.string.youtube_videos),
                            style = MaterialTheme.typography.headlineSmall,
                            fontWeight = FontWeight.ExtraBold,
                            color = Color.White
                        )
                        Text(
                            text = stringResource(R.string.youtube_videos_discover),
                            style = MaterialTheme.typography.bodyLarge,
                            color = Color.White.copy(alpha = 0.9f)
                        )
                    }
                }
                
                Surface(
                    onClick = onExploreAllClick,
                    shape = RoundedCornerShape(24.dp),
                    color = Color.White.copy(alpha = 0.25f)
                ) {
                    Text(
                        text = stringResource(R.string.youtube_explore_all),
                        style = MaterialTheme.typography.labelLarge,
                        color = Color.White,
                        fontWeight = FontWeight.Bold,
                        modifier = Modifier.padding(horizontal = 20.dp, vertical = 12.dp)
                    )
                }
            }
        }
    }
}

/**
 * ShivaayMusic Exclusive - YouTube Video Category Chip
 */
@Composable
fun YouTubeVideoCategoryChip(
    category: YouTubeVideoCategory,
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
) {
    Card(
        modifier = modifier
            .width(160.dp)
            .height(120.dp)
            .clickable { onClick() },
        shape = RoundedCornerShape(20.dp),
        elevation = CardDefaults.cardElevation(defaultElevation = 8.dp)
    ) {
        Box(
            modifier = Modifier
                .fillMaxSize()
                .background(
                    brush = Brush.linearGradient(category.gradientColors)
                ),
            contentAlignment = Alignment.Center
        ) {
            Column(
                horizontalAlignment = Alignment.CenterHorizontally,
                verticalArrangement = Arrangement.Center,
                modifier = Modifier.padding(16.dp)
            ) {
                Text(
                    text = category.emoji,
                    fontSize = 40.sp
                )
                Spacer(modifier = Modifier.height(10.dp))
                Text(
                    text = stringResource(category.nameResId),
                    style = MaterialTheme.typography.labelLarge,
                    fontWeight = FontWeight.Bold,
                    color = Color.White,
                    textAlign = TextAlign.Center,
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis
                )
            }
        }
    }
}

/**
 * ShivaayMusic Exclusive - YouTube Video Categories Section
 */
@Composable
fun YouTubeVideoCategoriesSection(
    onCategoryClick: (YouTubeVideoCategory) -> Unit,
    modifier: Modifier = Modifier,
) {
    Column(modifier = modifier.fillMaxWidth()) {
        LazyRow(
            contentPadding = PaddingValues(horizontal = 12.dp),
            horizontalArrangement = Arrangement.spacedBy(14.dp)
        ) {
            items(youtubeVideoCategories) { category ->
                YouTubeVideoCategoryChip(
                    category = category,
                    onClick = { onCategoryClick(category) }
                )
            }
        }
    }
}

/**
 * ShivaayMusic Exclusive - YouTube Video Section
 */
@Composable
fun YouTubeVideoSection(
    onSearchVideo: (String) -> Unit,
    modifier: Modifier = Modifier,
) {
    Column(modifier = modifier.fillMaxWidth()) {
        // Header with explore all button
        YouTubeVideoSectionHeader(
            onExploreAllClick = { onSearchVideo("trending videos india") }
        )
        
        Spacer(modifier = Modifier.height(16.dp))
        
        // Video Categories
        YouTubeVideoCategoriesSection(
            onCategoryClick = { category ->
                onSearchVideo(category.searchQuery)
            }
        )
    }
}

/**
 * ShivaayMusic Exclusive - Complete Podcast Section for Explore Screen
 */
@Composable
fun PodcastSection(
    onSearchPodcast: (String) -> Unit,
    modifier: Modifier = Modifier,
) {
    Column(modifier = modifier.fillMaxWidth()) {
        // Header with explore all button
        PodcastSectionHeader(
            onExploreAllClick = { onSearchPodcast("podcast hindi") }
        )
        
        Spacer(modifier = Modifier.height(16.dp))
        
        // Featured Podcasts
        FeaturedPodcastsSection(
            onPodcastClick = onSearchPodcast
        )
        
        Spacer(modifier = Modifier.height(16.dp))
        
        // Categories
        PodcastCategoriesSection(
            onCategoryClick = { category ->
                onSearchPodcast(category.searchQuery)
            }
        )
    }
}
