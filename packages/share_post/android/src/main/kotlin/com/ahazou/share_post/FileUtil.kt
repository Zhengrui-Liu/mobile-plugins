package com.ahazou.share_post

import android.content.Context
import android.net.Uri
import androidx.core.content.FileProvider
import android.webkit.MimeTypeMap
import android.provider.MediaStore
import android.util.Base64
import androidx.loader.content.CursorLoader
import java.io.File
import java.io.FileOutputStream
import java.io.IOException


class FileUtil(context: Context, url: String) {

    private var authorities: String? = null
    private var context: Context? = context
    private var url: String? = url
    private var type: String? = null
    private var uri: Uri? = null

    init {
        this.uri = Uri.parse(this.url)
        authorities = context.packageName + ".provider"
    }

    private fun getMimeType(url: String): String? {
        var type: String? = null
        val extension = MimeTypeMap.getFileExtensionFromUrl(url)
        if (extension != null) {
            type = MimeTypeMap.getSingleton().getMimeTypeFromExtension(extension)
        }
        return type
    }

    fun isFile(): Boolean {
        return isBase64File() || isLocalFile()
    }

    private fun isBase64File(): Boolean {
        val scheme = uri?.scheme
        if (scheme != null && uri?.scheme == "data") {
            type = uri?.schemeSpecificPart!!.substring(0, uri?.schemeSpecificPart!!.indexOf(";"))
            return true
        }
        return false
    }

    private fun isLocalFile(): Boolean {
        val scheme = uri?.scheme
        if (scheme != null && (uri?.scheme == "content" || uri?.scheme == "file")) {
            if (type != null) {
                return true
            }
            type = getMimeType(uri.toString())
            if (type == null) {
                val realPath = getRealPath(uri!!)
                if (realPath == null) {
                    return false
                } else {
                    type = getMimeType(realPath)
                }
                if (type == null) {
                    type = "*/*"
                }
            }
            return true
        }
        return false
    }

    fun getType(): String {
        return type ?: "*/*"
    }

    private fun getRealPath(uri: Uri): String? {
        val projection = arrayOf(MediaStore.Images.Media.DATA)
        val loader = CursorLoader(context!!, uri, projection, null, null, null)
        val cursor = loader.loadInBackground()
        var result: String? = null
        if (cursor != null && cursor.moveToFirst()) {
            val colIndex = cursor.getColumnIndexOrThrow(MediaStore.Images.Media.DATA)
            result = cursor.getString(colIndex)
            cursor!!.close()
        }
        return result
    }

    fun getUri(): Uri? {
        val mime = MimeTypeMap.getSingleton()
        val extension = mime.getExtensionFromMimeType(getType())

        if (isBase64File()) {
            val tempPath = context?.cacheDir!!.path
            val prefix = "" + System.currentTimeMillis() / 1000
            val encodedFile = uri?.schemeSpecificPart!!
                    .substring(uri?.schemeSpecificPart!!.indexOf(";base64,") + 8)
            try {
                val tempFile = File(tempPath, "$prefix.$extension")
                val stream = FileOutputStream(tempFile)
                stream.write(Base64.decode(encodedFile, Base64.DEFAULT))
                stream.flush()
                stream.close()
                return FileProvider.getUriForFile(context!!, authorities!!, tempFile)
            } catch (e: IOException) {
                e.printStackTrace()
            }

        } else if (isLocalFile()) {
            val uri = Uri.parse(this.url)
            return FileProvider.getUriForFile(context!!, authorities!!, File(uri.path))
        }
        return null
    }
}