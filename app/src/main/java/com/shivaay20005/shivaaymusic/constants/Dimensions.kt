package com.shivaay20005.shivaaymusic.constants


import androidx.compose.animation.core.Spring
import androidx.compose.animation.core.spring
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp

const val CONTENT_TYPE_HEADER = 0
const val CONTENT_TYPE_LIST = 1
const val CONTENT_TYPE_SONG = 2
const val CONTENT_TYPE_ARTIST = 3
const val CONTENT_TYPE_ALBUM = 4
const val CONTENT_TYPE_PLAYLIST = 5

val NavigationBarHeight = 80.dp
val MiniPlayerHeight = 64.dp
val QueuePeekHeight = 64.dp
val AppBarHeight = 64.dp

val ListItemHeight = 72.dp
val SuggestionItemHeight = 60.dp
val SearchFilterHeight = 52.dp
val ListThumbnailSize = 56.dp
val SmallGridThumbnailHeight = 120.dp
val GridThumbnailHeight = 160.dp
val AlbumThumbnailSize = 160.dp

val ThumbnailCornerRadius = 12.dp
val ThumbnailCornerRadiusV2 = 12.dp
val ThumbnailCornerRadiusVariant = 28.dp
val PlayerHorizontalPadding = 32.dp

val NavigationBarAnimationSpec = spring<Dp>(stiffness = Spring.StiffnessMediumLow)