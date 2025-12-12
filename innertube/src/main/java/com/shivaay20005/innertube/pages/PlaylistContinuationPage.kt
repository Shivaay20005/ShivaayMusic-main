package com.shivaay20005.innertube.pages

import com.shivaay20005.innertube.models.SongItem

data class PlaylistContinuationPage(
    val songs: List<SongItem>,
    val continuation: String?,
)
