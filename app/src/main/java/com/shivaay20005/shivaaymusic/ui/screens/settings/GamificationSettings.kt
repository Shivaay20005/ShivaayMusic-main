package com.shivaay20005.shivaaymusic.ui.screens.settings

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.unit.dp
import androidx.navigation.NavController
import com.shivaay20005.shivaaymusic.LocalPlayerAwareWindowInsets
import com.shivaay20005.shivaaymusic.R
import com.shivaay20005.shivaaymusic.constants.GamificationEnabledKey
import com.shivaay20005.shivaaymusic.constants.GamificationHapticsKey
import com.shivaay20005.shivaaymusic.constants.ShareRemindersKey
import com.shivaay20005.shivaaymusic.constants.ShowLevelBadgeKey
import com.shivaay20005.shivaaymusic.ui.component.IconButton
import com.shivaay20005.shivaaymusic.ui.component.PreferenceEntry
import com.shivaay20005.shivaaymusic.ui.component.SwitchPreference
import com.shivaay20005.shivaaymusic.utils.rememberPreference

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun GamificationSettings(
    navController: NavController,
    scrollBehavior: TopAppBarScrollBehavior
) {
    val gamificationEnabled by rememberPreference(GamificationEnabledKey, defaultValue = true)
    val showLevelBadge by rememberPreference(ShowLevelBadgeKey, defaultValue = true)
    val gamificationHaptics by rememberPreference(GamificationHapticsKey, defaultValue = true)
    val shareReminders by rememberPreference(ShareRemindersKey, defaultValue = false)

    Column(
        modifier = Modifier
            .fillMaxSize()
            .windowInsetsPadding(LocalPlayerAwareWindowInsets.current.only(WindowInsetsSides.Horizontal + WindowInsetsSides.Bottom))
            .verticalScroll(rememberScrollState())
    ) {
        Spacer(Modifier.windowInsetsPadding(LocalPlayerAwareWindowInsets.current.only(WindowInsetsSides.Top)))

        // Header
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 16.dp, vertical = 8.dp),
            horizontalArrangement = Arrangement.SpaceBetween
        ) {
            com.shivaay20005.shivaaymusic.ui.component.ResizableIconButton(
                onClick = navController::navigateUp,
                icon = R.drawable.arrow_back
            )
        }

        Text(
            text = "Gamification",
            style = MaterialTheme.typography.headlineMedium,
            modifier = Modifier.padding(horizontal = 16.dp, vertical = 8.dp)
        )

        Text(
            text = "Level up your music experience with XP, badges, and rewards",
            style = MaterialTheme.typography.bodyMedium,
            color = MaterialTheme.colorScheme.onSurfaceVariant,
            modifier = Modifier.padding(horizontal = 16.dp, vertical = 4.dp)
        )

        Spacer(Modifier.height(16.dp))

        // Profile Link
        PreferenceEntry(
            title = { Text("View Your Profile") },
            description = "Check your level, achievements, and stats",
            icon = { Icon(painterResource(R.drawable.person), null) },
            onClick = { navController.navigate("profile") }
        )

        HorizontalDivider(modifier = Modifier.padding(vertical = 8.dp))

        // Enable/Disable Gamification
        SwitchPreference(
            title = { Text("Enable Gamification") },
            description = "Track XP, levels, and unlock rewards",
            icon = { Icon(painterResource(R.drawable.star), null) },
            checked = gamificationEnabled,
            onCheckedChange = { }
        )

        // Show Level Badge
        SwitchPreference(
            title = { Text("Show Level Badge") },
            description = "Display your level badge on profile",
            icon = { Icon(painterResource(R.drawable.label), null) },
            checked = showLevelBadge,
            onCheckedChange = { },
            isEnabled = gamificationEnabled
        )

        // Haptic Feedback
        SwitchPreference(
            title = { Text("Haptic Feedback") },
            description = "Vibrate on level up and achievements",
            icon = { Icon(painterResource(R.drawable.vibration), null) },
            checked = gamificationHaptics,
            onCheckedChange = { },
            isEnabled = gamificationEnabled
        )

        // Share Reminders
        SwitchPreference(
            title = { Text("Share Reminders") },
            description = "Suggest sharing milestones and achievements",
            icon = { Icon(painterResource(R.drawable.share), null) },
            checked = shareReminders,
            onCheckedChange = { },
            isEnabled = gamificationEnabled
        )

        Spacer(Modifier.height(16.dp))

        // Info Card
        Card(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp),
            colors = CardDefaults.cardColors(
                containerColor = MaterialTheme.colorScheme.primaryContainer
            )
        ) {
            Column(
                modifier = Modifier.padding(16.dp)
            ) {
                Text(
                    text = "How to Earn XP",
                    style = MaterialTheme.typography.titleMedium
                )
                Spacer(Modifier.height(8.dp))
                Text(
                    text = "• Listen to music: +10 XP per hour\n" +
                            "• Discover artists: +20 XP each\n" +
                            "• Like songs: +5 XP each\n" +
                            "• Create playlists: +30 XP each\n" +
                            "• Be active daily: +15 XP per day\n" +
                            "• Explore genres: +25 XP per genre",
                    style = MaterialTheme.typography.bodyMedium,
                    color = MaterialTheme.colorScheme.onPrimaryContainer
                )
            }
        }
    }
}
