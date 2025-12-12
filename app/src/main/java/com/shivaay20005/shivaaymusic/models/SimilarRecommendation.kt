package com.shivaay20005.shivaaymusic.models

import com.shivaay20005.innertube.models.YTItem
import com.shivaay20005.shivaaymusic.db.entities.LocalItem

data class SimilarRecommendation(
    val title: LocalItem,
    val items: List<YTItem>,
)
