package com.shivaay20005.shivaaymusic.ui.screens

import androidx.compose.foundation.ExperimentalFoundationApi
import androidx.compose.foundation.combinedClickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.WindowInsets
import androidx.compose.foundation.layout.WindowInsetsSides
import androidx.compose.foundation.layout.asPaddingValues
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.only
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.systemBars
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.grid.GridCells
import androidx.compose.foundation.lazy.grid.LazyHorizontalGrid
import androidx.compose.foundation.lazy.grid.items
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.ui.Modifier
import androidx.compose.ui.hapticfeedback.HapticFeedbackType
import androidx.compose.ui.platform.LocalHapticFeedback
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.navigation.NavController
import com.shivaay20005.shivaaymusic.LocalPlayerAwareWindowInsets
import com.shivaay20005.shivaaymusic.LocalPlayerConnection
import com.shivaay20005.shivaaymusic.R
import com.shivaay20005.shivaaymusic.ui.component.LocalMenuState
import com.shivaay20005.shivaaymusic.ui.component.MoodSelectorCard
import com.shivaay20005.shivaaymusic.ui.component.NavigationTitle
import com.shivaay20005.shivaaymusic.ui.component.PodcastSection
import com.shivaay20005.shivaaymusic.ui.component.YouTubeGridItem
import com.shivaay20005.shivaaymusic.ui.component.YouTubeListItem
import com.shivaay20005.shivaaymusic.ui.component.shimmer.GridItemPlaceHolder
import com.shivaay20005.shivaaymusic.ui.component.shimmer.ShimmerHost
import com.shivaay20005.shivaaymusic.ui.component.shimmer.TextPlaceholder
import com.shivaay20005.shivaaymusic.ui.menu.YouTubeAlbumMenu
import com.shivaay20005.shivaaymusic.viewmodels.ExploreViewModel
import java.net.URLEncoder

@OptIn(ExperimentalFoundationApi::class)
@Composable
fun ExploreScreen(
    navController: NavController,
    viewModel: ExploreViewModel = hiltViewModel(),
) {
    val menuState = LocalMenuState.current
    val haptic = LocalHapticFeedback.current
    val playerConnection = LocalPlayerConnection.current ?: return
    val isPlaying by playerConnection.isPlaying.collectAsState()
    val mediaMetadata by playerConnection.mediaMetadata.collectAsState()

    val explorePage by viewModel.explorePage.collectAsState()

    val coroutineScope = rememberCoroutineScope()
    val scrollState = rememberScrollState()

    Box(
        modifier = Modifier.fillMaxSize(),
    ) {
        Column(
            modifier = Modifier.verticalScroll(scrollState),
        ) {
            Spacer(
                Modifier.height(
                    LocalPlayerAwareWindowInsets.current.asPaddingValues().calculateTopPadding(),
                ),
            )

            // ShivaayMusic Exclusive - Mood Selector
            MoodSelectorCard(
                onMoodSelected = { mood ->
                    navController.navigate("search/${URLEncoder.encode(mood.searchQuery, Charsets.UTF_8.name())}")
                },
            )

            explorePage?.moodAndGenres?.let { moodAndGenres ->
                NavigationTitle(
                    title = stringResource(R.string.mood_and_genres),
                    onClick = {
                        navController.navigate("mood_and_genres")
                    },
                )

                // Vertical layout for Moods and Genres (2 items per row)
                Column(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(horizontal = 6.dp),
                    verticalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    moodAndGenres.chunked(2).forEach { row ->
                        Row(
                            modifier = Modifier.fillMaxWidth(),
                            horizontalArrangement = Arrangement.spacedBy(8.dp)
                        ) {
                            row.forEach { item ->
                                MoodAndGenresButton(
                                    title = item.title,
                                    onClick = {
                                        navController.navigate("youtube_browse/${item.endpoint.browseId}?params=${item.endpoint.params}")
                                    },
                                    modifier = Modifier
                                        .weight(1f)
                                        .padding(vertical = 4.dp),
                                )
                            }
                            // Fill remaining space if odd number of items
                            if (row.size == 1) {
                                Spacer(modifier = Modifier.weight(1f))
                            }
                        }
                    }
                }
                
                Spacer(modifier = Modifier.height(16.dp))
            }

            // New Release Albums section - Mixed vertical and horizontal layout
            explorePage?.newReleaseAlbums?.takeIf { it.isNotEmpty() }?.let { newReleaseAlbums ->
                NavigationTitle(
                    title = stringResource(R.string.new_release_albums),
                    onClick = {
                        navController.navigate("new_release")
                    },
                )

                // Split: first 4 albums vertical, rest horizontal
                val verticalAlbums = newReleaseAlbums.take(4)
                val horizontalAlbums = newReleaseAlbums.drop(4)

                // Vertical album items
                verticalAlbums.forEach { album ->
                    YouTubeListItem(
                        item = album,
                        isActive = mediaMetadata?.album?.id == album.id,
                        isPlaying = isPlaying,
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(horizontal = 12.dp, vertical = 4.dp)
                            .combinedClickable(
                                onClick = {
                                    navController.navigate("album/${album.id}")
                                },
                                onLongClick = {
                                    haptic.performHapticFeedback(HapticFeedbackType.LongPress)
                                    menuState.show {
                                        YouTubeAlbumMenu(
                                            albumItem = album,
                                            navController = navController,
                                            onDismiss = menuState::dismiss
                                        )
                                    }
                                }
                            )
                    )
                }

                // Horizontal row for remaining albums
                if (horizontalAlbums.isNotEmpty()) {
                    LazyRow(
                        contentPadding = WindowInsets.systemBars
                            .only(WindowInsetsSides.Horizontal)
                            .asPaddingValues(),
                    ) {
                        items(
                            items = horizontalAlbums,
                            key = { it.id }
                        ) { album ->
                            YouTubeGridItem(
                                item = album,
                                isActive = mediaMetadata?.album?.id == album.id,
                                isPlaying = isPlaying,
                                coroutineScope = coroutineScope,
                                modifier = Modifier
                                    .combinedClickable(
                                        onClick = {
                                            navController.navigate("album/${album.id}")
                                        },
                                        onLongClick = {
                                            haptic.performHapticFeedback(HapticFeedbackType.LongPress)
                                            menuState.show {
                                                YouTubeAlbumMenu(
                                                    albumItem = album,
                                                    navController = navController,
                                                    onDismiss = menuState::dismiss
                                                )
                                            }
                                        }
                                    )
                            )
                        }
                    }
                }
            }

            Spacer(modifier = Modifier.height(16.dp))

            // ShivaayMusic Exclusive - Podcast Section (YouTube Video Section removed)
            PodcastSection(
                onSearchPodcast = { query ->
                    navController.navigate("search/${URLEncoder.encode(query, Charsets.UTF_8.name())}")
                }
            )

            Spacer(
                Modifier.height(
                    LocalPlayerAwareWindowInsets.current.asPaddingValues()
                        .calculateBottomPadding()
                )
            )

            if (explorePage == null) {
                ShimmerHost {
                    TextPlaceholder(
                        height = 36.dp,
                        modifier =
                            Modifier
                                .padding(vertical = 12.dp, horizontal = 12.dp)
                                .width(250.dp),
                    )
                    repeat(4) {
                        Row {
                            repeat(2) {
                                TextPlaceholder(
                                    height = MoodAndGenresButtonHeight,
                                    modifier =
                                        Modifier
                                            .padding(horizontal = 6.dp)
                                            .width(200.dp),
                                )
                            }
                        }
                    }
                    // Shimmer for new releases
                    TextPlaceholder(
                        height = 36.dp,
                        modifier =
                            Modifier
                                .padding(vertical = 12.dp, horizontal = 12.dp)
                                .width(200.dp),
                    )
                    LazyRow {
                        items(4) {
                            GridItemPlaceHolder()
                        }
                    }
                }
            }
        }
    }
}