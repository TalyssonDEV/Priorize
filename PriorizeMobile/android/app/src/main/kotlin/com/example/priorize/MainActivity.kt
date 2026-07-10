package com.example.priorize

import android.app.Activity
import android.content.ContentValues
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.provider.OpenableColumns
import android.provider.MediaStore
import android.webkit.MimeTypeMap
import com.example.priorize.p2p.*
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.net.Inet4Address
import java.net.NetworkInterface
import java.util.UUID
import java.util.concurrent.Executors
import org.json.JSONObject

class MainActivity : FlutterActivity() {
    private val channelName = "priorize/p2p"
    private val fileRequestCode = 4102
    private val catalog get() = PeerRuntime.catalog()
    private val peerServer get() = PeerRuntime.server()
    private val background = Executors.newCachedThreadPool()
    private var pendingFileResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        restoreFileCatalog()
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler(::handleMethod)
    }

    private fun handleMethod(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "startPeerServer" -> background.execute {
                try {
                    val port = peerServer.start(call.argument<Int>("port") ?: 0)
                    startPeerForegroundService()
                    runOnUiThread { result.success(mapOf("port" to port, "ipAddress" to localIpv4(), "running" to true)) }
                } catch (error: Exception) { runOnUiThread { result.error("START_ERROR", error.message, null) } }
            }
            "stopPeerServer" -> { stopPeerForegroundService(); result.success(true) }
            "getPeerStatus" -> result.success(mapOf("running" to peerServer.isRunning, "port" to peerServer.port, "ipAddress" to localIpv4()))
            "selectLocalFile" -> selectFile(result)
            "registerLocalFile" -> registerLocalFile(call, result)
            "downloadFile" -> downloadFile(call, result)
            "openDownloadedFile" -> openDownloadedFile(call, result)
            else -> result.notImplemented()
        }
    }

    private fun selectFile(result: MethodChannel.Result) {
        if (pendingFileResult != null) { result.error("BUSY", "Já existe uma seleção em andamento", null); return }
        pendingFileResult = result
        startActivityForResult(Intent(Intent.ACTION_OPEN_DOCUMENT).apply {
            addCategory(Intent.CATEGORY_OPENABLE); type = "*/*"
        }, fileRequestCode)
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode != fileRequestCode) return
        val result = pendingFileResult ?: return
        pendingFileResult = null
        val uri = data?.data
        if (resultCode != Activity.RESULT_OK || uri == null) { result.success(null); return }
        background.execute {
            try {
                val copied = copyUriToAppStorage(uri)
                val hash = HashService.sha256(copied)
                val displayName = copied.name.substringAfter('-', copied.name)
                runOnUiThread { result.success(mapOf("path" to copied.absolutePath, "name" to displayName, "size" to copied.length(), "sha256" to hash)) }
            } catch (error: Exception) { runOnUiThread { result.error("FILE_ERROR", error.message, null) } }
        }
    }

    private fun copyUriToAppStorage(uri: Uri): File {
        var name = "arquivo-${UUID.randomUUID()}"
        contentResolver.query(uri, null, null, null, null)?.use { cursor ->
            val index = cursor.getColumnIndex(OpenableColumns.DISPLAY_NAME)
            if (cursor.moveToFirst() && index >= 0) name = File(cursor.getString(index)).name
        }
        val folder = File(filesDir, "shared").apply { mkdirs() }
        val destination = File(folder, "${System.currentTimeMillis()}-$name")
        contentResolver.openInputStream(uri).use { input ->
            requireNotNull(input) { "Não foi possível abrir o arquivo" }
            destination.outputStream().use { output -> input.copyTo(output, 8192) }
        }
        return destination
    }

    private fun registerLocalFile(call: MethodCall, result: MethodChannel.Result) {
        try {
            registerAndPersist(FileMetadata(
                call.argument<String>("fileId")!!, call.argument<String>("name")!!,
                (call.argument<Number>("size")!!).toLong(), call.argument<String>("sha256")!!,
                call.argument<String>("path")!!
            ))
            result.success(true)
        } catch (error: Exception) { result.error("CATALOG_ERROR", error.message, null) }
    }

    private fun downloadFile(call: MethodCall, result: MethodChannel.Result) = background.execute {
        val fileId = call.argument<String>("fileId")!!
        val name = File(call.argument<String>("fileName")!!).name
        val folder = File(filesDir, "downloads")
        val destination = File(folder.apply { mkdirs() }, name)
        val transfer = PeerFileClient().download(
            call.argument<String>("ipAddress")!!, (call.argument<Number>("port")!!).toInt(),
            fileId, destination, call.argument<String>("expectedHash")!!
        )
        var publicUri: String? = null
        if (transfer.success()) {
            registerAndPersist(FileMetadata(fileId, name, transfer.bytesReceived(), transfer.calculatedHash(), transfer.finalPath()))
            publicUri = publishToDownloads(destination, name).toString()
        }
        runOnUiThread { result.success(mapOf("success" to transfer.success(), "error" to transfer.error(),
            "finalPath" to if (transfer.success()) "Downloads/Priorize/$name" else transfer.finalPath(),
            "contentUri" to publicUri, "calculatedHash" to transfer.calculatedHash(),
            "bytesReceived" to transfer.bytesReceived())) }
    }

    private fun publishToDownloads(source: File, name: String): Uri {
        val mime = MimeTypeMap.getSingleton().getMimeTypeFromExtension(File(name).extension.lowercase())
            ?: "application/octet-stream"
        val values = ContentValues().apply {
            put(MediaStore.Downloads.DISPLAY_NAME, name)
            put(MediaStore.Downloads.MIME_TYPE, mime)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                put(MediaStore.Downloads.RELATIVE_PATH, "${Environment.DIRECTORY_DOWNLOADS}/Priorize")
                put(MediaStore.Downloads.IS_PENDING, 1)
            }
        }
        val collection = MediaStore.Downloads.getContentUri(MediaStore.VOLUME_EXTERNAL_PRIMARY)
        val uri = requireNotNull(contentResolver.insert(collection, values)) { "Não foi possível criar o arquivo em Downloads" }
        try {
            contentResolver.openOutputStream(uri).use { output ->
                requireNotNull(output) { "Não foi possível abrir Downloads" }
                source.inputStream().use { input -> input.copyTo(output, 8192) }
            }
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                contentResolver.update(uri, ContentValues().apply { put(MediaStore.Downloads.IS_PENDING, 0) }, null, null)
            }
            return uri
        } catch (error: Exception) {
            contentResolver.delete(uri, null, null)
            throw error
        }
    }

    private fun openDownloadedFile(call: MethodCall, result: MethodChannel.Result) {
        try {
            val uri = Uri.parse(call.argument<String>("contentUri")!!)
            val mime = contentResolver.getType(uri) ?: "*/*"
            startActivity(Intent(Intent.ACTION_VIEW).apply {
                setDataAndType(uri, mime)
                addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            })
            result.success(true)
        } catch (error: Exception) { result.error("OPEN_ERROR", "Nenhum aplicativo disponível para abrir o arquivo", null) }
    }

    private fun startPeerForegroundService() {
        val intent = Intent(this, PeerForegroundService::class.java)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) startForegroundService(intent) else startService(intent)
    }

    private fun stopPeerForegroundService() {
        startService(Intent(this, PeerForegroundService::class.java).apply { action = PeerForegroundService.ACTION_STOP })
    }

    private fun localIpv4(): String {
        return NetworkInterface.getNetworkInterfaces().toList().flatMap { it.inetAddresses.toList() }
            .firstOrNull { !it.isLoopbackAddress && it is Inet4Address && it.isSiteLocalAddress }?.hostAddress ?: "127.0.0.1"
    }

    private fun registerAndPersist(metadata: FileMetadata) {
        catalog.register(metadata)
        val json = JSONObject()
            .put("fileId", metadata.fileId()).put("fileName", metadata.fileName())
            .put("fileSize", metadata.fileSize()).put("sha256", metadata.sha256())
            .put("localPath", metadata.localPath())
        getSharedPreferences("p2p_catalog", Context.MODE_PRIVATE).edit()
            .putString("file_${metadata.fileId()}", json.toString()).apply()
    }

    private fun restoreFileCatalog() {
        val preferences = getSharedPreferences("p2p_catalog", Context.MODE_PRIVATE)
        preferences.all.forEach { (key, value) ->
            if (!key.startsWith("file_") || value !is String) return@forEach
            try {
                val json = JSONObject(value)
                val metadata = FileMetadata(json.getString("fileId"), json.getString("fileName"),
                    json.getLong("fileSize"), json.getString("sha256"), json.getString("localPath"))
                catalog.register(metadata)
            } catch (_: Exception) {
                preferences.edit().remove(key).apply()
            }
        }
    }

    override fun onDestroy() { background.shutdownNow(); super.onDestroy() }
}
