package com.shivaay20005.shivaaymusicflutter

import com.ryanheise.audioservice.AudioServiceFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.media.audiofx.BassBoost
import android.media.audiofx.Virtualizer
import android.media.audiofx.LoudnessEnhancer

class MainActivity : AudioServiceFragmentActivity() {
    private val CHANNEL = "com.shivaay20005.shivaaymusic/booster"
    private var bassBoost: BassBoost? = null
    private var virtualizer: Virtualizer? = null
    private var loudnessEnhancer: LoudnessEnhancer? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "init" -> {
                    val sessionId = call.argument<Int>("sessionId") ?: 0
                    initBooster(sessionId)
                    result.success(null)
                }
                "setEnabled" -> {
                    val enabled = call.argument<Boolean>("enabled") ?: false
                    setEnabled(enabled)
                    result.success(null)
                }
                "setBass" -> {
                    val level = call.argument<Int>("level") ?: 0
                    setBass(level)
                    result.success(null)
                }
                "setVirtualizer" -> {
                    val level = call.argument<Int>("level") ?: 0
                    setVirtualizer(level)
                    result.success(null)
                }
                "setGain" -> {
                    val gain = call.argument<Int>("gain") ?: 0
                    setGain(gain)
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun initBooster(sessionId: Int) {
        if (sessionId == 0) return
        try {
            bassBoost?.release()
            virtualizer?.release()
            loudnessEnhancer?.release()
            
            bassBoost = BassBoost(0, sessionId)
            virtualizer = Virtualizer(0, sessionId)
            loudnessEnhancer = LoudnessEnhancer(sessionId)
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    private fun setEnabled(enabled: Boolean) {
        try {
            bassBoost?.enabled = enabled
            virtualizer?.enabled = enabled
            loudnessEnhancer?.enabled = enabled
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    private fun setBass(level: Int) {
        try {
            bassBoost?.setStrength(level.toShort())
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    private fun setVirtualizer(level: Int) {
        try {
            virtualizer?.setStrength(level.toShort())
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    private fun setGain(gain: Int) {
        try {
            loudnessEnhancer?.setTargetGain(gain)
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }
}
