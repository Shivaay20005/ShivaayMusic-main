package com.shivaay20005.shivaaymusic.ui.screens.settings

import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.net.Uri
import android.os.Build
import android.util.Log
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.animation.AnimatedVisibility
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.gestures.detectTapGestures
import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.aspectRatio
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.layout.windowInsetsPadding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Info
import androidx.compose.material3.Button
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.Slider
import androidx.compose.material3.SliderDefaults
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.TopAppBar
import androidx.compose.material3.TopAppBarScrollBehavior
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableFloatStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.unit.dp
import androidx.datastore.core.DataStore
import androidx.datastore.preferences.core.Preferences
import androidx.datastore.preferences.core.edit
import androidx.datastore.preferences.core.stringPreferencesKey
import androidx.datastore.preferences.preferencesDataStore
import androidx.navigation.NavController
import coil.compose.AsyncImage
import coil.request.ImageRequest
import com.shivaay20005.shivaaymusic.LocalPlayerAwareWindowInsets
import com.shivaay20005.shivaaymusic.R
import com.shivaay20005.shivaaymusic.constants.AutoDarkModeKey
import com.shivaay20005.shivaaymusic.constants.ChipSortTypeKey
import com.shivaay20005.shivaaymusic.constants.DarkEndTimeKey
import com.shivaay20005.shivaaymusic.constants.DarkModeKey
import com.shivaay20005.shivaaymusic.constants.DarkStartTimeKey
import com.shivaay20005.shivaaymusic.constants.DefaultOpenTabKey
import com.shivaay20005.shivaaymusic.constants.DynamicThemeKey
import com.shivaay20005.shivaaymusic.constants.GridItemSize
import com.shivaay20005.shivaaymusic.constants.GridItemsSizeKey
import com.shivaay20005.shivaaymusic.constants.LibraryFilter
import com.shivaay20005.shivaaymusic.constants.LyricsClickKey
import com.shivaay20005.shivaaymusic.constants.LyricsTextPositionKey
import com.shivaay20005.shivaaymusic.constants.PlayerBackgroundStyle
import com.shivaay20005.shivaaymusic.constants.PlayerBackgroundStyleKey
import com.shivaay20005.shivaaymusic.constants.PlayerButtonsStyle
import com.shivaay20005.shivaaymusic.constants.PlayerButtonsStyleKey
import com.shivaay20005.shivaaymusic.constants.PlayerStyle
import com.shivaay20005.shivaaymusic.constants.PlayerStyleKey
import com.shivaay20005.shivaaymusic.constants.PlayerTextAlignmentKey
import com.shivaay20005.shivaaymusic.constants.PureBlackKey
import com.shivaay20005.shivaaymusic.constants.SliderStyle
import com.shivaay20005.shivaaymusic.constants.SliderStyleKey
import com.shivaay20005.shivaaymusic.constants.SlimNavBarKey
import com.shivaay20005.shivaaymusic.constants.SwipeThumbnailKey
import com.shivaay20005.shivaaymusic.ui.component.DefaultDialog
import com.shivaay20005.shivaaymusic.ui.component.EnumListPreference
import com.shivaay20005.shivaaymusic.ui.component.IconButton
import com.shivaay20005.shivaaymusic.ui.component.ListPreference
import com.shivaay20005.shivaaymusic.ui.component.PlayerSliderTrack
import com.shivaay20005.shivaaymusic.ui.component.PreferenceEntry
import com.shivaay20005.shivaaymusic.ui.component.PreferenceGroupTitle
import com.shivaay20005.shivaaymusic.ui.component.SwitchPreference
import com.shivaay20005.shivaaymusic.ui.component.TimePickerPreference
import com.shivaay20005.shivaaymusic.ui.component.ThumbnailCornerRadiusSelectorButton
import com.shivaay20005.shivaaymusic.ui.utils.backToMain
import com.shivaay20005.shivaaymusic.utils.rememberEnumPreference
import com.shivaay20005.shivaaymusic.utils.rememberPreference
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import me.saket.squiggles.SquigglySlider
import timber.log.Timber
import java.io.File
import java.io.FileOutputStream

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun AppearanceSettings(
    navController: NavController,
    scrollBehavior: TopAppBarScrollBehavior,
) {
    val (dynamicTheme, onDynamicThemeChange) = rememberPreference(
        DynamicThemeKey,
        defaultValue = true
    )
    val (playerTextAlignment, onPlayerTextAlignmentChange) =
        rememberEnumPreference(
            PlayerTextAlignmentKey,
            defaultValue = PlayerTextAlignment.CENTER,
        )

    val (darkMode, onDarkModeChange) = rememberEnumPreference(
        DarkModeKey,
        defaultValue = DarkMode.AUTO
    )

    val (autoDarkMode, onAutoDarkModeChange) = rememberPreference(
        AutoDarkModeKey,
        defaultValue = false
    )
    val (darkStartTime, onDarkStartTimeChange) = rememberPreference(
        DarkStartTimeKey,
        defaultValue = "18:00"
    )
    val (darkEndTime, onDarkEndTimeChange) = rememberPreference(
        DarkEndTimeKey,
        defaultValue = "06:00"
    )

    val (playerButtonsStyle, onPlayerButtonsStyleChange) = rememberEnumPreference(
        PlayerButtonsStyleKey,
        defaultValue = PlayerButtonsStyle.DEFAULT
    )
    val (playerStyle, onPlayerStyleChange) = rememberEnumPreference(
        PlayerStyleKey,
        defaultValue = PlayerStyle.VERTICAL_REELS
    )
    val (playerBackground, onPlayerBackgroundChange) =
        rememberEnumPreference(
            PlayerBackgroundStyleKey,
            defaultValue = PlayerBackgroundStyle.BLUR,
        )
    val (pureBlack, onPureBlackChange) = rememberPreference(PureBlackKey, defaultValue = false)
    val (defaultOpenTab, onDefaultOpenTabChange) = rememberEnumPreference(
        DefaultOpenTabKey,
        defaultValue = NavigationTab.HOME
    )
    val (lyricsPosition, onLyricsPositionChange) = rememberEnumPreference(
        LyricsTextPositionKey,
        defaultValue = LyricsPosition.CENTER
    )
    val (lyricsClick, onLyricsClickChange) = rememberPreference(LyricsClickKey, defaultValue = true)
    val (sliderStyle, onSliderStyleChange) = rememberEnumPreference(
        SliderStyleKey,
        defaultValue = SliderStyle.SQUIGGLY
    )
    val (swipeThumbnail, onSwipeThumbnailChange) = rememberPreference(
        SwipeThumbnailKey,
        defaultValue = true
    )
    val (gridItemSize, onGridItemSizeChange) = rememberEnumPreference(
        GridItemsSizeKey,
        defaultValue = GridItemSize.BIG
    )

    val (slimNav, onSlimNavChange) = rememberPreference(SlimNavBarKey, defaultValue = false)

    val availableBackgroundStyles = PlayerBackgroundStyle.entries.filter {
        it != PlayerBackgroundStyle.BLUR || Build.VERSION.SDK_INT >= Build.VERSION_CODES.S
    }

    val isSystemInDarkTheme = isSystemInDarkTheme()
    val useDarkTheme =
        remember(darkMode, isSystemInDarkTheme) {
            if (darkMode == DarkMode.AUTO) isSystemInDarkTheme else darkMode == DarkMode.ON
        }

    val (defaultChip, onDefaultChipChange) = rememberEnumPreference(
        key = ChipSortTypeKey,
        defaultValue = LibraryFilter.LIBRARY
    )

    var showSliderOptionDialog by rememberSaveable {
        mutableStateOf(false)
    }

    if (showSliderOptionDialog) {
        DefaultDialog(
            buttons = {
                TextButton(
                    onClick = { showSliderOptionDialog = false }
                ) {
                    Text(text = stringResource(android.R.string.cancel))
                }
            },
            onDismiss = {
                showSliderOptionDialog = false
            }
        ) {
            Row(
                horizontalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                Column(
                    horizontalAlignment = Alignment.CenterHorizontally,
                    verticalArrangement = Arrangement.spacedBy(4.dp),
                    modifier = Modifier
                        .aspectRatio(1f)
                        .weight(1f)
                        .clip(RoundedCornerShape(16.dp))
                        .border(
                            1.dp,
                            if (sliderStyle == SliderStyle.DEFAULT) MaterialTheme.colorScheme.primary else MaterialTheme.colorScheme.outlineVariant,
                            RoundedCornerShape(16.dp)
                        )
                        .clickable {
                            onSliderStyleChange(SliderStyle.DEFAULT)
                            showSliderOptionDialog = false
                        }
                        .padding(16.dp)
                ) {
                    var sliderValue by remember {
                        mutableFloatStateOf(0.5f)
                    }
                    Slider(
                        value = sliderValue,
                        valueRange = 0f..1f,
                        onValueChange = {
                            sliderValue = it
                        },
                        modifier = Modifier.weight(1f)
                    )
                    Text(
                        text = stringResource(R.string.default_),
                        style = MaterialTheme.typography.labelLarge
                    )
                }
                Column(
                    horizontalAlignment = Alignment.CenterHorizontally,
                    verticalArrangement = Arrangement.spacedBy(4.dp),
                    modifier = Modifier
                        .aspectRatio(1f)
                        .weight(1f)
                        .clip(RoundedCornerShape(16.dp))
                        .border(
                            1.dp,
                            if (sliderStyle == SliderStyle.SQUIGGLY) MaterialTheme.colorScheme.primary else MaterialTheme.colorScheme.outlineVariant,
                            RoundedCornerShape(16.dp)
                        )
                        .clickable {
                            onSliderStyleChange(SliderStyle.SQUIGGLY)
                            showSliderOptionDialog = false
                        }
                        .padding(16.dp)
                ) {
                    var sliderValue by remember {
                        mutableFloatStateOf(0.5f)
                    }
                    SquigglySlider(
                        value = sliderValue,
                        valueRange = 0f..1f,
                        onValueChange = {
                            sliderValue = it
                        },
                        modifier = Modifier.weight(1f)
                    )
                    Text(
                        text = stringResource(R.string.squiggly),
                        style = MaterialTheme.typography.labelLarge
                    )
                }
                Column(
                    horizontalAlignment = Alignment.CenterHorizontally,
                    verticalArrangement = Arrangement.spacedBy(4.dp),
                    modifier = Modifier
                        .aspectRatio(1f)
                        .weight(1f)
                        .clip(RoundedCornerShape(16.dp))
                        .border(
                            1.dp,
                            if (sliderStyle == SliderStyle.SLIM) MaterialTheme.colorScheme.primary else MaterialTheme.colorScheme.outlineVariant,
                            RoundedCornerShape(16.dp)
                        )
                        .clickable {
                            onSliderStyleChange(SliderStyle.SLIM)
                            showSliderOptionDialog = false
                        }
                        .padding(16.dp)
                ) {
                    var sliderValue by remember {
                        mutableFloatStateOf(0.5f)
                    }
                    Slider(
                        value = sliderValue,
                        valueRange = 0f..1f,
                        onValueChange = {
                            sliderValue = it
                        },
                        thumb = { Spacer(modifier = Modifier.size(0.dp)) },
                        track = { sliderState ->
                            PlayerSliderTrack(
                                sliderState = sliderState,
                                colors = SliderDefaults.colors()
                            )
                        },
                        modifier = Modifier
                            .weight(1f)
                            .pointerInput(Unit) {
                                detectTapGestures(
                                    onPress = {}
                                )
                            }
                    )

                    Text(
                        text = stringResource(R.string.slim),
                        style = MaterialTheme.typography.labelLarge
                    )
                }
            }
        }
    }

    Column(
        Modifier
            .windowInsetsPadding(LocalPlayerAwareWindowInsets.current)
            .verticalScroll(rememberScrollState()),
    ) {
        PreferenceGroupTitle(
            title = stringResource(R.string.theme),
        )

        SwitchPreference(
            title = { Text(stringResource(R.string.enable_dynamic_theme)) },
            icon = { Icon(painterResource(R.drawable.palette), null) },
            checked = dynamicTheme,
            onCheckedChange = onDynamicThemeChange,
        )

        EnumListPreference(
            title = { Text(stringResource(R.string.dark_theme)) },
            icon = { Icon(painterResource(R.drawable.dark_mode), null) },
            selectedValue = darkMode,
            onValueSelected = onDarkModeChange,
            valueText = {
                when (it) {
                    DarkMode.ON -> stringResource(R.string.dark_theme_on)
                    DarkMode.OFF -> stringResource(R.string.dark_theme_off)
                    DarkMode.AUTO -> stringResource(R.string.dark_theme_follow_system)
                }
            },
        )

        SwitchPreference(
            title = { Text(stringResource(R.string.auto_dark_mode)) },
            description = stringResource(R.string.auto_dark_mode_desc),
            icon = { Icon(painterResource(R.drawable.schedule), null) },
            checked = autoDarkMode,
            onCheckedChange = onAutoDarkModeChange,
        )

        AnimatedVisibility(autoDarkMode) {
            Column {
                TimePickerPreference(
                    title = stringResource(R.string.dark_start_time),
                    currentTime = darkStartTime,
                    onTimeSelected = onDarkStartTimeChange,
                    icon = { Icon(painterResource(R.drawable.dark_mode), null) },
                )
                TimePickerPreference(
                    title = stringResource(R.string.dark_end_time),
                    currentTime = darkEndTime,
                    onTimeSelected = onDarkEndTimeChange,
                    icon = { Icon(painterResource(R.drawable.lightbulb), null) },
                )
            }
        }

        AnimatedVisibility(useDarkTheme) {
            SwitchPreference(
                title = { Text(stringResource(R.string.pure_black)) },
                icon = { Icon(painterResource(R.drawable.contrast), null) },
                checked = pureBlack,
                onCheckedChange = onPureBlackChange,
            )
        }

        PreferenceGroupTitle(
            title = stringResource(R.string.player),
        )

        // Player Style preference
        EnumListPreference(
            title = { Text(stringResource(R.string.player_style)) },
            icon = { Icon(painterResource(R.drawable.play), null) },
            selectedValue = playerStyle,
            onValueSelected = onPlayerStyleChange,
            valueText = {
                when (it) {
                    PlayerStyle.CLASSIC -> stringResource(R.string.player_style_classic)
                    PlayerStyle.VERTICAL_REELS -> stringResource(R.string.player_style_vertical_reels)
                }
            },
        )

        // Determine available options based on Android version
        val availableBackgroundStyles = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            enumValues<PlayerBackgroundStyle>().toList()
        } else {
            enumValues<PlayerBackgroundStyle>().filter {
                it != PlayerBackgroundStyle.BLUR
            }
        }

// Also ensure the selected value is compatible
        val safeSelectedValue = if (playerBackground == PlayerBackgroundStyle.BLUR &&
            Build.VERSION.SDK_INT < Build.VERSION_CODES.S
        ) {
            PlayerBackgroundStyle.DEFAULT // Or any other default value
        } else {
            playerBackground
        }

// Use the updated component
        EnumListPreference(
            title = { Text(stringResource(R.string.player_background_style)) },
            icon = { Icon(painterResource(R.drawable.gradient), null) },
            selectedValue = safeSelectedValue,
            onValueSelected = onPlayerBackgroundChange,
            valueText = {
                when (it) {
                    PlayerBackgroundStyle.DEFAULT -> stringResource(R.string.follow_theme)
                    PlayerBackgroundStyle.GRADIENT -> stringResource(R.string.gradient)
                    PlayerBackgroundStyle.BLUR -> stringResource(R.string.player_background_blur)
                }
            },
            values = availableBackgroundStyles
        )

        ThumbnailCornerRadiusSelectorButton(
            modifier = Modifier.padding(16.dp),
            onRadiusSelected = { selectedRadius ->
                // Here you can handle the selected radius value
                Timber.tag("Thumbnail").d("Selected radius: $selectedRadius")
            }
        )

        EnumListPreference(
            title = { Text(stringResource(R.string.player_buttons_style)) },
            icon = { Icon(painterResource(R.drawable.palette), null) },
            selectedValue = playerButtonsStyle,
            onValueSelected = onPlayerButtonsStyleChange,
            valueText = {
                when (it) {
                    PlayerButtonsStyle.DEFAULT -> stringResource(R.string.default_style)
                    PlayerButtonsStyle.SECONDARY -> stringResource(R.string.secondary_color_style)
                }
            },
        )


        PreferenceEntry(
            title = { Text(stringResource(R.string.player_slider_style)) },
            description =
                when (sliderStyle) {
                    SliderStyle.DEFAULT -> stringResource(R.string.default_)
                    SliderStyle.SQUIGGLY -> stringResource(R.string.squiggly)
                    SliderStyle.SLIM -> stringResource(R.string.slim)
                },
            icon = { Icon(painterResource(R.drawable.sliders), null) },
            onClick = {
                showSliderOptionDialog = true
            },
        )

        SwitchPreference(
            title = { Text(stringResource(R.string.enable_swipe_thumbnail)) },
            icon = { Icon(painterResource(R.drawable.swipe), null) },
            checked = swipeThumbnail,
            onCheckedChange = onSwipeThumbnailChange,
        )
        EnumListPreference(
            title = { Text(stringResource(R.string.player_text_alignment)) },
            icon = {
                Icon(
                    painter =
                        painterResource(
                            when (playerTextAlignment) {
                                PlayerTextAlignment.CENTER -> R.drawable.format_align_center
                                PlayerTextAlignment.SIDED -> R.drawable.format_align_left
                            },
                        ),
                    contentDescription = null,
                )
            },
            selectedValue = playerTextAlignment,
            onValueSelected = onPlayerTextAlignmentChange,
            valueText = {
                when (it) {
                    PlayerTextAlignment.SIDED -> stringResource(R.string.sided)
                    PlayerTextAlignment.CENTER -> stringResource(R.string.center)
                }
            },
        )

        EnumListPreference(
            title = { Text(stringResource(R.string.lyrics_text_position)) },
            icon = { Icon(painterResource(R.drawable.lyrics), null) },
            selectedValue = lyricsPosition,
            onValueSelected = onLyricsPositionChange,
            valueText = {
                when (it) {
                    LyricsPosition.LEFT -> stringResource(R.string.left)
                    LyricsPosition.CENTER -> stringResource(R.string.center)
                    LyricsPosition.RIGHT -> stringResource(R.string.right)
                }
            },
        )

        SwitchPreference(
            title = { Text(stringResource(R.string.lyrics_click_change)) },
            icon = { Icon(painterResource(R.drawable.lyrics), null) },
            checked = lyricsClick,
            onCheckedChange = onLyricsClickChange,
        )

        PreferenceGroupTitle(
            title = stringResource(R.string.misc),
        )

        EnumListPreference(
            title = { Text(stringResource(R.string.default_open_tab)) },
            icon = { Icon(painterResource(R.drawable.nav_bar), null) },
            selectedValue = defaultOpenTab,
            onValueSelected = onDefaultOpenTabChange,
            valueText = {
                when (it) {
                    NavigationTab.HOME -> stringResource(R.string.home)
                    NavigationTab.EXPLORE -> stringResource(R.string.explore)
                    NavigationTab.MOOD -> stringResource(R.string.mood)
                    NavigationTab.LIBRARY -> stringResource(R.string.filter_library)
                }
            },
        )

        ListPreference(
            title = { Text(stringResource(R.string.default_lib_chips)) },
            icon = { Icon(painterResource(R.drawable.tab), null) },
            selectedValue = defaultChip,
            values = listOf(
                LibraryFilter.LIBRARY, LibraryFilter.PLAYLISTS, LibraryFilter.SONGS,
                LibraryFilter.ALBUMS, LibraryFilter.ARTISTS
            ),
            valueText = {
                when (it) {
                    LibraryFilter.SONGS -> stringResource(R.string.songs)
                    LibraryFilter.ARTISTS -> stringResource(R.string.artists)
                    LibraryFilter.ALBUMS -> stringResource(R.string.albums)
                    LibraryFilter.PLAYLISTS -> stringResource(R.string.playlists)
                    LibraryFilter.LIBRARY -> stringResource(R.string.filter_library)
                }
            },
            onValueSelected = onDefaultChipChange,
        )

        SwitchPreference(
            title = { Text(stringResource(R.string.slim_navbar)) },
            icon = { Icon(painterResource(R.drawable.nav_bar), null) },
            checked = slimNav,
            onCheckedChange = onSlimNavChange
        )

        EnumListPreference(
            title = { Text(stringResource(R.string.grid_cell_size)) },
            icon = { Icon(painterResource(R.drawable.grid_view), null) },
            selectedValue = gridItemSize,
            onValueSelected = onGridItemSizeChange,
            valueText = {
                when (it) {
                    GridItemSize.SMALL -> stringResource(R.string.small)
                    GridItemSize.BIG -> stringResource(R.string.big)
                }
            },
        )


        CustomAvatarSelector()
    }

    TopAppBar(
        title = { Text(stringResource(R.string.appearance)) },
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
    )
}



enum class DarkMode {
    ON,
    OFF,
    AUTO,
}

enum class NavigationTab {
    HOME,
    EXPLORE,
    MOOD,
    LIBRARY,
}

enum class LyricsPosition {
    LEFT,
    CENTER,
    RIGHT,
}

enum class PlayerTextAlignment {
    SIDED,
    CENTER,
}


// Extension property for DataStore
val Context.avatarDataStore: DataStore<Preferences> by preferencesDataStore(name = "avatar_preferences")

/** Preference manager for the custom avatar */
class AvatarPreferenceManager(private val context: Context) {
    companion object {
        private val CUSTOM_AVATAR_URI_KEY = stringPreferencesKey("custom_avatar_uri")
    }

    /** Saves the URI of the custom avatar */
    suspend fun saveCustomAvatarUri(uriString: String?) {
        context.avatarDataStore.edit { preferences ->
            if (uriString == null) {
                preferences.remove(CUSTOM_AVATAR_URI_KEY)
            } else {
                preferences[CUSTOM_AVATAR_URI_KEY] = uriString
            }
        }
    }

    /** Flow to get the custom avatar URI */
    val getCustomAvatarUri: Flow<String?> = context.avatarDataStore.data
        .map { preferences ->
            preferences[CUSTOM_AVATAR_URI_KEY]
        }
}

/**
 * Composable that allows the user to select and manage a custom
 * avatar
 */
@Composable
fun CustomAvatarSelector(
    modifier: Modifier = Modifier
) {
    val context = LocalContext.current
    val avatarManager = remember { AvatarPreferenceManager(context) }
    val customAvatarUri by avatarManager.getCustomAvatarUri.collectAsState(initial = null)

    var isLoading by remember { mutableStateOf(false) }
    var errorMessage by remember { mutableStateOf<String?>(null) }

    val coroutineScope = rememberCoroutineScope()

    val galleryLauncher = rememberLauncherForActivityResult(
        contract = ActivityResultContracts.GetContent()
    ) { uri: Uri? ->
        uri?.let {
            isLoading = true
            errorMessage = null

            coroutineScope.launch {
                val result = saveImageToInternalStorage(context, it)
                result.fold(
                    onSuccess = { savedFile ->
                        val savedUri = Uri.fromFile(savedFile)
                        avatarManager.saveCustomAvatarUri(savedUri.toString())
                    },
                    onFailure = { exception ->
                        errorMessage = context.getString(R.string.error_saving_image)
                        Log.e("CustomAvatarSelector", "Error saving image", exception)
                    }
                )
                isLoading = false
            }
        }
    }

    // Show error temporarily
    errorMessage?.let { error ->
        LaunchedEffect(error) {
            delay(4000)
            errorMessage = null
        }
    }

    Card(
        modifier = modifier.fillMaxWidth(),
        elevation = CardDefaults.cardElevation(defaultElevation = 2.dp),
        colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface)
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp)
        ) {
            Text(
                text = stringResource(id = R.string.custom_avatar_beta),
                style = MaterialTheme.typography.titleMedium,
                color = MaterialTheme.colorScheme.onSurface
            )

            Spacer(modifier = Modifier.height(12.dp))

            Row(
                verticalAlignment = Alignment.CenterVertically,
                modifier = Modifier.fillMaxWidth()
            ) {
                // Avatar with loading indicator
                Box(
                    modifier = Modifier
                        .size(72.dp)
                        .clip(CircleShape)
                        .border(
                            width = 2.dp,
                            color = MaterialTheme.colorScheme.primary.copy(alpha = 0.5f),
                            shape = CircleShape
                        )
                        .clickable(enabled = !isLoading) {
                            galleryLauncher.launch("image/*")
                        },
                    contentAlignment = Alignment.Center
                ) {
                    when {
                        isLoading -> {
                            CircularProgressIndicator(
                                modifier = Modifier.size(36.dp),
                                strokeWidth = 3.dp,
                                color = MaterialTheme.colorScheme.primary
                            )
                        }

                        customAvatarUri != null -> {
                            AsyncImage(
                                model = ImageRequest.Builder(context)
                                    .data(Uri.parse(customAvatarUri))
                                    .crossfade(true)
                                    .error(R.drawable.person)
                                    .placeholder(R.drawable.person)
                                    .build(),
                                contentDescription = stringResource(id = R.string.custom_avatar),
                                modifier = Modifier.fillMaxSize(),
                                contentScale = ContentScale.Crop
                            )
                        }

                        else -> {
                            Icon(
                                painter = painterResource(id = R.drawable.person),
                                contentDescription = stringResource(id = R.string.default_avatar),
                                modifier = Modifier.size(36.dp),
                                tint = MaterialTheme.colorScheme.onSurfaceVariant
                            )
                        }
                    }
                }

                Spacer(modifier = Modifier.width(16.dp))

                Column(modifier = Modifier.weight(1f)) {
                    Button(
                        onClick = { galleryLauncher.launch("image/*") },
                        modifier = Modifier.fillMaxWidth(),
                        enabled = !isLoading
                    ) {
                        if (isLoading) {
                            CircularProgressIndicator(
                                modifier = Modifier.size(16.dp),
                                strokeWidth = 2.dp,
                                color = MaterialTheme.colorScheme.onPrimary
                            )
                            Spacer(modifier = Modifier.width(8.dp))
                        }
                        Text(
                            text = if (isLoading)
                                stringResource(id = R.string.processing)
                            else
                                stringResource(id = R.string.select_image)
                        )
                    }

                    Spacer(modifier = Modifier.height(8.dp))

                    OutlinedButton(
                        onClick = {
                            coroutineScope.launch {
                                // Clean up old files before restoring
                                cleanupOldAvatars(context)
                                avatarManager.saveCustomAvatarUri(null)
                            }
                        },
                        modifier = Modifier.fillMaxWidth(),
                        enabled = customAvatarUri != null && !isLoading
                    ) {
                        Text(stringResource(id = R.string.restore_default_avatar))
                    }
                }
            }

            // Show error message
            errorMessage?.let { error ->
                Spacer(modifier = Modifier.height(8.dp))
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Icon(
                        imageVector = Icons.Default.Info,
                        contentDescription = null,
                        tint = MaterialTheme.colorScheme.error,
                        modifier = Modifier.size(16.dp)
                    )
                    Spacer(modifier = Modifier.width(8.dp))
                    Text(
                        text = error,
                        color = MaterialTheme.colorScheme.error,
                        style = MaterialTheme.typography.bodySmall
                    )
                }
            }
        }
    }
}

/** Improved function to save the image to internal storage */
private suspend fun saveImageToInternalStorage(
    context: Context,
    uri: Uri
): Result<File> = withContext(Dispatchers.IO) {
    try {
        context.contentResolver.openInputStream(uri)?.use { inputStream ->
            // Clean up old files before saving a new one
            cleanupOldAvatars(context)

            // Generate unique name to avoid conflicts
            val fileName = "custom_avatar_${System.currentTimeMillis()}.jpg"
            val outputFile = File(context.filesDir, fileName)

            // Decode and compress the image
            val bitmap = BitmapFactory.decodeStream(inputStream)
            val compressedBitmap = resizeAndCompressBitmap(bitmap, 500, 500)

            FileOutputStream(outputFile).use { outputStream ->
                compressedBitmap.compress(Bitmap.CompressFormat.JPEG, 85, outputStream)
            }

            // Clean up resources
            if (bitmap != compressedBitmap) {
                bitmap.recycle()
            }
            compressedBitmap.recycle()

            Result.success(outputFile)
        } ?: Result.failure(Exception("Could not open the file"))
    } catch (e: Exception) {
        Log.e("CustomAvatarSelector", "Error saving image to internal storage", e)
        Result.failure(e)
    }
}

/** Function to resize and compress bitmap */
private fun resizeAndCompressBitmap(
    bitmap: Bitmap,
    maxWidth: Int,
    maxHeight: Int
): Bitmap {
    val width = bitmap.width
    val height = bitmap.height

    val ratio = minOf(maxWidth.toFloat() / width, maxHeight.toFloat() / height)

    return if (ratio < 1.0f) {
        val newWidth = (width * ratio).toInt()
        val newHeight = (height * ratio).toInt()
        Bitmap.createScaledBitmap(bitmap, newWidth, newHeight, true)
    } else {
        bitmap
    }
}

/** Function to clean up old avatar files */
private fun cleanupOldAvatars(context: Context) {
    try {
        context.filesDir.listFiles()?.forEach { file ->
            if (file.name.startsWith("custom_avatar_") && file.name.endsWith(".jpg")) {
                val deleted = file.delete()
                Log.d(
                    "CustomAvatarSelector",
                    "Deleted old avatar file: ${file.name}, success: $deleted"
                )
            }
        }
    } catch (e: Exception) {
        Log.e("CustomAvatarSelector", "Error cleaning up old avatars", e)
    }
}

/** Data class to handle UI states (optional for future use) */
data class AvatarUiState(
    val isLoading: Boolean = false,
    val error: String? = null,
    val customAvatarUri: String? = null
)