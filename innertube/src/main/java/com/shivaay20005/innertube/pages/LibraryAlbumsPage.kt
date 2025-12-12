package com.shivaay20005.innertube.pages

import com.shivaay20005.innertube.models.Album
import com.shivaay20005.innertube.models.AlbumItem
import com.shivaay20005.innertube.models.Artist
import com.shivaay20005.innertube.models.ArtistItem
import com.shivaay20005.innertube.models.MusicResponsiveListItemRenderer
import com.shivaay20005.innertube.models.MusicTwoRowItemRenderer
import com.shivaay20005.innertube.models.PlaylistItem
import com.shivaay20005.innertube.models.SongItem
import com.shivaay20005.innertube.models.YTItem
import com.shivaay20005.innertube.models.oddElements
import com.shivaay20005.innertube.utils.parseTime

data class LibraryAlbumsPage(
    val albums: List<AlbumItem>,
    val continuation: String?,
) {
    companion object {
        fun fromMusicTwoRowItemRenderer(renderer: MusicTwoRowItemRenderer): AlbumItem? {
            return AlbumItem(
                        browseId = renderer.navigationEndpoint.browseEndpoint?.browseId ?: return null,
                        playlistId = renderer.thumbnailOverlay?.musicItemThumbnailOverlayRenderer?.content
                            ?.musicPlayButtonRenderer?.playNavigationEndpoint
                            ?.watchPlaylistEndpoint?.playlistId ?: return null,
                        title = renderer.title.runs?.firstOrNull()?.text ?: return null,
                        artists = null,
                        year = renderer.subtitle?.runs?.lastOrNull()?.text?.toIntOrNull(),
                        thumbnail = renderer.thumbnailRenderer.musicThumbnailRenderer?.getThumbnailUrl() ?: return null,
                        explicit = renderer.subtitleBadges?.find {
                            it.musicInlineBadgeRenderer?.icon?.iconType == "MUSIC_EXPLICIT_BADGE"
                        } != null
                    )
        }
    }
}
