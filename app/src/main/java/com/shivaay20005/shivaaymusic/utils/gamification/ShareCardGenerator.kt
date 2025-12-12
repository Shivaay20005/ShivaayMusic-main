package com.shivaay20005.shivaaymusic.utils.gamification

import android.content.Context
import android.graphics.*
import android.graphics.drawable.Drawable
import androidx.compose.ui.graphics.toArgb
import androidx.core.content.ContextCompat
import androidx.core.graphics.drawable.toBitmap
import com.shivaay20005.shivaaymusic.R
import com.shivaay20005.shivaaymusic.db.entities.UserStatsEntity
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import java.io.File
import java.io.FileOutputStream

/**
 * Generates shareable image cards for gamification achievements
 */
class ShareCardGenerator(private val context: Context) {

    /**
     * Generate a level milestone share card
     */
    suspend fun generateLevelCard(
        level: Int,
        username: String = "Music Enthusiast",
        stats: UserStatsEntity
    ): File = withContext(Dispatchers.IO) {
        val width = 1080
        val height = 1920
        val bitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bitmap)

        // Background gradient
        val gradient = LinearGradient(
            0f, 0f, 0f, height.toFloat(),
            intArrayOf(
                android.graphics.Color.parseColor("#6366F1"),
                android.graphics.Color.parseColor("#8B5CF6"),
                android.graphics.Color.parseColor("#D946EF")
            ),
            null,
            Shader.TileMode.CLAMP
        )
        val paint = Paint().apply {
            shader = gradient
            isAntiAlias = true
        }
        canvas.drawRect(0f, 0f, width.toFloat(), height.toFloat(), paint)

        // App branding
        val brandPaint = Paint().apply {
            color = Color.WHITE
            textSize = 60f
            typeface = Typeface.create(Typeface.DEFAULT, Typeface.BOLD)
            textAlign = Paint.Align.CENTER
            isAntiAlias = true
        }
        canvas.drawText("ShivaayMusic", width / 2f, 150f, brandPaint)

        // Level badge (large circle)
        val circlePaint = Paint().apply {
            color = Color.WHITE
            style = Paint.Style.FILL
            isAntiAlias = true
        }
        canvas.drawCircle(width / 2f, height / 2f - 200f, 250f, circlePaint)

        // Level text
        val levelTextPaint = Paint().apply {
            color = android.graphics.Color.parseColor("#6366F1")
            textSize = 100f
            typeface = Typeface.create(Typeface.DEFAULT, Typeface.BOLD)
            textAlign = Paint.Align.CENTER
            isAntiAlias = true
        }
        canvas.drawText("LEVEL", width / 2f, height / 2f - 280f, levelTextPaint)

        val levelNumPaint = Paint().apply {
            color = android.graphics.Color.parseColor("#6366F1")
            textSize = 200f
            typeface = Typeface.create(Typeface.DEFAULT, Typeface.BOLD)
            textAlign = Paint.Align.CENTER
            isAntiAlias = true
        }
        canvas.drawText("$level", width / 2f, height / 2f - 80f, levelNumPaint)

        // Username
        val usernamePaint = Paint().apply {
            color = Color.WHITE
            textSize = 70f
            typeface = Typeface.create(Typeface.DEFAULT, Typeface.BOLD)
            textAlign = Paint.Align.CENTER
            isAntiAlias = true
        }
        canvas.drawText(username, width / 2f, height / 2f + 200f, usernamePaint)

        // Stats
        val statsPaint = Paint().apply {
            color = Color.WHITE
            textSize = 45f
            textAlign = Paint.Align.CENTER
            isAntiAlias = true
        }

        val listeningHours = stats.totalListeningMs / (1000 * 60 * 60)
        var yPos = height / 2f + 320f
        canvas.drawText("🎵 Listening Time: ${listeningHours}h", width / 2f, yPos, statsPaint)
        
        yPos += 80f
        canvas.drawText("🎤 Artists Discovered: ${stats.uniqueArtists}", width / 2f, yPos, statsPaint)
        
        yPos += 80f
        canvas.drawText("💙 Songs Liked: ${stats.songsLiked}", width / 2f, yPos, statsPaint)
        
        yPos += 80f
        canvas.drawText("📝 Playlists: ${stats.playlistsCreated}", width / 2f, yPos, statsPaint)

        // Footer
        val footerPaint = Paint().apply {
            color = Color.WHITE
            textSize = 40f
            textAlign = Paint.Align.CENTER
            alpha = 180
            isAntiAlias = true
        }
        canvas.drawText("Share your music journey!", width / 2f, height - 150f, footerPaint)

        // Save to file
        val file = File(context.cacheDir, "shivaay_level_${level}_${System.currentTimeMillis()}.png")
        FileOutputStream(file).use { out ->
            bitmap.compress(Bitmap.CompressFormat.PNG, 100, out)
        }
        bitmap.recycle()

        file
    }

    /**
     * Generate a badge unlock share card
     */
    suspend fun generateBadgeCard(
        badgeIcon: String,
        badgeTitle: String,
        username: String = "Music Enthusiast"
    ): File = withContext(Dispatchers.IO) {
        val width = 1080
        val height = 1920
        val bitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bitmap)

        // Background
        val gradient = LinearGradient(
            0f, 0f, 0f, height.toFloat(),
            intArrayOf(
                android.graphics.Color.parseColor("#10B981"),
                android.graphics.Color.parseColor("#3B82F6"),
                android.graphics.Color.parseColor("#6366F1")
            ),
            null,
            Shader.TileMode.CLAMP
        )
        val paint = Paint().apply {
            shader = gradient
            isAntiAlias = true
        }
        canvas.drawRect(0f, 0f, width.toFloat(), height.toFloat(), paint)

        // App branding
        val brandPaint = Paint().apply {
            color = Color.WHITE
            textSize = 60f
            typeface = Typeface.create(Typeface.DEFAULT, Typeface.BOLD)
            textAlign = Paint.Align.CENTER
            isAntiAlias = true
        }
        canvas.drawText("ShivaayMusic", width / 2f, 150f, brandPaint)

        // Achievement unlocked text
        val achievementPaint = Paint().apply {
            color = Color.WHITE
            textSize = 80f
            typeface = Typeface.create(Typeface.DEFAULT, Typeface.BOLD)
            textAlign = Paint.Align.CENTER
            isAntiAlias = true
        }
        canvas.drawText("ACHIEVEMENT", width / 2f, height / 2f - 400f, achievementPaint)
        canvas.drawText("UNLOCKED!", width / 2f, height / 2f - 310f, achievementPaint)

        // Badge icon (emoji)
        val iconPaint = Paint().apply {
            color = Color.WHITE
            textSize = 300f
            textAlign = Paint.Align.CENTER
            isAntiAlias = true
        }
        canvas.drawText(badgeIcon, width / 2f, height / 2f + 50f, iconPaint)

        // Badge title
        val titlePaint = Paint().apply {
            color = Color.WHITE
            textSize = 70f
            typeface = Typeface.create(Typeface.DEFAULT, Typeface.BOLD)
            textAlign = Paint.Align.CENTER
            isAntiAlias = true
        }
        canvas.drawText(badgeTitle, width / 2f, height / 2f + 250f, titlePaint)

        // Username
        val usernamePaint = Paint().apply {
            color = Color.WHITE
            textSize = 55f
            textAlign = Paint.Align.CENTER
            isAntiAlias = true
        }
        canvas.drawText(username, width / 2f, height / 2f + 400f, usernamePaint)

        // Save to file
        val file = File(context.cacheDir, "shivaay_badge_${System.currentTimeMillis()}.png")
        FileOutputStream(file).use { out ->
            bitmap.compress(Bitmap.CompressFormat.PNG, 100, out)
        }
        bitmap.recycle()

        file
    }

    /**
     * Generate yearly stats share card
     */
    suspend fun generateYearlyStatsCard(
        year: Int,
        stats: UserStatsEntity,
        topArtist: String = "Various Artists",
        username: String = "Music Enthusiast"
    ): File = withContext(Dispatchers.IO) {
        val width = 1080
        val height = 1920
        val bitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bitmap)

        // Background
        val gradient = LinearGradient(
            0f, 0f, 0f, height.toFloat(),
            intArrayOf(
                android.graphics.Color.parseColor("#F59E0B"),
                android.graphics.Color.parseColor("#EF4444"),
                android.graphics.Color.parseColor("#DC2626")
            ),
            null,
            Shader.TileMode.CLAMP
        )
        val paint = Paint().apply {
            shader = gradient
            isAntiAlias = true
        }
        canvas.drawRect(0f, 0f, width.toFloat(), height.toFloat(), paint)

        // Year text
        val yearPaint = Paint().apply {
            color = Color.WHITE
            textSize = 100f
            typeface = Typeface.create(Typeface.DEFAULT, Typeface.BOLD)
            textAlign = Paint.Align.CENTER
            isAntiAlias = true
        }
        canvas.drawText("$year", width / 2f, 200f, yearPaint)

        val wrapUpPaint = Paint().apply {
            color = Color.WHITE
            textSize = 70f
            typeface = Typeface.create(Typeface.DEFAULT, Typeface.BOLD)
            textAlign = Paint.Align.CENTER
            isAntiAlias = true
        }
        canvas.drawText("Music Wrapped", width / 2f, 310f, wrapUpPaint)

        // Stats boxes
        val boxPaint = Paint().apply {
            color = Color.WHITE
            alpha = 40
            style = Paint.Style.FILL
            isAntiAlias = true
        }

        val statLabelPaint = Paint().apply {
            color = Color.WHITE
            textSize = 40f
            textAlign = Paint.Align.CENTER
            alpha = 200
            isAntiAlias = true
        }

        val statValuePaint = Paint().apply {
            color = Color.WHITE
            textSize = 80f
            typeface = Typeface.create(Typeface.DEFAULT, Typeface.BOLD)
            textAlign = Paint.Align.CENTER
            isAntiAlias = true
        }

        val listeningHours = stats.totalListeningMs / (1000 * 60 * 60)
        
        // Listening time box
        var yPos = 500f
        val boxHeight = 200f
        val boxMargin = 50f
        
        canvas.drawRoundRect(
            boxMargin, yPos, width - boxMargin, yPos + boxHeight,
            30f, 30f, boxPaint
        )
        canvas.drawText("Total Listening", width / 2f, yPos + 60f, statLabelPaint)
        canvas.drawText("${listeningHours}h", width / 2f, yPos + 150f, statValuePaint)

        // Artists box
        yPos += boxHeight + 30f
        canvas.drawRoundRect(
            boxMargin, yPos, width - boxMargin, yPos + boxHeight,
            30f, 30f, boxPaint
        )
        canvas.drawText("Artists Discovered", width / 2f, yPos + 60f, statLabelPaint)
        canvas.drawText("${stats.uniqueArtists}", width / 2f, yPos + 150f, statValuePaint)

        // Songs liked box
        yPos += boxHeight + 30f
        canvas.drawRoundRect(
            boxMargin, yPos, width - boxMargin, yPos + boxHeight,
            30f, 30f, boxPaint
        )
        canvas.drawText("Songs Liked", width / 2f, yPos + 60f, statLabelPaint)
        canvas.drawText("${stats.songsLiked}", width / 2f, yPos + 150f, statValuePaint)

        // Top artist
        yPos += boxHeight + 80f
        val topArtistPaint = Paint().apply {
            color = Color.WHITE
            textSize = 50f
            textAlign = Paint.Align.CENTER
            isAntiAlias = true
        }
        canvas.drawText("Top Artist:", width / 2f, yPos, topArtistPaint)
        
        val artistNamePaint = Paint().apply {
            color = Color.WHITE
            textSize = 65f
            typeface = Typeface.create(Typeface.DEFAULT, Typeface.BOLD)
            textAlign = Paint.Align.CENTER
            isAntiAlias = true
        }
        canvas.drawText(topArtist, width / 2f, yPos + 80f, artistNamePaint)

        // Username
        val usernamePaint = Paint().apply {
            color = Color.WHITE
            textSize = 50f
            textAlign = Paint.Align.CENTER
            isAntiAlias = true
        }
        canvas.drawText(username, width / 2f, height - 150f, usernamePaint)

        // Save to file
        val file = File(context.cacheDir, "shivaay_wrapped_${year}_${System.currentTimeMillis()}.png")
        FileOutputStream(file).use { out ->
            bitmap.compress(Bitmap.CompressFormat.PNG, 100, out)
        }
        bitmap.recycle()

        file
    }
}
