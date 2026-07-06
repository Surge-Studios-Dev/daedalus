package com.surgestudios.myapp // TODO(per-app): your package

import android.content.Intent
import android.content.SharedPreferences
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * Android half of the share intake (extracted from Ladle). Mirrors the iOS
 * share-extension contract: the platform side queues shared URLs/text in
 * persistent storage and the Flutter side drains them over the share
 * MethodChannel on launch + every resume.
 *
 * Android's share entry point is an Intent — declare an ACTION_SEND filter
 * and launchMode="singleTop" in AndroidManifest so the running instance is
 * reused. When the user picks the app in another app's share sheet, the OS
 * delivers ACTION_SEND here; stash the payload before Flutter resumes and
 * the next drain picks it up.
 *
 * Unlike iOS (whose extension has its own UI and only sets present-on-open
 * for an explicit "Open app"), picking the app in the Android share sheet
 * always foregrounds it, so every share sets the flag.
 */
class MainActivity : FlutterActivity() {
    // TODO(per-app): channel "<slug>/share", prefs "<slug>.share".
    private val channelName = "myapp/share"
    private val prefsName = "myapp.share"
    private val queueKey = "pendingImports"
    private val presentKey = "presentOnOpen"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "drainPendingImports" -> {
                        val prefs = sharePrefs()
                        val queue = prefs.getStringSet(queueKey, emptySet())
                            ?.toList()
                            ?: emptyList()
                        prefs.edit().remove(queueKey).apply()
                        result.success(queue)
                    }
                    "takePresentOnOpen" -> {
                        val prefs = sharePrefs()
                        val present = prefs.getBoolean(presentKey, false)
                        prefs.edit().remove(presentKey).apply()
                        result.success(present)
                    }
                    else -> result.notImplemented()
                }
            }
        enqueueIfShareIntent(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        // singleTop: same Activity instance receives subsequent shares
        // while the app is already running.
        enqueueIfShareIntent(intent)
    }

    private fun enqueueIfShareIntent(intent: Intent?) {
        if (intent == null) return
        if (intent.action != Intent.ACTION_SEND) return
        val raw = intent.getStringExtra(Intent.EXTRA_TEXT) ?: return
        val value = raw.trim()
        if (value.isEmpty()) return
        val prefs = sharePrefs()
        val existing = prefs.getStringSet(queueKey, emptySet())?.toMutableSet()
            ?: mutableSetOf()
        existing.add(value)
        prefs.edit()
            .putStringSet(queueKey, existing)
            .putBoolean(presentKey, true)
            .apply()
    }

    private fun sharePrefs(): SharedPreferences =
        getSharedPreferences(prefsName, MODE_PRIVATE)
}
