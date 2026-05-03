package com.shivaay20005.shivaaymusicflutter

import android.content.Context
import android.content.Intent
import androidx.annotation.NonNull
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

class WidgetService: FlutterPlugin, MethodCallHandler {
    private lateinit var channel: MethodChannel
    private var context: Context? = null

    companion object {
        const val CHANNEL = "com.shivaay20005.shivaaymusicflutter/widget"
    }

    override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        context = flutterPluginBinding.applicationContext
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, CHANNEL)
        channel.setMethodCallHandler(this)
    }

    override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
        when (call.method) {
            "updateWidget" -> updateWidget(call, result)
            "notifyPlay" -> notifyPlay(result)
            "notifyPause" -> notifyPause(result)
            else -> result.notImplemented()
        }
    }

    private fun updateWidget(call: MethodCall, result: Result) {
        try {
            val songTitle = call.argument<String>("songTitle")
            val songArtist = call.argument<String>("songArtist")
            val isPlaying = call.argument<Boolean>("isPlaying") ?: false

            // Send broadcast to update widget
            val intent = Intent("com.shivaay20005.shivaaymusicflutter.UPDATE_WIDGET")
            intent.putExtra("song_title", songTitle)
            intent.putExtra("song_artist", songArtist)
            intent.putExtra("playback_state", if (isPlaying) "playing" else "paused")
            
            context?.sendBroadcast(intent)
            result.success(null)
        } catch (e: Exception) {
            result.error("UPDATE_ERROR", e.message, null)
        }
    }

    private fun notifyPlay(result: Result) {
        try {
            // Update widget to show pause button
            val intent = Intent("com.shivaay20005.shivaaymusicflutter.UPDATE_WIDGET")
            intent.putExtra("playback_state", "playing")
            
            context?.sendBroadcast(intent)
            result.success(null)
        } catch (e: Exception) {
            result.error("NOTIFY_ERROR", e.message, null)
        }
    }

    private fun notifyPause(result: Result) {
        try {
            // Update widget to show play button
            val intent = Intent("com.shivaay20005.shivaaymusicflutter.UPDATE_WIDGET")
            intent.putExtra("playback_state", "paused")
            
            context?.sendBroadcast(intent)
            result.success(null)
        } catch (e: Exception) {
            result.error("NOTIFY_ERROR", e.message, null)
        }
    }

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }
}