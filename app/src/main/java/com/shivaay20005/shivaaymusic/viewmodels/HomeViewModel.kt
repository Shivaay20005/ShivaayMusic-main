package com.shivaay20005.shivaaymusic.viewmodels

import android.content.Context
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.shivaay20005.innertube.YouTube
import com.shivaay20005.innertube.models.PlaylistItem
import com.shivaay20005.innertube.models.WatchEndpoint
import com.shivaay20005.innertube.models.YTItem
import com.shivaay20005.innertube.pages.ExplorePage
import com.shivaay20005.innertube.pages.HomePage
import com.shivaay20005.innertube.utils.completedLibraryPage
import com.shivaay20005.shivaaymusic.db.MusicDatabase
import com.shivaay20005.shivaaymusic.db.entities.Album
import com.shivaay20005.shivaaymusic.db.entities.Artist
import com.shivaay20005.shivaaymusic.db.entities.LocalItem
import com.shivaay20005.shivaaymusic.db.entities.Playlist
import com.shivaay20005.shivaaymusic.db.entities.Song
import com.shivaay20005.shivaaymusic.models.SimilarRecommendation
import com.shivaay20005.shivaaymusic.models.SmartRecommendation
import com.shivaay20005.shivaaymusic.utils.RecommendationEngine
import com.shivaay20005.shivaaymusic.utils.reportException
import dagger.hilt.android.lifecycle.HiltViewModel
import dagger.hilt.android.qualifiers.ApplicationContext
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.async
import kotlinx.coroutines.awaitAll
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.launch
import javax.inject.Inject

@HiltViewModel
class HomeViewModel @Inject constructor(
    @ApplicationContext context: Context,
    val database: MusicDatabase,
) : ViewModel() {
    val isRefreshing = MutableStateFlow(false)
    val isLoading = MutableStateFlow(false)

    val quickPicks = MutableStateFlow<List<Song>?>(null)
    val forgottenFavorites = MutableStateFlow<List<Song>?>(null)
    val keepListening = MutableStateFlow<List<LocalItem>?>(null)
    val similarRecommendations = MutableStateFlow<List<SimilarRecommendation>?>(null)
    val accountPlaylists = MutableStateFlow<List<PlaylistItem>?>(null)
    val homePage = MutableStateFlow<HomePage?>(null)
    val explorePage = MutableStateFlow<ExplorePage?>(null)
    val recentActivity = MutableStateFlow<List<YTItem>?>(null)
    val recentPlaylistsDb = MutableStateFlow<List<Playlist>?>(null)

    // ShivaayMusic Exclusive - Smart Recommendations
    val smartRecommendations = MutableStateFlow<List<SmartRecommendation>?>(null)
    val forYouMix = MutableStateFlow<SmartRecommendation?>(null)

    val allLocalItems = MutableStateFlow<List<LocalItem>>(emptyList())
    val allYtItems = MutableStateFlow<List<YTItem>>(emptyList())

    val accountName = MutableStateFlow("Guest")
    val accountImageUrl = MutableStateFlow<String?>(null)

    private suspend fun load() {
        isLoading.value = true

        // PARALLEL LOADING - Load local data first (fast)
        // Increased limits to show more content - "bhar bhar ke songs"
        val quickPicksDeferred = viewModelScope.async(Dispatchers.IO) {
            database.quickPicks().first().shuffled().take(60)
        }
        
        val forgottenFavoritesDeferred = viewModelScope.async(Dispatchers.IO) {
            database.forgottenFavorites().first().shuffled().take(60)
        }

        val fromTimeStamp = System.currentTimeMillis() - 86400000 * 7 * 2
        
        val keepListeningDeferred = viewModelScope.async(Dispatchers.IO) {
            val songs = database.mostPlayedSongs(fromTimeStamp, limit = 50, offset = 3)
                .first().shuffled().take(30)
            val albums = database.mostPlayedAlbums(fromTimeStamp, limit = 25, offset = 1)
                .first().filter { it.album.thumbnailUrl != null }.shuffled().take(15)
            val artists = database.mostPlayedArtists(fromTimeStamp)
                .first().filter { it.artist.isYouTubeArtist && it.artist.thumbnailUrl != null }
                .shuffled().take(15)
            (songs + albums + artists).shuffled()
        }

        // Wait for local data to complete first (fast)
        quickPicks.value = quickPicksDeferred.await()
        forgottenFavorites.value = forgottenFavoritesDeferred.await()
        keepListening.value = keepListeningDeferred.await()

        allLocalItems.value =
            (quickPicks.value.orEmpty() + forgottenFavorites.value.orEmpty() + keepListening.value.orEmpty())
                .filter { it is Song || it is Album }

        // Now load network data in parallel with error handling
        val accountPlaylistsDeferred = viewModelScope.async(Dispatchers.IO) {
            if (YouTube.cookie != null) {
                YouTube.library("FEmusic_liked_playlists").completedLibraryPage()
                    .onFailure { reportException(it) }
                    .getOrNull()
                    ?.items?.filterIsInstance<PlaylistItem>()?.filterNot { it.id == "SE" }
            } else null
        }

        val homePageDeferred = viewModelScope.async(Dispatchers.IO) {
            YouTube.home()
                .onFailure { reportException(it) }
                .getOrNull()
        }

        val explorePageDeferred = viewModelScope.async(Dispatchers.IO) {
            YouTube.explore()
                .onFailure { reportException(it) }
                .getOrNull()
        }

        val smartRecsDeferred = viewModelScope.async(Dispatchers.IO) {
            try {
                forYouMix.value = RecommendationEngine.getMixedForYou(database)
                RecommendationEngine.getAllSmartRecommendations(database)
            } catch (e: Exception) {
                reportException(e)
                null
            }
        }

        // Wait for network data in parallel
        val results = awaitAll(
            accountPlaylistsDeferred,
            homePageDeferred,
            explorePageDeferred,
            smartRecsDeferred
        )
        
        accountPlaylists.value = results[0] as? List<PlaylistItem>
        homePage.value = results[1] as? HomePage
        smartRecommendations.value = results[3] as? List<SmartRecommendation>

        // Process explore page with artist sorting
        (results[2] as? ExplorePage)?.let { page ->
            val artists: Set<String>
            val favouriteArtists: Set<String>
            database.artistsBookmarkedByCreateDateAsc().first().let { list ->
                artists = list.map(Artist::id).toHashSet()
                favouriteArtists = list
                    .filter { it.artist.bookmarkedAt != null }
                    .map { it.id }
                    .toHashSet()
            }
            explorePage.value = page.copy(
                newReleaseAlbums = page.newReleaseAlbums
                    .sortedBy { album ->
                        if (album.artists.orEmpty().any { it.id in favouriteArtists }) 0
                        else if (album.artists.orEmpty().any { it.id in artists }) 1
                        else 2
                    }
            )
        }

        // Load similar recommendations in parallel (these are slower network calls)
        // Increased limits for more content - "bhar bhar ke aaye"
        viewModelScope.launch(Dispatchers.IO) {
            val artistRecommendations =
                database.mostPlayedArtists(fromTimeStamp, limit = 25).first()
                    .filter { it.artist.isYouTubeArtist }
                    .shuffled().take(10)
                    .mapNotNull {
                        val items = mutableListOf<YTItem>()
                        YouTube.artist(it.id).onSuccess { page ->
                            page.sections.forEach { section ->
                                items += section.items.shuffled().take(12)
                            }
                        }
                        SimilarRecommendation(
                            title = it,
                            items = items
                                .shuffled()
                                .take(30)
                                .ifEmpty { return@mapNotNull null }
                        )
                    }
            
            val songRecommendations =
                database.mostPlayedSongs(fromTimeStamp, limit = 40).first()
                    .filter { it.album != null }
                    .shuffled().take(10)
                    .mapNotNull { song ->
                        val endpoint =
                            YouTube.next(WatchEndpoint(videoId = song.id)).getOrNull()?.relatedEndpoint
                                ?: return@mapNotNull null
                        val page = YouTube.related(endpoint).getOrNull() ?: return@mapNotNull null
                        SimilarRecommendation(
                            title = song,
                            items = (page.songs.shuffled().take(25) +
                                    page.albums.shuffled().take(12) +
                                    page.artists.shuffled().take(10) +
                                    page.playlists.shuffled().take(12))
                                .shuffled()
                                .take(35)
                                .ifEmpty { return@mapNotNull null }
                        )
                    }
            similarRecommendations.value = (artistRecommendations + songRecommendations).shuffled()
        }

        allYtItems.value = similarRecommendations.value?.flatMap { it.items }.orEmpty() +
                homePage.value?.sections?.flatMap { it.items }.orEmpty() +
                explorePage.value?.newReleaseAlbums.orEmpty() +
                smartRecommendations.value?.flatMap { it.items }.orEmpty()

        isLoading.value = false
    }

    fun refresh() {
        if (isRefreshing.value) return
        viewModelScope.launch(Dispatchers.IO) {
            isRefreshing.value = true
            load()
            isRefreshing.value = false
        }
    }

    init {
        viewModelScope.launch(Dispatchers.IO) {
            load()
        }
    }
}