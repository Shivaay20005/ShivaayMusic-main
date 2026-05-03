package com.shivaay20005.shivaaymusicflutter

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews

class ShivaayMusicWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {
        // Initial update for all widgets
        for (appWidgetId in appWidgetIds) {
            updateAppWidget(context, appWidgetManager, appWidgetId)
        }
    }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        
        if (intent.action == "com.shivaay20005.shivaaymusicflutter.UPDATE_WIDGET") {
            val appWidgetManager = AppWidgetManager.getInstance(context)
            val thisWidget = ComponentName(context, ShivaayMusicWidgetProvider::class.java)
            val appWidgetIds = appWidgetManager.getAppWidgetIds(thisWidget)
            
            for (appWidgetId in appWidgetIds) {
                val views = RemoteViews(context.packageName, R.layout.shivaay_music_widget)
                
                // Update text
                val title = intent.getStringExtra("song_title") ?: "ShivaayMusic"
                val artist = intent.getStringExtra("song_artist") ?: "No song playing"
                views.setTextViewText(R.id.widget_song_title, title)
                views.setTextViewText(R.id.widget_song_artist, artist)
                
                // Update Play/Pause Icon
                val playbackState = intent.getStringExtra("playback_state")
                if (playbackState == "playing") {
                    views.setImageViewResource(R.id.widget_play_pause_button, R.drawable.ic_pause)
                } else if (playbackState == "paused") {
                    views.setImageViewResource(R.id.widget_play_pause_button, R.drawable.ic_play_arrow)
                }
                
                appWidgetManager.updateAppWidget(appWidgetId, views)
            }
        }
    }

    private fun updateAppWidget(context: Context, appWidgetManager: AppWidgetManager, appWidgetId: Int) {
        val views = RemoteViews(context.packageName, R.layout.shivaay_music_widget)

        // Open App on Click
        val intent = Intent(context, MainActivity::class.java)
        val pendingIntent = PendingIntent.getActivity(
            context, 0, intent, 
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        views.setOnClickPendingIntent(R.id.widget_layout, pendingIntent)

        // Set up button intents (these would need to be handled by a service or receiver)
        // For now, we just link them back to the app or use broadcasts that the app listens to
        
        appWidgetManager.updateAppWidget(appWidgetId, views)
    }
}
