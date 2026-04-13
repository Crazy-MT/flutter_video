package com.example.yueshi_player


import android.content.Context
import android.content.Intent
import android.database.Cursor
import android.net.Uri
import android.provider.DocumentsContract
import android.provider.MediaStore

import android.content.ContentUris
import android.content.ContentResolver
import android.os.Build

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {

    private val CHANNEL = "com.bomanyi.ai/channel"
    private var methodChannel: MethodChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)

        methodChannel?.setMethodCallHandler { call, result ->
            if (call.method == "moveTaskToBack") {
                moveTaskToBack(true)
                result.success(null)
            } else {
                result.notImplemented()
            }
        }

        // 处理从 Intent 启动时的 URI
        handleIncomingVideo(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)  // 更新当前 intent
        handleIncomingVideo(intent)
    }

    private fun handleIncomingVideo(intent: Intent) {
        val data: Uri? = intent.data
        if (data != null) {
            // 把 URI 转成字符串发给 Flutter
            methodChannel?.invokeMethod("onVideoReceived",getRealPathFromUri(this,  data))
            methodChannel?.invokeMethod("onVideoReceivedUri",data.toString())
        }
    }

    private fun getRealPathFromUri(context: Context, uri: Uri): String? {
        // DocumentProvider
        if (DocumentsContract.isDocumentUri(context, uri)) {
            val docId = DocumentsContract.getDocumentId(uri)
            val split = docId.split(":")
            if (uri.authority == "com.android.externalstorage.documents") {
                val type = split[0]
                val relativePath = split[1]
                val fullPath = "/storage/emulated/0/$relativePath"
                return fullPath
            } else if (uri.authority == "com.android.providers.media.documents") {
                val contentUri = when (split[0]) {
                    "image" -> MediaStore.Images.Media.EXTERNAL_CONTENT_URI
                    "video" -> MediaStore.Video.Media.EXTERNAL_CONTENT_URI
                    "audio" -> MediaStore.Audio.Media.EXTERNAL_CONTENT_URI
                    else -> null
                }
                val selection = "_id=?"
                val selectionArgs = arrayOf(split[1])
                return getDataColumn(context, contentUri, selection, selectionArgs)
            }
        }
        // content://
        else if ("content".equals(uri.scheme, ignoreCase = true)) {
            return getDataColumn(context, uri, null, null)
        }
        // file://
        else if ("file".equals(uri.scheme, ignoreCase = true)) {
            return uri.path
        }
        return null
    }

    private fun getDataColumn(
        context: Context,
        uri: Uri?,
        selection: String?,
        selectionArgs: Array<String>?
    ): String? {
        var cursor: Cursor? = null
        val projection = arrayOf(MediaStore.Images.Media.DATA)
        try {
            cursor = context.contentResolver.query(uri!!, projection, selection, selectionArgs, null)
            if (cursor != null && cursor.moveToFirst()) {
                val index = cursor.getColumnIndexOrThrow(MediaStore.Images.Media.DATA)
                return cursor.getString(index)
            }
        } finally {
            cursor?.close()
        }
        return null
    }
}
