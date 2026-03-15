package com.transpilot.app

import android.content.Intent
import android.database.Cursor
import android.net.Uri
import android.provider.OpenableColumns
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private var eventSink: EventChannel.EventSink? = null
    private var initialTorrent: Map<String, Any>? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            METHOD_CHANNEL,
        ).setMethodCallHandler { call, result ->
            if (call.method == "takeInitialTorrent") {
                result.success(initialTorrent)
                initialTorrent = null
            } else {
                result.notImplemented()
            }
        }

        EventChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            EVENT_CHANNEL,
        ).setStreamHandler(
            object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink) {
                    eventSink = events
                }

                override fun onCancel(arguments: Any?) {
                    eventSink = null
                }
            },
        )

        handleIncomingIntent(intent, preferInitialStorage = true)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        handleIncomingIntent(intent, preferInitialStorage = false)
    }

    private fun handleIncomingIntent(intent: Intent?, preferInitialStorage: Boolean) {
        val payload = extractTorrentPayload(intent) ?: return
        if (!preferInitialStorage && eventSink != null) {
            eventSink?.success(payload)
            return
        }
        initialTorrent = payload
    }

    private fun extractTorrentPayload(intent: Intent?): Map<String, Any>? {
        if (intent == null) {
            return null
        }

        if (intent.action == Intent.ACTION_VIEW) {
            val dataString = intent.dataString
            if (!dataString.isNullOrBlank() && dataString.startsWith(MAGNET_SCHEME, ignoreCase = true)) {
                return mapOf("magnetLink" to dataString)
            }
        }

        val uri = when (intent.action) {
            Intent.ACTION_VIEW -> intent.data
            Intent.ACTION_SEND -> intent.getParcelableExtra(Intent.EXTRA_STREAM, Uri::class.java)
            else -> null
        } ?: return null

        val name = resolveFileName(uri)
        val mimeType = contentResolver.getType(uri)
        val looksLikeTorrent = name.endsWith(TORRENT_EXTENSION, ignoreCase = true) ||
            mimeType == TORRENT_MIME_TYPE

        if (!looksLikeTorrent) {
            return null
        }

        val bytes = contentResolver.openInputStream(uri)?.use { it.readBytes() } ?: return null
        if (bytes.isEmpty()) {
            return null
        }

        return mapOf(
            "fileName" to name,
            "bytes" to bytes,
        )
    }

    private fun resolveFileName(uri: Uri): String {
        if (uri.scheme == "content") {
            val cursor: Cursor? = contentResolver.query(
                uri,
                arrayOf(OpenableColumns.DISPLAY_NAME),
                null,
                null,
                null,
            )
            cursor?.use {
                val index = it.getColumnIndex(OpenableColumns.DISPLAY_NAME)
                if (index >= 0 && it.moveToFirst()) {
                    val value = it.getString(index)
                    if (!value.isNullOrBlank()) {
                        return value
                    }
                }
            }
        }

        return uri.lastPathSegment?.substringAfterLast('/')?.takeIf { it.isNotBlank() }
            ?: "shared.torrent"
    }

    companion object {
        private const val METHOD_CHANNEL = "com.transpilot.app/incoming_torrent_method"
        private const val EVENT_CHANNEL = "com.transpilot.app/incoming_torrent_events"
        private const val MAGNET_SCHEME = "magnet:"
        private const val TORRENT_EXTENSION = ".torrent"
        private const val TORRENT_MIME_TYPE = "application/x-bittorrent"
    }
}
