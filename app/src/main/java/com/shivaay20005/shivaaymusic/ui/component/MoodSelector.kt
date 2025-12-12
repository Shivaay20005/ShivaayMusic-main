package com.shivaay20005.shivaaymusic.ui.component

import androidx.compose.animation.animateColorAsState
import androidx.compose.animation.core.FastOutSlowInEasing
import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.tween
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
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
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.shivaay20005.shivaaymusic.R

/**
 * ShivaayMusic Exclusive - Mood-Based Music Selector
 * A unique feature that lets users select their mood and get personalized recommendations
 */

data class MoodItem(
    val emoji: String,
    val nameResId: Int,
    val color: Color,
    val searchQuery: String
)

val moodList = listOf(
    MoodItem("😊", R.string.mood_happy, Color(0xFFFFD700), "happy upbeat songs"),
    MoodItem("😢", R.string.mood_sad, Color(0xFF6495ED), "sad emotional songs"),
    MoodItem("😌", R.string.mood_relaxed, Color(0xFF90EE90), "relaxing calm music"),
    MoodItem("🔥", R.string.mood_energetic, Color(0xFFFF6347), "energetic workout songs"),
    MoodItem("💖", R.string.mood_romantic, Color(0xFFFF69B4), "romantic love songs"),
    MoodItem("🌙", R.string.mood_sleepy, Color(0xFF9370DB), "sleep music ambient"),
    MoodItem("🎉", R.string.mood_party, Color(0xFFFF4500), "party dance songs"),
    MoodItem("🤔", R.string.mood_focused, Color(0xFF4682B4), "focus concentration music"),
)

@Composable
fun MoodSelectorCard(
    onMoodSelected: (MoodItem) -> Unit,
    modifier: Modifier = Modifier,
) {
    var selectedMood by remember { mutableStateOf<MoodItem?>(null) }
    
    Card(
        modifier = modifier
            .fillMaxWidth()
            .padding(horizontal = 16.dp, vertical = 8.dp),
        shape = RoundedCornerShape(20.dp),
        elevation = CardDefaults.cardElevation(defaultElevation = 6.dp),
        colors = CardDefaults.cardColors(
            containerColor = MaterialTheme.colorScheme.surfaceVariant
        )
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
        ) {
            Row(
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.Center,
            ) {
                Icon(
                    painter = painterResource(R.drawable.mood),
                    contentDescription = null,
                    tint = MaterialTheme.colorScheme.primary,
                    modifier = Modifier.size(24.dp)
                )
                Spacer(modifier = Modifier.width(8.dp))
                Text(
                    text = stringResource(R.string.mood_how_feeling),
                    style = MaterialTheme.typography.titleMedium,
                    fontWeight = FontWeight.Bold,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                )
            }
            
            Spacer(modifier = Modifier.height(4.dp))
            
            Text(
                text = stringResource(R.string.mood_tap_to_discover),
                style = MaterialTheme.typography.bodySmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant.copy(alpha = 0.7f),
            )
            
            Spacer(modifier = Modifier.height(16.dp))
            
            LazyRow(
                horizontalArrangement = Arrangement.spacedBy(12.dp),
                modifier = Modifier.fillMaxWidth()
            ) {
                items(moodList) { mood ->
                    MoodChip(
                        mood = mood,
                        isSelected = selectedMood == mood,
                        onClick = {
                            selectedMood = mood
                            onMoodSelected(mood)
                        }
                    )
                }
            }
        }
    }
}

@Composable
fun MoodChip(
    mood: MoodItem,
    isSelected: Boolean,
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
) {
    val scale by animateFloatAsState(
        targetValue = if (isSelected) 1.1f else 1f,
        animationSpec = tween(200, easing = FastOutSlowInEasing),
        label = "moodScale"
    )
    
    val backgroundColor by animateColorAsState(
        targetValue = if (isSelected) mood.color.copy(alpha = 0.3f) else Color.Transparent,
        animationSpec = tween(200),
        label = "moodBgColor"
    )
    
    Column(
        horizontalAlignment = Alignment.CenterHorizontally,
        modifier = modifier
            .scale(scale)
            .clip(RoundedCornerShape(16.dp))
            .background(backgroundColor)
            .border(
                width = if (isSelected) 2.dp else 1.dp,
                color = if (isSelected) mood.color else MaterialTheme.colorScheme.outline.copy(alpha = 0.3f),
                shape = RoundedCornerShape(16.dp)
            )
            .clickable { onClick() }
            .padding(12.dp)
    ) {
        Text(
            text = mood.emoji,
            fontSize = 32.sp,
        )
        Spacer(modifier = Modifier.height(4.dp))
        Text(
            text = stringResource(mood.nameResId),
            style = MaterialTheme.typography.labelSmall,
            fontWeight = if (isSelected) FontWeight.Bold else FontWeight.Normal,
            color = if (isSelected) mood.color else MaterialTheme.colorScheme.onSurfaceVariant,
            textAlign = TextAlign.Center,
        )
    }
}

/**
 * ShivaayMusic Exclusive - Quick Mood Buttons
 * Compact mood selection for the player screen
 */
@Composable
fun QuickMoodButtons(
    onMoodSelected: (MoodItem) -> Unit,
    modifier: Modifier = Modifier,
) {
    Row(
        modifier = modifier
            .fillMaxWidth()
            .padding(horizontal = 16.dp),
        horizontalArrangement = Arrangement.SpaceEvenly,
    ) {
        moodList.take(4).forEach { mood ->
            Box(
                contentAlignment = Alignment.Center,
                modifier = Modifier
                    .size(48.dp)
                    .clip(CircleShape)
                    .background(
                        brush = Brush.radialGradient(
                            colors = listOf(
                                mood.color.copy(alpha = 0.3f),
                                mood.color.copy(alpha = 0.1f)
                            )
                        )
                    )
                    .clickable { onMoodSelected(mood) }
            ) {
                Text(
                    text = mood.emoji,
                    fontSize = 24.sp,
                )
            }
        }
    }
}
