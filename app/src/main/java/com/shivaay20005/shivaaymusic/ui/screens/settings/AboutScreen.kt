package com.shivaay20005.shivaaymusic.ui.screens.settings

import androidx.compose.animation.core.FastOutSlowInEasing
import androidx.compose.animation.core.RepeatMode
import androidx.compose.animation.core.animateFloat
import androidx.compose.animation.core.infiniteRepeatable
import androidx.compose.animation.core.rememberInfiniteTransition
import androidx.compose.animation.core.tween
import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.offset
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.layout.windowInsetsPadding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.NavigationBarDefaults
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.material3.TopAppBarDefaults
import androidx.compose.material3.TopAppBarScrollBehavior
import androidx.compose.material3.surfaceColorAtElevation
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalUriHandler
import androidx.compose.ui.platform.UriHandler
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.navigation.NavController
import coil.compose.rememberAsyncImagePainter
import com.shivaay20005.shivaaymusic.BuildConfig
import com.shivaay20005.shivaaymusic.LocalPlayerAwareWindowInsets
import com.shivaay20005.shivaaymusic.R
import com.shivaay20005.shivaaymusic.ui.component.IconButton
import com.shivaay20005.shivaaymusic.ui.utils.backToMain

@Composable
fun shimmerEffect(): Brush {
    val shimmerColors = listOf(
        MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.6f),
        MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.2f),
        MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.6f),
    )

    val transition = rememberInfiniteTransition(label = "shimmerEffect")
    val translateAnim = transition.animateFloat(
        initialValue = 0f,
        targetValue = 1000f,
        animationSpec = infiniteRepeatable(
            animation = tween(durationMillis = 1200, easing = FastOutSlowInEasing),
            repeatMode = RepeatMode.Reverse
        ), label = "shimmerEffect"
    )

    return Brush.linearGradient(
        colors = shimmerColors,
        start = Offset.Zero,
        end = Offset(x = translateAnim.value, y = translateAnim.value)
    )
}

@Composable
fun UserCard(
    imageUrl: String,
    name: String,
    role: String,
    onClick: () -> Unit
) {
    Card(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 24.dp, vertical = 16.dp)
            .height(140.dp)
            .shadow(8.dp, RoundedCornerShape(20.dp))
            .clickable(onClick = onClick),
        shape = RoundedCornerShape(20.dp),
        colors = CardDefaults.cardColors(
            containerColor = MaterialTheme.colorScheme.surface,
        )
    ) {
        Box(
            modifier = Modifier.fillMaxSize()
        ) {
            Row(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(24.dp),
                verticalAlignment = Alignment.CenterVertically
            ) {
                Image(
                    painter = rememberAsyncImagePainter(model = imageUrl),
                    contentDescription = null,
                    modifier = Modifier
                        .size(60.dp)
                        .clip(CircleShape)
                        .background(
                            Brush.radialGradient(
                                colors = listOf(
                                    MaterialTheme.colorScheme.primary.copy(alpha = 0.1f),
                                    MaterialTheme.colorScheme.primary.copy(alpha = 0.05f)
                                )
                            )
                        )
                        .border(1.dp, MaterialTheme.colorScheme.primary, CircleShape),
                    contentScale = ContentScale.Crop
                )

                Spacer(modifier = Modifier.width(16.dp))

                Column {
                    Text(
                        text = name,
                        style = MaterialTheme.typography.titleMedium,
                        fontWeight = FontWeight.Bold,
                        color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.8f)
                    )
                    Spacer(modifier = Modifier.height(4.dp))
                    Text(
                        text = role,
                        style = MaterialTheme.typography.bodyMedium,
                        color = MaterialTheme.colorScheme.onSurfaceVariant.copy(alpha = 0.6f)
                    )
                }
            }

            // Decorative element
            Box(
                modifier = Modifier
                    .align(Alignment.TopEnd)
                    .size(40.dp)
                    .offset(x = 20.dp, y = (-20).dp)
                    .background(
                        MaterialTheme.colorScheme.primaryContainer.copy(alpha = 0.1f),
                        CircleShape
                    )
            )
        }
    }
}


@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun AboutScreen(
    navController: NavController,
    scrollBehavior: TopAppBarScrollBehavior,

    ) {
    val uriHandler = LocalUriHandler.current
    val shimmerBrush = shimmerEffect()

    Column(
        modifier = Modifier
            .fillMaxWidth()
            .windowInsetsPadding(LocalPlayerAwareWindowInsets.current)
            .verticalScroll(rememberScrollState()),
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        Spacer(Modifier.height(20.dp))

        // Image with shimmer effect
        Box(
            modifier = Modifier
                .size(90.dp)
                .clip(CircleShape)
                .background(MaterialTheme.colorScheme.surfaceColorAtElevation(NavigationBarDefaults.Elevation))
        ) {
            Image(
                painter = painterResource(R.drawable.source_icon),
                contentDescription = null,
                modifier = Modifier
                    .matchParentSize()
                    .clickable { },
                contentScale = ContentScale.Fit
            )

            // Shimmer effect overlay only for the image
            Box(
                modifier = Modifier
                    .matchParentSize()
                    .background(shimmerBrush)
            )
        }


        Row(
            verticalAlignment = Alignment.Top,
        ) {
            Text(
                text = stringResource(R.string.app_name),
                style = MaterialTheme.typography.headlineSmall,
                fontWeight = FontWeight.Bold,
                modifier = Modifier.padding(top = 8.dp, bottom = 4.dp)
            )
        }


        Row(verticalAlignment = Alignment.CenterVertically) {
//

            Spacer(Modifier.width(10.dp))

            Text(
                text = BuildConfig.VERSION_NAME.uppercase(),
                style = MaterialTheme.typography.labelSmall,
                color = MaterialTheme.colorScheme.secondary,
                modifier = Modifier
                    .border(
                        width = 1.dp,
                        color = MaterialTheme.colorScheme.secondary,
                        shape = CircleShape
                    )
                    .padding(
                        horizontal = 6.dp,
                        vertical = 2.dp
                    )
            )

            if (BuildConfig.DEBUG) {
                Spacer(Modifier.width(4.dp))

                Text(
                    text = "DEBUG",
                    style = MaterialTheme.typography.labelSmall,
                    color = MaterialTheme.colorScheme.secondary,
                    modifier = Modifier
                        .border(
                            width = 1.dp,
                            color = MaterialTheme.colorScheme.secondary,
                            shape = CircleShape
                        )
                        .padding(
                            horizontal = 6.dp,
                            vertical = 2.dp
                        )
                )
            }
        }

        Spacer(Modifier.height(10.dp))

        Text(
            text = " Dev By Shivaay 亗",
            style = MaterialTheme.typography.titleMedium.copy(
                fontFamily = FontFamily.Monospace
            ),
            fontWeight = FontWeight.Bold,
            color = MaterialTheme.colorScheme.secondary
        )

        Spacer(Modifier.height(4.dp))
        
        // ShivaayMusic Exclusive - Made with love badge
        Text(
            text = stringResource(R.string.made_with_love),
            style = MaterialTheme.typography.bodySmall,
            color = MaterialTheme.colorScheme.tertiary
        )

        Spacer(Modifier.height(8.dp))

        Card(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp),
            shape = RoundedCornerShape(28.dp), // Highly rounded corners MD3 style
            elevation = CardDefaults.cardElevation(defaultElevation = 1.dp),
            colors = CardDefaults.cardColors(
                containerColor = MaterialTheme.colorScheme.surfaceVariant, // MD3 background color
            )
        ) {
            Row(
                modifier = Modifier
                    .padding(8.dp)
                    .fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceEvenly,
                verticalAlignment = Alignment.CenterVertically
            ) {
                IconButton(
                    onClick = { uriHandler.openUri("https://github.com/shivaay20005") }
                ) {
                    Icon(
                        modifier = Modifier.size(20.dp),
                        painter = painterResource(R.drawable.github),
                        contentDescription = null
                    )
                }
                // PayPal donation button - commented out
                // IconButton(
                //     onClick = { uriHandler.openUri("https://www.paypal.me/shivaaymusic") }
                // ) {
                //     Icon(
                //         modifier = Modifier.size(20.dp),
                //         contentDescription = null,
                //         painter = painterResource(R.drawable.paypal)
                //     )
                // }

                IconButton(
                    onClick = { uriHandler.openUri("https://g.dev/shivaay20005") }
                ) {
                    Icon(
                        modifier = Modifier.size(20.dp),
                        contentDescription = null,
                        painter = painterResource(R.drawable.google)
                    )
                }


                IconButton(
                    onClick = { uriHandler.openUri("https://shivaaymusic.netlify.app/") }
                ) {
                    Icon(
                        modifier = Modifier.size(22.dp),
                        contentDescription = null,
                        painter = painterResource(R.drawable.resource_public)
                    )
                }
            }
        }
        Spacer(Modifier.height(20.dp))
        Row(
            verticalAlignment = Alignment.Top,
        ) {
            Row(
                verticalAlignment = Alignment.CenterVertically,
                modifier = Modifier.padding(top = 8.dp, bottom = 4.dp)
            ) {
                Icon(
                    painter = painterResource(id = R.drawable.group),
                    contentDescription = null
                )
                Spacer(modifier = Modifier.width(8.dp))
                Text(
                    text = stringResource(R.string.contributors),
                    style = MaterialTheme.typography.headlineSmall,
                    fontWeight = FontWeight.Bold
                )
            }


        }

        UserCards(uriHandler)
        Spacer(modifier = Modifier.width(12.dp))

    }

    TopAppBar(
        title = {
            Text(
                stringResource(R.string.about),
                style = MaterialTheme.typography.titleLarge.copy(
                    fontWeight = FontWeight.Bold
                )
            )
        },
        modifier = Modifier.clip(RoundedCornerShape(16.dp)),
        navigationIcon = {
            IconButton(
                onClick = navController::navigateUp,
                onLongClick = navController::backToMain,
            ) {
                Icon(
                    painterResource(R.drawable.arrow_back),
                    contentDescription = null,
                )
            }
        },
        scrollBehavior = scrollBehavior,
        colors = TopAppBarDefaults.topAppBarColors(
            containerColor = MaterialTheme.colorScheme.surface,
            titleContentColor = MaterialTheme.colorScheme.onSurface,
        )
    )
}

@Composable
fun UserCards(uriHandler: UriHandler) {
    Column {
        UserCard(
            imageUrl = "https://avatars.githubusercontent.com/u/208749772?s=400&u=e984ff02672986b1082b019d9ad47e9c61ad8741&v=4",
            name = "亗 Shivaay",
            role = "Lead Developer ",
            onClick = { uriHandler.openUri("https://github.com/shivaay20005") }
        )

        UserCard(
            imageUrl = "https://files.catbox.moe/6kwzs4.jpg",
            name = "\uD81A\uDD10 Prateek",
            role = " Icon designer",
            onClick = { uriHandler.openUri("https://github.com/Prateek6388-web/") }
        )

        UserCard(
            imageUrl = "https://files.catbox.moe/6dnudf.jpg",
            name = "Rohit",
            role = "Code Analyzer",
            onClick = { uriHandler.openUri("https://github.com/Rohit-Patel-Techie") }
        )

        // Hidden UserCard entries - commented out by Shivaay
        /*
        UserCard(
            imageUrl = "https://avatars.githubusercontent.com/u/205341163?v=4",
            name = "ϟ Priyanshu",
            role = "Code Refactor",
            onClick = { uriHandler.openUri("https://github.com/Shivaay200005") }
        )
        UserCard(
            imageUrl = "https://avatars.githubusercontent.com/u/106829560?v=4",
            name = "ϟ Priyanshu",
            role = "Translator",
            onClick = { uriHandler.openUri("https://github.com/Shivaay20005") }
        )

        UserCard(
            imageUrl = "https://avatars.githubusercontent.com/u/147309938?v=4",
            name = "「★」 Priyanshu",
            role = "Language selector",
            onClick = { uriHandler.openUri("https://github.com/Shivaay20005") }
        )
        */
    }
}


@Composable
fun CardItem(
    icon: Int,
    title: String,
    subtitle: String,
    onClick: () -> Unit
) {
    Card(
        modifier = Modifier
            .fillMaxWidth()
            .height(120.dp)
//            .shadow(8.dp, RoundedCornerShape(16.dp))
            .padding(horizontal = 16.dp),
        shape = RoundedCornerShape(20.dp),
        colors = CardDefaults.cardColors(
            containerColor = MaterialTheme.colorScheme.surfaceVariant,
        ),
        onClick = onClick
    ) {
        Row(
            modifier = Modifier
                .fillMaxSize()
                .padding(16.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Icon(
                painter = painterResource(icon),
                contentDescription = null,
                modifier = Modifier.size(28.dp),
                tint = MaterialTheme.colorScheme.primary
            )
            Spacer(modifier = Modifier.width(16.dp))
            Column {
                Text(
                    text = title,
                    style = MaterialTheme.typography.titleMedium,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
                Spacer(modifier = Modifier.height(4.dp))
                Text(
                    text = subtitle,
                    style = MaterialTheme.typography.bodyMedium,
                    color = MaterialTheme.colorScheme.onSurfaceVariant.copy(alpha = 0.7f)
                )

            }

        }
    }

}