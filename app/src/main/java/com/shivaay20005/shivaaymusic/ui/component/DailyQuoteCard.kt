package com.shivaay20005.shivaaymusic.ui.component

import androidx.compose.animation.animateColorAsState
import androidx.compose.animation.core.FastOutSlowInEasing
import androidx.compose.animation.core.RepeatMode
import androidx.compose.animation.core.animateFloat
import androidx.compose.animation.core.infiniteRepeatable
import androidx.compose.animation.core.rememberInfiniteTransition
import androidx.compose.animation.core.tween
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.alpha
import androidx.compose.ui.draw.scale
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.shivaay20005.shivaaymusic.R
import java.util.Calendar

/**
 * ShivaayMusic Exclusive - Daily Music Quote Card
 * A unique feature that displays motivational music quotes
 * Changes quote based on the day of the year
 */
@Composable
fun DailyQuoteCard(
    modifier: Modifier = Modifier,
) {
    val quotes = listOf(
        R.string.quote_1, R.string.quote_2, R.string.quote_3, R.string.quote_4, R.string.quote_5,
        R.string.quote_6, R.string.quote_7, R.string.quote_8, R.string.quote_9, R.string.quote_10,
        R.string.quote_11, R.string.quote_12, R.string.quote_13, R.string.quote_14, R.string.quote_15,
        R.string.quote_16, R.string.quote_17, R.string.quote_18, R.string.quote_19, R.string.quote_20,
        R.string.quote_21, R.string.quote_22, R.string.quote_23, R.string.quote_24, R.string.quote_25,
        R.string.quote_26, R.string.quote_27, R.string.quote_28, R.string.quote_29, R.string.quote_30,
        R.string.quote_31, R.string.quote_32, R.string.quote_33, R.string.quote_34, R.string.quote_35,
        R.string.quote_36, R.string.quote_37, R.string.quote_38, R.string.quote_39, R.string.quote_40,
        R.string.quote_41, R.string.quote_42, R.string.quote_43, R.string.quote_44, R.string.quote_45,
        R.string.quote_46, R.string.quote_47, R.string.quote_48, R.string.quote_49, R.string.quote_50,
        R.string.quote_51, R.string.quote_52, R.string.quote_53, R.string.quote_54, R.string.quote_55,
        R.string.quote_56, R.string.quote_57, R.string.quote_58, R.string.quote_59, R.string.quote_60,
        R.string.quote_61, R.string.quote_62, R.string.quote_63, R.string.quote_64, R.string.quote_65,
        R.string.quote_66, R.string.quote_67, R.string.quote_68, R.string.quote_69, R.string.quote_70,
        R.string.quote_71, R.string.quote_72, R.string.quote_73, R.string.quote_74, R.string.quote_75,
        R.string.quote_76, R.string.quote_77, R.string.quote_78, R.string.quote_79, R.string.quote_80,
        R.string.quote_81, R.string.quote_82, R.string.quote_83, R.string.quote_84, R.string.quote_85,
        R.string.quote_86, R.string.quote_87, R.string.quote_88, R.string.quote_89, R.string.quote_90,
        R.string.quote_91, R.string.quote_92, R.string.quote_93, R.string.quote_94, R.string.quote_95,
        R.string.quote_96, R.string.quote_97, R.string.quote_98, R.string.quote_99, R.string.quote_100,
    )
    
    // Get quote based on day of year so it changes daily
    val dayOfYear = remember {
        Calendar.getInstance().get(Calendar.DAY_OF_YEAR)
    }
    val quoteIndex = dayOfYear % quotes.size
    val currentQuote = stringResource(quotes[quoteIndex])
    
    // Animation for the music icon
    val infiniteTransition = rememberInfiniteTransition(label = "quoteAnimation")
    val scale by infiniteTransition.animateFloat(
        initialValue = 1f,
        targetValue = 1.2f,
        animationSpec = infiniteRepeatable(
            animation = tween(1500, easing = FastOutSlowInEasing),
            repeatMode = RepeatMode.Reverse
        ),
        label = "iconScale"
    )
    
    val alpha by infiniteTransition.animateFloat(
        initialValue = 0.6f,
        targetValue = 1f,
        animationSpec = infiniteRepeatable(
            animation = tween(1500, easing = FastOutSlowInEasing),
            repeatMode = RepeatMode.Reverse
        ),
        label = "iconAlpha"
    )
    
    Card(
        modifier = modifier
            .fillMaxWidth()
            .padding(horizontal = 16.dp, vertical = 8.dp),
        shape = RoundedCornerShape(20.dp),
        elevation = CardDefaults.cardElevation(defaultElevation = 4.dp),
        colors = CardDefaults.cardColors(
            containerColor = MaterialTheme.colorScheme.primaryContainer.copy(alpha = 0.7f)
        )
    ) {
        Box(
            modifier = Modifier
                .fillMaxWidth()
                .background(
                    brush = Brush.horizontalGradient(
                        colors = listOf(
                            MaterialTheme.colorScheme.primaryContainer,
                            MaterialTheme.colorScheme.secondaryContainer,
                            MaterialTheme.colorScheme.tertiaryContainer,
                        )
                    )
                )
        ) {
            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(20.dp),
                horizontalAlignment = Alignment.CenterHorizontally,
            ) {
                Row(
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.Center,
                ) {
                    Icon(
                        painter = painterResource(R.drawable.music_note),
                        contentDescription = null,
                        tint = MaterialTheme.colorScheme.primary,
                        modifier = Modifier
                            .size(24.dp)
                            .scale(scale)
                            .alpha(alpha)
                    )
                    
                    Text(
                        text = stringResource(R.string.daily_music_quote),
                        style = MaterialTheme.typography.titleMedium,
                        fontWeight = FontWeight.Bold,
                        color = MaterialTheme.colorScheme.onPrimaryContainer,
                        modifier = Modifier.padding(start = 8.dp)
                    )
                    
                    Icon(
                        painter = painterResource(R.drawable.music_note),
                        contentDescription = null,
                        tint = MaterialTheme.colorScheme.primary,
                        modifier = Modifier
                            .size(24.dp)
                            .scale(scale)
                            .alpha(alpha)
                    )
                }
                
                Spacer(modifier = Modifier.height(12.dp))
                
                Text(
                    text = currentQuote,
                    style = MaterialTheme.typography.bodyLarge,
                    fontStyle = FontStyle.Italic,
                    textAlign = TextAlign.Center,
                    color = MaterialTheme.colorScheme.onPrimaryContainer,
                    lineHeight = 24.sp,
                    modifier = Modifier.padding(horizontal = 8.dp)
                )
                
                Spacer(modifier = Modifier.height(12.dp))
                
                Text(
                    text = stringResource(R.string.powered_by_shivaay),
                    style = MaterialTheme.typography.labelSmall,
                    color = MaterialTheme.colorScheme.onPrimaryContainer.copy(alpha = 0.7f),
                    fontWeight = FontWeight.Medium,
                )
            }
        }
    }
}

/**
 * ShivaayMusic Exclusive - Shivaay Special Header
 * A branded header with animation
 */
@Composable
fun ShivaaySpecialHeader(
    modifier: Modifier = Modifier,
) {
    val infiniteTransition = rememberInfiniteTransition(label = "headerAnimation")
    val colorProgress by infiniteTransition.animateFloat(
        initialValue = 0f,
        targetValue = 1f,
        animationSpec = infiniteRepeatable(
            animation = tween(3000, easing = FastOutSlowInEasing),
            repeatMode = RepeatMode.Reverse
        ),
        label = "colorProgress"
    )
    
    val textColor by animateColorAsState(
        targetValue = if (colorProgress > 0.5f) 
            MaterialTheme.colorScheme.primary 
        else 
            MaterialTheme.colorScheme.tertiary,
        animationSpec = tween(500),
        label = "textColor"
    )
    
    Row(
        modifier = modifier
            .fillMaxWidth()
            .padding(horizontal = 16.dp, vertical = 8.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Text(
            text = "✨",
            fontSize = 20.sp,
        )
        Text(
            text = stringResource(R.string.shivaay_special),
            style = MaterialTheme.typography.titleLarge,
            fontWeight = FontWeight.Bold,
            color = textColor,
            modifier = Modifier.padding(horizontal = 8.dp)
        )
        Text(
            text = "✨",
            fontSize = 20.sp,
        )
    }
}

/**
 * ShivaayMusic Exclusive - Time-based Greeting Message
 * Shows Good Morning/Afternoon/Evening/Night based on current time
 */
@Composable
fun GreetingMessage(
    modifier: Modifier = Modifier,
) {
    val currentHour = remember {
        Calendar.getInstance().get(Calendar.HOUR_OF_DAY)
    }
    
    val greetingResId = when (currentHour) {
        in 5..11 -> R.string.good_morning
        in 12..16 -> R.string.good_afternoon
        in 17..20 -> R.string.good_evening
        else -> R.string.good_night
    }
    
    val greetingEmoji = when (currentHour) {
        in 5..11 -> "🌅"
        in 12..16 -> "☀️"
        in 17..20 -> "🌆"
        else -> "🌙"
    }
    
    Text(
        text = "$greetingEmoji ${stringResource(greetingResId)}",
        style = MaterialTheme.typography.titleMedium,
        fontWeight = FontWeight.Medium,
        color = MaterialTheme.colorScheme.onSurfaceVariant,
        modifier = modifier.padding(horizontal = 16.dp, vertical = 4.dp)
    )
}
