package com.ahazou.share_post

import android.app.Activity
import android.content.pm.PackageManager
import android.graphics.BitmapFactory
import android.os.Bundle
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import com.facebook.share.model.SharePhotoContent
import com.facebook.share.widget.ShareDialog
import com.facebook.share.model.SharePhoto
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import com.facebook.AccessToken
import com.facebook.GraphRequest
import com.facebook.HttpMethod
import com.facebook.Profile
import org.json.JSONArray
import java.net.URL
import android.content.Intent
import android.content.ActivityNotFoundException
import android.graphics.Bitmap
import android.net.Uri
import androidx.core.content.FileProvider
import com.facebook.internal.FacebookDialogBase
import com.facebook.share.Sharer
import com.facebook.share.model.ShareContent
import com.facebook.share.model.ShareLinkContent
import java.io.ByteArrayOutputStream
import java.io.File
import java.io.FileOutputStream
import java.lang.Exception


/** SharePostPlugin */
class SharePostPlugin: ActivityAware, FlutterPlugin, MethodCallHandler {

  companion object {
    lateinit var activity: Activity
  }

  override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    val channel = MethodChannel(binding.binaryMessenger, "share_post")
    channel.setMethodCallHandler(SharePostPlugin())
  }

  override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
  }

  override fun onDetachedFromActivity() {
  }

  override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
  }

  override fun onAttachedToActivity(binding: ActivityPluginBinding) {
    activity = binding.activity
  }

  override fun onDetachedFromActivityForConfigChanges() {
  }

  override fun onMethodCall(call: MethodCall, result: Result) {
    when ( call.method ) {
      "getPlatformVersion" -> result.success("Android ${android.os.Build.VERSION.RELEASE}")
      "getFacebookUser" -> getFacebookUser(result)
      "getFacebookUserPages" -> getFacebookUserPages(result)
      "shareOnFacebook" -> {
        val args = call.arguments as Map<*, *>
        val url: String? = args["url"] as? String?
        val message = args["message"] as String
        val accessToken = args["accessToken"]
        val time: Long? = if ( args["time"] == null ) null else (args["time"] as? Int)!!.toLong()
        val facebookId = args["facebookId"] as String

        if( accessToken == null ) {
          shareOnFacebookProfile(url, message, result)
        } else {
          accessToken as String
          shareOnFacebookPage(url, message, accessToken, time, facebookId, result)
        }
      }
      "shareStoryOnInstagram" -> {
        val args = call.arguments as Map<*, *>
        val url = args["url"] as String
        shareStoryOnInstagram(url, result)
      }
      "sharePostOnInstagram" -> {
        val args = call.arguments as Map<*, *>
        val url = args["url"] as String
        val message = args["message"] as String
        sharePostOnInstagram(url, message, result)
      }
      "shareOnWhatsapp" -> {
        val args = call.arguments as Map<*, *>
        val url = args["url"] as String
        val message = args["message"] as String
        shareOnWhatsApp(url, message, result, false)
      }
      "shareOnWhatsappBusiness" -> {
        val args = call.arguments as Map<*, *>
        val url = args["url"] as String
        val message = args["message"] as String
        shareOnWhatsApp(url, message, result, true)
      }
      "openAppOnStore" -> {
        val args = call.arguments as Map<*, *>
        val appUrl = args["appUrl"] as String
        openAppOnStore(appUrl)
      }
      "shareOnNative" -> {
        val args = call.arguments as Map<*, *>
        val url = args["url"] as String
        val message = args["message"] as String
        shareOnNative(url, message, result)
      }
      "checkPermissionToPublish" -> checkPermissionToPublish(result)
      else -> result.notImplemented()
    }
  }

  private fun getFacebookUser(result: Result) {
    if( AccessToken.getCurrentAccessToken() != null ) {
      val parameters = Bundle()
      parameters.putString("fields", "id,name")
      GraphRequest(
              AccessToken.getCurrentAccessToken(),
              "/me",
              parameters,
              HttpMethod.GET
      ) { response ->
        val obj = response.jsonObject
        val map = HashMap<String, String>()
        map["id"] = obj.getString("id")
        map["name"] = obj.getString("name")
        result.success(map)
      }.executeAsync()
    }
  }

  private fun getFacebookUserPages(result: Result) {
    if( AccessToken.getCurrentAccessToken() != null ) {
      val profile = Profile.getCurrentProfile()
      val parameters = Bundle()
      parameters.putString("fields", "id,name,access_token")
      GraphRequest(
              AccessToken.getCurrentAccessToken(),
              "/" + profile.id + "/accounts",
              parameters,
              HttpMethod.GET
      ) { response ->
        val arr = response.jsonObject.get("data") as JSONArray
        val list = List(arr.length()) {
          val map = HashMap<String, String>()
          val obj = arr.getJSONObject(it)
          map["id"] = obj.getString("id")
          map["name"] = obj.getString("name")
          map["access_token"] = obj.getString("access_token")
          map
        }
        result.success(list)
      }.executeAsync()
    }
  }

  private fun shareOnFacebookPage(url: String?, message: String, accessToken: String, time: Long?,
                                  facebookId: String, result: Result) {
    val parameters = Bundle()
    if( url != null ) {
      parameters.putString("url", url)
    }
    parameters.putString("message", message)
    parameters.putString("access_token", accessToken)
    if( time != null ) {
      parameters.putLong("scheduled_publish_time", time)
      parameters.putBoolean("published", false)
    }

    val partPath = if( url != null ) "photos" else "feed"
    val graphPath = "$facebookId/$partPath"

    val localAccessToken = AccessToken.getCurrentAccessToken()
    val gr = GraphRequest(
            AccessToken(accessToken, localAccessToken.applicationId, localAccessToken.userId,
                    null, null, null, null, null, null, null),
            graphPath,
            parameters,
            HttpMethod.POST
    ) { response ->
      if( response.error == null ) {
        result.success("POST_SENT")
      } else result.error("ERROR_TO_POSTING", "Error to posting", null)
    }
    gr.version = "v5.0"
    gr.executeAsync()
  }

  private fun shareOnFacebookProfile(urlImage: String?, message: String?, result: Result) {
    Thread {
      var image: Bitmap? = null
      if( urlImage != null ) {
        val url = URL(urlImage)
        image = BitmapFactory.decodeStream(url.openConnection().getInputStream())
      }

      activity.runOnUiThread {
        var content = if( image != null ) {
          val photo = SharePhoto.Builder().setBitmap(image).build()
          SharePhotoContent.Builder().addPhoto(photo).build()
        } else {
          ShareLinkContent.Builder().setQuote(message).build()
        }

        val shareDialog = ShareDialog(activity)
        if (ShareDialog.canShow(SharePhotoContent::class.java)) {
          shareDialog.show(content)
        } else result.error("APP_NOT_FOUND", "Facebook app not found", null)
      }
    }.start()
  }

  private fun shareStoryOnInstagram(url: String, result: Result) {
    if( isInstalled("com.instagram.android") ) {
      val urlImage = URL(url)

      Thread {
        val image = BitmapFactory.decodeStream(urlImage.openConnection().getInputStream())

        activity.runOnUiThread {
          val bitmapUri = getImageUri(image)

          val storiesIntent = Intent("com.instagram.share.ADD_TO_STORY")
          storiesIntent.setDataAndType(bitmapUri,  "jpg")
          storiesIntent.addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)

          activity.startActivity(storiesIntent)
          result.success("POST_SENT")
        }
      }.start()
    } else {
      result.error("APP_NOT_FOUND",  "Instagram app not found", null)
    }
  }

  private fun sharePostOnInstagram(url: String, msg: String, result: Result) {
    if( isInstalled("com.instagram.android") ) {
      val urlImage = URL(url)

      Thread {
        val image = BitmapFactory.decodeStream(urlImage.openConnection().getInputStream())

        activity.runOnUiThread {
          val bitmapUri = getImageUri(image)

          val feedIntent = Intent(Intent.ACTION_SEND)
          feedIntent.type = "image/*"
          feedIntent.putExtra(Intent.EXTRA_TEXT, msg)
          feedIntent.putExtra(Intent.EXTRA_STREAM, bitmapUri)
          feedIntent.setPackage("com.instagram.android")

          activity.startActivity(feedIntent)
          result.success("POST_SENT")
        }
      }.start()
    } else {
      result.error("APP_NOT_FOUND",  "Instagram app not found", null)
    }
  }

  private fun shareOnWhatsApp(url: String, msg: String, result: Result, shareToWhatsAppBiz: Boolean) {
    val app = if (shareToWhatsAppBiz) "com.whatsapp.w4b" else "com.whatsapp"
    if( isInstalled(app) ) {
      val whatsappIntent = Intent(Intent.ACTION_SEND)
      whatsappIntent.setPackage(app)
      whatsappIntent.putExtra(Intent.EXTRA_TEXT, msg)

      val urlImage = URL(url)

      Thread {
        val image = BitmapFactory.decodeStream(urlImage.openConnection().getInputStream())

        activity.runOnUiThread {
          val bitmapUri = getImageUri(image)

          whatsappIntent.addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
          whatsappIntent.putExtra(Intent.EXTRA_STREAM, bitmapUri)
          val cr = activity.contentResolver
          whatsappIntent.type = cr.getType(bitmapUri)
          activity.startActivity(whatsappIntent)
          result.success("POST_SENT")
        }
      }.start()
    } else {
      result.error("APP_NOT_FOUND",  "App not found", null)
    }
  }

  private fun shareOnNative(url: String, msg: String, result: Result) {
    try {
      val intent = Intent(Intent.ACTION_SEND)
      intent.putExtra(Intent.EXTRA_TEXT, msg)
      val urlImage = URL(url)

      Thread {
        val image = BitmapFactory.decodeStream(urlImage.openConnection().getInputStream())

        activity.runOnUiThread {
          val bitmapUri = getImageUri(image)

          intent.addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
          intent.putExtra(Intent.EXTRA_STREAM, bitmapUri)
          val cr = activity.contentResolver
          intent.type = cr.getType(bitmapUri)
          activity.startActivity(Intent.createChooser(intent, "Enviar post..."))
          result.success("POST_SENT")
        }
      }.start()
    } catch (e: Exception) {
      result.error("ERROR_TO_POSTING", "Error to posting", null)
    }
  }

  private fun checkPermissionToPublish(result: Result) {
    if( AccessToken.getCurrentAccessToken() != null ) {
      val accessToken = AccessToken.getCurrentAccessToken()
      result.success(accessToken.permissions.contains("publish_pages") &&
              accessToken.permissions.contains("manage_pages"))
      return
    }
    result.success(false)
  }

  private fun getImageUri(inImage: Bitmap?): Uri {
    val tempFile = File.createTempFile("img_sharing", ".jpg", activity.externalCacheDir)
    val bts = ByteArrayOutputStream()
    inImage!!.compress(Bitmap.CompressFormat.JPEG, 100, bts)
    val bitmapData = bts.toByteArray()

    val fos = FileOutputStream(tempFile)
    fos.write(bitmapData)
    fos.flush()
    fos.close()

    return FileProvider.getUriForFile(activity.applicationContext, activity.packageName +".provider", tempFile)
  }

  private fun openAppOnStore(packageName: String) {
    val context = activity.applicationContext
    try {
      val playStoreUri = Uri.parse("market://details?id=$packageName")
      val intent = Intent(Intent.ACTION_VIEW, playStoreUri)
      context.startActivity(intent)
    } catch (e: ActivityNotFoundException) {
      val playStoreUri = Uri.parse("https://play.google.com/store/apps/details?id=$packageName")
      val intent = Intent(Intent.ACTION_VIEW, playStoreUri)
      context.startActivity(intent)
    }
  }

  private fun isInstalled(packageName: String): Boolean {
    val packageManager = activity.packageManager
    return try {
      packageManager.getApplicationInfo(packageName, 0).enabled
    } catch (e: PackageManager.NameNotFoundException) {
      false
    }
  }

}
