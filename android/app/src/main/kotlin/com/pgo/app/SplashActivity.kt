package com.pgo.app

import android.app.Activity
import android.content.Intent
import android.media.MediaPlayer
import android.net.Uri
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.view.View
import android.widget.VideoView

class SplashActivity : Activity() {
    private val handler = Handler(Looper.getMainLooper())
    private var continued = false
    private var videoView: VideoView? = null

    private val fallback = Runnable { openFlutterApp() }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        window.decorView.systemUiVisibility = (
            View.SYSTEM_UI_FLAG_LAYOUT_STABLE
                or View.SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN
                or View.SYSTEM_UI_FLAG_FULLSCREEN
        )
        window.setBackgroundDrawableResource(android.R.color.black)

        videoView = VideoView(this).apply {
            setVideoURI(Uri.parse("android.resource://$packageName/${R.raw.startup_intro}"))
            setOnPreparedListener { mp ->
                mp.isLooping = false
                mp.setVideoScalingMode(MediaPlayer.VIDEO_SCALING_MODE_SCALE_TO_FIT)
                start()
                handler.postDelayed(fallback, 15000)
            }
            setOnCompletionListener {
                handler.post { openFlutterApp() }
            }
            setOnErrorListener { _, _, _ ->
                openFlutterApp()
                true
            }
        }

        setContentView(videoView)
        videoView?.requestFocus()
    }

    private fun openFlutterApp() {
        if (continued) return
        continued = true
        handler.removeCallbacks(fallback)
        videoView?.stopPlayback()
        val nextIntent = Intent(this, MainActivity::class.java)
        if (intent?.data != null) {
            nextIntent.action = Intent.ACTION_VIEW
            nextIntent.data = intent?.data
        }
        intent?.extras?.let { nextIntent.putExtras(it) }
        startActivity(nextIntent)
        overridePendingTransition(0, 0)
        finish()
    }

    override fun onDestroy() {
        handler.removeCallbacks(fallback)
        videoView?.stopPlayback()
        videoView = null
        super.onDestroy()
    }
}
