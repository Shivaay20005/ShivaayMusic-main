package com.shivaay20005.shivaaymusic.viewmodels

import android.content.Context
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateMapOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.lifecycle.SavedStateHandle
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.shivaay20005.innertube.YouTube
import com.shivaay20005.innertube.models.filterExplicit
import com.shivaay20005.innertube.pages.SearchSummary
import com.shivaay20005.innertube.pages.SearchSummaryPage
import com.shivaay20005.shivaaymusic.constants.HideExplicitKey
import com.shivaay20005.shivaaymusic.models.ItemsPage
import com.shivaay20005.shivaaymusic.utils.dataStore
import com.shivaay20005.shivaaymusic.utils.get
import com.shivaay20005.shivaaymusic.utils.reportException
import dagger.hilt.android.lifecycle.HiltViewModel
import dagger.hilt.android.qualifiers.ApplicationContext
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.launch
import javax.inject.Inject

@HiltViewModel
class OnlineSearchViewModel
@Inject
constructor(
    @ApplicationContext val context: Context,
    savedStateHandle: SavedStateHandle,
) : ViewModel() {
    val query = savedStateHandle.get<String>("query")!!
    val filter = MutableStateFlow<YouTube.SearchFilter?>(null)
    var summaryPage by mutableStateOf<SearchSummaryPage?>(null)
    val viewStateMap = mutableStateMapOf<String, ItemsPage?>()

    // Minimum target items to load for rich search results
    private val minItemsTarget = 60

    init {
        viewModelScope.launch {
            filter.collect { filter ->
                if (filter == null) {
                    if (summaryPage == null) {
                        YouTube
                            .searchSummary(query)
                            .onSuccess {
                                val filteredPage = it.filterExplicit(
                                    context.dataStore.get(
                                        HideExplicitKey,
                                        false,
                                    ),
                                )
                                // If summaries are empty, fall back to song search
                                if (filteredPage.summaries.isEmpty()) {
                                    loadAllTabFallback()
                                } else {
                                    summaryPage = filteredPage
                                }
                            }.onFailure {
                                reportException(it)
                                // On failure, fall back to song search for "All" tab
                                loadAllTabFallback()
                            }
                    }
                } else {
                    if (viewStateMap[filter.value] == null) {
                        YouTube
                            .search(query, filter)
                            .onSuccess { result ->
                                viewStateMap[filter.value] =
                                    ItemsPage(
                                        result.items
                                            .distinctBy { it.id }
                                            .filterExplicit(
                                                context.dataStore.get(
                                                    HideExplicitKey,
                                                    false
                                                )
                                            ),
                                        result.continuation,
                                    )
                                // Pre-load more results to show 60-80 items initially
                                preloadMoreResults(filter.value)
                            }.onFailure {
                                reportException(it)
                            }
                    }
                }
            }
        }
    }

    /**
     * Pre-loads additional search results to reach the target count (60-80 items)
     * This provides a richer search experience with more content visible initially
     */
    private fun preloadMoreResults(filterValue: String) {
        viewModelScope.launch {
            var currentState = viewStateMap[filterValue] ?: return@launch
            var loadAttempts = 0
            val maxAttempts = 4 // Load up to 4 more pages to reach target
            
            while (currentState.items.size < minItemsTarget && 
                   currentState.continuation != null && 
                   loadAttempts < maxAttempts) {
                val searchResult = YouTube.searchContinuation(currentState.continuation!!)
                    .getOrNull() ?: break
                
                val newItems = (currentState.items + searchResult.items)
                    .distinctBy { it.id }
                    .filterExplicit(
                        context.dataStore.get(HideExplicitKey, false)
                    )
                
                currentState = ItemsPage(newItems, searchResult.continuation)
                viewStateMap[filterValue] = currentState
                loadAttempts++
            }
        }
    }

    private suspend fun loadAllTabFallback() {
        // Fall back to loading songs for "All" tab with multiple content types
        val allItems = mutableListOf<com.shivaay20005.innertube.models.YTItem>()
        var songContinuation: String? = null
        
        // Load songs
        YouTube.search(query, YouTube.SearchFilter.FILTER_SONG)
            .onSuccess { result ->
                allItems.addAll(result.items)
                songContinuation = result.continuation
            }
        
        // Load more songs to reach target
        var loadAttempts = 0
        while (allItems.size < minItemsTarget && songContinuation != null && loadAttempts < 4) {
            YouTube.searchContinuation(songContinuation!!)
                .onSuccess { result ->
                    allItems.addAll(result.items)
                    songContinuation = result.continuation
                }
                .onFailure { songContinuation = null }
            loadAttempts++
        }
        
        // Also load albums and playlists for variety
        YouTube.search(query, YouTube.SearchFilter.FILTER_ALBUM)
            .onSuccess { allItems.addAll(it.items.take(15)) }
        
        YouTube.search(query, YouTube.SearchFilter.FILTER_COMMUNITY_PLAYLIST)
            .onSuccess { allItems.addAll(it.items.take(15)) }
        
        val filteredItems = allItems
            .distinctBy { it.id }
            .filterExplicit(context.dataStore.get(HideExplicitKey, false))
        
        if (filteredItems.isNotEmpty()) {
            summaryPage = SearchSummaryPage(
                summaries = listOf(
                    SearchSummary(
                        title = "Songs",
                        items = filteredItems.filterIsInstance<com.shivaay20005.innertube.models.SongItem>()
                    ),
                    SearchSummary(
                        title = "Albums",
                        items = filteredItems.filterIsInstance<com.shivaay20005.innertube.models.AlbumItem>()
                    ),
                    SearchSummary(
                        title = "Playlists",
                        items = filteredItems.filterIsInstance<com.shivaay20005.innertube.models.PlaylistItem>()
                    )
                ).filter { it.items.isNotEmpty() }
            )
        }
    }

    fun loadMore() {
        val filter = filter.value?.value
        viewModelScope.launch {
            if (filter == null) return@launch
            val viewState = viewStateMap[filter] ?: return@launch
            val continuation = viewState.continuation
            if (continuation != null) {
                val searchResult =
                    YouTube.searchContinuation(continuation).getOrNull() ?: return@launch
                viewStateMap[filter] = ItemsPage(
                    (viewState.items + searchResult.items).distinctBy { it.id },
                    searchResult.continuation
                )
            }
        }
    }
}
