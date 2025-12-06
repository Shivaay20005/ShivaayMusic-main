package com.shivaay20005.shivaaymusic.ui.component

import android.content.Intent
import android.net.Uri
import android.widget.Toast
import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.slideInVertically
import androidx.compose.animation.slideOutVertically
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.shivaay20005.shivaaymusic.BuildConfig
import com.shivaay20005.shivaaymusic.R
import com.shivaay20005.shivaaymusic.utils.Updater
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext

/**
 * Update Alert Banner that shows on HomeScreen when a new app version is available
 * User can click to download update or dismiss with X button
 */
@Composable
fun UpdateAlertBanner(
    modifier: Modifier = Modifier,
) {
    val context = LocalContext.current
    var showBanner by rememberSaveable { mutableStateOf(false) }
    var latestVersion by rememberSaveable { mutableStateOf<String?>(null) }
    var isDismissed by rememberSaveable { mutableStateOf(false) }
    
    // Check for updates
    LaunchedEffect(Unit) {
        if (isDismissed) return@LaunchedEffect
        
        withContext(Dispatchers.IO) {
            Updater.getLatestVersionName()
                .onSuccess { version ->
                    latestVersion = version
                    val isNewer = isNewerVersion(version, BuildConfig.VERSION_NAME)
                    if (isNewer) {
                        showBanner = true
                    }
                }
        }
    }
    
    AnimatedVisibility(
        visible = showBanner && !isDismissed,
        enter = slideInVertically(initialOffsetY = { -it }) + fadeIn(),
        exit = slideOutVertically(targetOffsetY = { -it }) + fadeOut(),
        modifier = modifier
    ) {
        Box(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 12.dp, vertical = 8.dp)
                .clip(RoundedCornerShape(16.dp))
                .background(MaterialTheme.colorScheme.primaryContainer)
                .clickable {
                    // Open GitHub releases page or APK download
                    try {
                        val intent = Intent(
                            Intent.ACTION_VIEW,
                            Uri.parse("https://github.com/shivaay20005/shivaaymusic/releases/latest")
                        )
                        context.startActivity(intent)
                    } catch (e: Exception) {
                        Toast.makeText(
                            context,
                            context.getString(R.string.download_errorup),
                            Toast.LENGTH_SHORT
                        ).show()
                    }
                }
                .padding(12.dp)
        ) {
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Row(
                    verticalAlignment = Alignment.CenterVertically,
                    modifier = Modifier.weight(1f)
                ) {
                    // Update icon
                    Icon(
                        painter = painterResource(R.drawable.update),
                        contentDescription = null,
                        tint = MaterialTheme.colorScheme.primary,
                        modifier = Modifier.size(28.dp)
                    )
                    
                    Spacer(modifier = Modifier.width(12.dp))
                    
                    // Update text
                    Text(
                        text = stringResource(R.string.update_version, latestVersion ?: ""),
                        style = MaterialTheme.typography.bodyMedium,
                        fontWeight = FontWeight.SemiBold,
                        color = MaterialTheme.colorScheme.onPrimaryContainer
                    )
                    
                    Spacer(modifier = Modifier.width(8.dp))
                    
                    Text(
                        text = "• ${stringResource(R.string.tap_to_update)}",
                        style = MaterialTheme.typography.bodySmall,
                        color = MaterialTheme.colorScheme.onPrimaryContainer.copy(alpha = 0.7f)
                    )
                }
                
                // Dismiss button (X)
                IconButton(
                    onClick = {
                        isDismissed = true
                        showBanner = false
                    },
                    modifier = Modifier
                        .size(32.dp)
                        .clip(CircleShape)
                        .background(MaterialTheme.colorScheme.onPrimaryContainer.copy(alpha = 0.1f))
                ) {
                    Icon(
                        painter = painterResource(R.drawable.close),
                        contentDescription = "Dismiss",
                        tint = MaterialTheme.colorScheme.onPrimaryContainer,
                        modifier = Modifier.size(18.dp)
                    )
                }
            }
        }
    }
}

/**
 * Compare version strings to check if remote is newer than current
 */
private fun isNewerVersion(remoteVersion: String, currentVersion: String): Boolean {
    val remote = remoteVersion.removePrefix("v").split(".").mapNotNull { it.toIntOrNull() }
    val current = currentVersion.removePrefix("v").split(".").mapNotNull { it.toIntOrNull() }

    for (i in 0 until maxOf(remote.size, current.size)) {
        val r = remote.getOrNull(i) ?: 0
        val c = current.getOrNull(i) ?: 0
        if (r > c) return true
        if (r < c) return false
    }
    return false
}
