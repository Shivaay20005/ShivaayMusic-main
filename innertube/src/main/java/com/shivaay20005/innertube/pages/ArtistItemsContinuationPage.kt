package com.shivaay20005.innertube.pages

import com.shivaay20005.innertube.models.YTItem

data class ArtistItemsContinuationPage(
    val items: List<YTItem>,
    val continuation: String?,
)
