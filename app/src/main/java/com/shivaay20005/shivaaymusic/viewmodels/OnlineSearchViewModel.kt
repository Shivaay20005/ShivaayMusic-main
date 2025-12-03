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
                            }.onFailure {
                                reportException(it)
                            }
                    }
                }
            }
        }
    }

    private suspend fun loadAllTabFallback() {
        // Fall back to loading songs for "All" tab
        YouTube
            .search(query, YouTube.SearchFilter.FILTER_SONG)
            .onSuccess { result ->
                summaryPage = SearchSummaryPage(
                    summaries = listOf(
                        SearchSummary(
                            title = "Songs",
                            items = result.items
                                .distinctBy { it.id }
                                .filterExplicit(
                                    context.dataStore.get(
                                        HideExplicitKey,
                                        false
                                    )
                                )
                        )
                    )
                )
            }.onFailure {
                reportException(it)
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
