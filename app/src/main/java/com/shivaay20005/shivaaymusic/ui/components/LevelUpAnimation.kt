package com.shivaay20005.shivaaymusic.ui.components

import androidx.compose.animation.*
import androidx.compose.animation.core.*
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.alpha
import androidx.compose.ui.draw.scale
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.hapticfeedback.HapticFeedbackType
import androidx.compose.ui.platform.LocalHapticFeedback
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.window.Dialog
import androidx.compose.ui.window.DialogProperties
import com.shivaay20005.shivaaymusic.models.Reward
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import kotlin.random.Random

@Composable
fun LevelUpDialog(
    show: Boolean,
    newLevel: Int,
    unlockedRewards: List<Reward>,
    onDismiss: () -> Unit
) {
    val haptic = LocalHapticFeedback.current
    val scope = rememberCoroutineScope()

    LaunchedEffect(show) {
        if (show) {
            // Trigger haptic feedback
            haptic.performHapticFeedback(HapticFeedbackType.LongPress)
            delay(200)
            haptic.performHapticFeedback(HapticFeedbackType.LongPress)
        }
    }

    if (show) {
        Dialog(
            onDismissRequest = onDismiss,
            properties = DialogProperties(
                dismissOnBackPress = true,
                dismissOnClickOutside = true,
                usePlatformDefaultWidth = false
            )
        ) {
            Box(
                modifier = Modifier
                    .fillMaxSize()
                    .background(Color.Black.copy(alpha = 0.7f)),
                contentAlignment = Alignment.Center
            ) {
                // Confetti effect
                ConfettiAnimation(show = show)

                // Main content
                AnimatedContent(
                    targetState = show,
                    transitionSpec = {
                        fadeIn(
                            animationSpec = tween(500)
                        ) + scaleIn(
                            initialScale = 0.8f,
                            animationSpec = spring(
                                dampingRatio = Spring.DampingRatioMediumBouncy,
                                stiffness = Spring.StiffnessLow
                            )
                        ) togetherWith fadeOut(animationSpec = tween(200))
                    },
                    label = "level_up_content"
                ) { isShowing ->
                    if (isShowing) {
                        Card(
                            modifier = Modifier
                                .padding(32.dp)
                                .fillMaxWidth(),
                            shape = RoundedCornerShape(24.dp),
                            colors = CardDefaults.cardColors(
                                containerColor = MaterialTheme.colorScheme.surface
                            )
                        ) {
                            Column(
                                modifier = Modifier.padding(32.dp),
                                horizontalAlignment = Alignment.CenterHorizontally
                            ) {
                                // Animated level badge
                                AnimatedLevelBadge(level = newLevel)

                                Spacer(modifier = Modifier.height(24.dp))

                                Text(
                                    text = "LEVEL UP!",
                                    style = MaterialTheme.typography.headlineLarge,
                                    fontWeight = FontWeight.Bold,
                                    color = MaterialTheme.colorScheme.primary
                                )

                                Spacer(modifier = Modifier.height(8.dp))

                                Text(
                                    text = "You reached Level $newLevel",
                                    style = MaterialTheme.typography.titleMedium,
                                    color = MaterialTheme.colorScheme.onSurface
                                )

                                if (unlockedRewards.isNotEmpty()) {
                                    Spacer(modifier = Modifier.height(24.dp))

                                    Text(
                                        text = "🎁 Rewards Unlocked:",
                                        style = MaterialTheme.typography.titleMedium,
                                        fontWeight = FontWeight.Bold
                                    )

                                    Spacer(modifier = Modifier.height(12.dp))

                                    unlockedRewards.forEach { reward ->
                                        Card(
                                            modifier = Modifier
                                                .fillMaxWidth()
                                                .padding(vertical = 4.dp),
                                            colors = CardDefaults.cardColors(
                                                containerColor = MaterialTheme.colorScheme.primaryContainer
                                            )
                                        ) {
                                            Column(
                                                modifier = Modifier.padding(12.dp)
                                            ) {
                                                Text(
                                                    text = reward.name,
                                                    style = MaterialTheme.typography.bodyLarge,
                                                    fontWeight = FontWeight.Bold,
                                                    color = MaterialTheme.colorScheme.onPrimaryContainer
                                                )
                                                Text(
                                                    text = reward.description,
                                                    style = MaterialTheme.typography.bodySmall,
                                                    color = MaterialTheme.colorScheme.onPrimaryContainer.copy(alpha = 0.7f)
                                                )
                                            }
                                        }
                                    }
                                }

                                Spacer(modifier = Modifier.height(24.dp))

                                Button(
                                    onClick = onDismiss,
                                    modifier = Modifier.fillMaxWidth()
                                ) {
                                    Text("Continue")
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

@Composable
private fun AnimatedLevelBadge(level: Int) {
    val infiniteTransition = rememberInfiniteTransition(label = "level_badge")
    val scale by infiniteTransition.animateFloat(
        initialValue = 1f,
        targetValue = 1.1f,
        animationSpec = infiniteRepeatable(
            animation = tween(1000),
            repeatMode = RepeatMode.Reverse
        ),
        label = "scale"
    )

    Box(
        modifier = Modifier
            .size(120.dp)
            .scale(scale)
            .background(
                brush = Brush.radialGradient(
                    colors = listOf(
                        MaterialTheme.colorScheme.primary,
                        MaterialTheme.colorScheme.secondary,
                        MaterialTheme.colorScheme.tertiary
                    )
                ),
                shape = CircleShape
            ),
        contentAlignment = Alignment.Center
    ) {
        Column(
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            Text(
                text = "LVL",
                fontSize = 18.sp,
                fontWeight = FontWeight.Bold,
                color = Color.White
            )
            Text(
                text = "$level",
                fontSize = 36.sp,
                fontWeight = FontWeight.Bold,
                color = Color.White
            )
        }
    }
}

@Composable
private fun ConfettiAnimation(show: Boolean) {
    val confettiPieces = remember { List(30) { ConfettiPiece() } }

    confettiPieces.forEach { piece ->
        ConfettiParticle(
            show = show,
            startX = piece.startX,
            color = piece.color,
            delay = piece.delay
        )
    }
}

@Composable
private fun ConfettiParticle(
    show: Boolean,
    startX: Float,
    color: Color,
    delay: Int
) {
    var animationPlayed by remember { mutableStateOf(false) }

    val offsetY by animateFloatAsState(
        targetValue = if (show && !animationPlayed) 1000f else 0f,
        animationSpec = tween(
            durationMillis = 2000,
            delayMillis = delay,
            easing = LinearEasing
        ),
        finishedListener = { animationPlayed = true },
        label = "offsetY"
    )

    val alpha by animateFloatAsState(
        targetValue = if (show && !animationPlayed) 0f else 1f,
        animationSpec = tween(2000, delay),
        label = "alpha"
    )

    Box(
        modifier = Modifier
            .offset(x = startX.dp, y = offsetY.dp)
            .size(8.dp)
            .alpha(alpha)
            .background(color, shape = CircleShape)
    )
}

private data class ConfettiPiece(
    val startX: Float = Random.nextFloat() * 400f,
    val color: Color = listOf(
        Color.Red,
        Color.Blue,
        Color.Green,
        Color.Yellow,
        Color.Magenta,
        Color.Cyan
    ).random(),
    val delay: Int = Random.nextInt(0, 300)
)
