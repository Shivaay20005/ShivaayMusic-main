package com.shivaay20005.shivaaymusic.models

import com.shivaay20005.innertube.models.YTItem

data class ItemsPage(
    val items: List<YTItem>,
    val continuation: String?,
)
