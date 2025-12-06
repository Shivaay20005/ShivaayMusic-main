package com.shivaay20005.shivaaymusic.viewmodels

import androidx.lifecycle.SavedStateHandle
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.shivaay20005.innertube.YouTube
import com.shivaay20005.innertube.models.PlaylistItem
import com.shivaay20005.innertube.models.SongItem
import com.shivaay20005.shivaaymusic.db.MusicDatabase
import com.shivaay20005.shivaaymusic.db.entities.PlaylistEntity
import com.shivaay20005.shivaaymusic.db.entities.PlaylistSongMap
import com.shivaay20005.shivaaymusic.models.toMediaMetadata
import com.shivaay20005.shivaaymusic.utils.reportException
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.launch
import javax.inject.Inject

@HiltViewModel
class OnlinePlaylistViewModel @Inject constructor(
    savedStateHandle: SavedStateHandle,
    private val database: MusicDatabase
) : ViewModel() {
    private val playlistId = savedStateHandle.get<String>("playlistId")!!

    val playlist = MutableStateFlow<PlaylistItem?>(null)
    val playlistSongs = MutableStateFlow<List<SongItem>>(emptyList())
    val dbPlaylist = database.playlistByBrowseId(playlistId)
        .stateIn(viewModelScope, SharingStarted.Lazily, null)
    
    // Loading state for large playlists
    val isLoading = MutableStateFlow(true)
    val loadingProgress = MutableStateFlow<String?>(null)
    val isSaving = MutableStateFlow(false)
    val saveProgress = MutableStateFlow<String?>(null)
    
    // Error state for displaying to user
    val errorMessage = MutableStateFlow<String?>(null)

    init {
        loadPlaylist()
    }
    
    /**
     * Load playlist with retry logic for failed attempts
     */
    fun loadPlaylist(retryCount: Int = 0) {
        viewModelScope.launch(Dispatchers.IO) {
            isLoading.value = true
            errorMessage.value = null
            loadingProgress.value = if (retryCount > 0) "Retrying... (attempt ${retryCount + 1})" else "Loading playlist..."
            
            // Clean up playlist ID - remove any VL prefix if accidentally added
            val cleanPlaylistId = playlistId.removePrefix("VL")
            
            YouTube.playlist(cleanPlaylistId)
                .onSuccess { playlistPage ->
                    playlist.value = playlistPage.playlist
                    val songs = playlistPage.songs.toMutableList()
                    playlistSongs.value = songs
                    loadingProgress.value = "Loaded ${songs.size} songs..."
                    errorMessage.value = null
                    
                    // Load continuation pages for large playlists
                    var continuation = playlistPage.songsContinuation
                    var pageCount = 1
                    var continuationFailures = 0
                    
                    while (continuation != null && continuationFailures < 3) {
                        pageCount++
                        val continuationPage = YouTube.playlistContinuation(continuation).getOrNull()
                        if (continuationPage != null) {
                            songs.addAll(continuationPage.songs)
                            playlistSongs.value = songs.toList()
                            loadingProgress.value = "Loaded ${songs.size} songs..."
                            continuation = continuationPage.continuation
                            continuationFailures = 0 // Reset failure count on success
                        } else {
                            continuationFailures++
                            if (continuationFailures < 3) {
                                // Wait a bit before retrying continuation
                                delay(500L)
                            } else {
                                // Stop trying but keep what we have
                                break
                            }
                        }
                    }
                    loadingProgress.value = if (songs.isEmpty()) "Playlist loaded (no songs)" else "Total: ${songs.size} songs"
                }.onFailure { exception ->
                    reportException(exception)
                    
                    val errorMsg = when {
                        exception.message?.contains("unavailable", ignoreCase = true) == true -> 
                            "This playlist is unavailable or private"
                        exception.message?.contains("private", ignoreCase = true) == true -> 
                            "This playlist is private"
                        exception.message?.contains("title not found", ignoreCase = true) == true ->
                            "Playlist not accessible. It may be private or deleted."
                        retryCount < 2 -> {
                            // Auto-retry on failure
                            delay(1000L)
                            loadPlaylist(retryCount + 1)
                            return@launch
                        }
                        else -> "Failed to load playlist. Please try again."
                    }
                    
                    loadingProgress.value = null
                    errorMessage.value = errorMsg
                }
            
            isLoading.value = false
        }
    }
    
    /**
     * Retry loading the playlist
     */
    fun retry() {
        loadPlaylist()
    }

    /**
     * Import the playlist to local database with progress tracking
     * This handles large playlists by batch inserting songs
     */
    fun importPlaylistToLocal(onComplete: (success: Boolean, message: String) -> Unit) {
        val currentPlaylist = playlist.value ?: run {
            onComplete(false, "Playlist not loaded")
            return
        }
        val currentSongs = playlistSongs.value
        if (currentSongs.isEmpty()) {
            onComplete(false, "No songs to import")
            return
        }

        viewModelScope.launch(Dispatchers.IO) {
            isSaving.value = true
            saveProgress.value = "Creating playlist..."
            
            try {
                database.transaction {
                    // Create the playlist entity
                    val playlistEntity = PlaylistEntity(
                        name = currentPlaylist.title,
                        browseId = currentPlaylist.id,
                        isEditable = currentPlaylist.isEditable,
                        playEndpointParams = currentPlaylist.playEndpoint?.params,
                        shuffleEndpointParams = currentPlaylist.shuffleEndpoint?.params,
                        radioEndpointParams = currentPlaylist.radioEndpoint?.params
                    ).toggleLike()
                    insert(playlistEntity)
                    
                    // Insert songs in batches for better performance with large playlists
                    val batchSize = 50
                    val totalSongs = currentSongs.size
                    
                    currentSongs.chunked(batchSize).forEachIndexed { batchIndex, batch ->
                        val startIndex = batchIndex * batchSize
                        saveProgress.value = "Importing songs ${startIndex + 1}-${minOf(startIndex + batch.size, totalSongs)} of $totalSongs..."
                        
                        batch.forEachIndexed { indexInBatch, song ->
                            val songMetadata = song.toMediaMetadata()
                            insert(songMetadata)
                            insert(
                                PlaylistSongMap(
                                    songId = songMetadata.id,
                                    playlistId = playlistEntity.id,
                                    position = startIndex + indexInBatch
                                )
                            )
                        }
                    }
                }
                
                saveProgress.value = "Import complete! ${currentSongs.size} songs added"
                onComplete(true, "Successfully imported ${currentSongs.size} songs")
            } catch (e: Exception) {
                reportException(e)
                saveProgress.value = "Import failed"
                onComplete(false, "Failed to import: ${e.message}")
            } finally {
                isSaving.value = false
            }
        }
    }
}
