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
import androidx.core.content.ContextCompat.startActivity
import android.content.Intent
import android.content.ActivityNotFoundException
import android.content.Context
import android.graphics.Bitmap
import android.net.Uri
import android.os.Environment
import android.provider.MediaStore
import android.text.TextUtils
import androidx.core.content.FileProvider
import com.facebook.appevents.ml.Utils
import com.squareup.picasso.Picasso
import java.io.ByteArrayOutputStream
import java.io.File
import java.io.FileOutputStream
import java.lang.Exception
import java.util.ArrayList


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
        val url = args["url"] as String
        val message = args["message"] as String
        val accessToken = args["accessToken"]
        val time = args["time"]
        val facebookId = args["facebookId"] as String

        if( accessToken == null ) {
          shareOnFacebookProfile(url, result)
        } else {
          accessToken as String
          shareOnFacebookPage(url, message, accessToken, time, facebookId, result)
        }
      }
      "shareStoryOnInstagram" -> {
        val args = call.arguments as Map<*, *>
        val url = args["url"] as String
        val message = args["message"] as String
        shareStoryOnInstagram(url, message, result)
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
      else -> result.notImplemented()
    }
  }

  private fun getFacebookUser(result: Result) {
    if( isInstalled("com.facebook.katana") ) {
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
    } else {
      result.error("APP_NOT_FOUND",  "Facebook app not found", null)
    }
  }

  private fun getFacebookUserPages(result: Result) {
    if( isInstalled("com.facebook.katana") ) {

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
    } else {
      result.error("APP_NOT_FOUND",  "Facebook app not found", null)
    }
  }

  private fun shareOnFacebookPage(url: String, message: String, accessToken: String, time: Any?,
                                  facebookId: String, result: Result) {
    val parameters = Bundle()
    parameters.putString("url", url)
    parameters.putString("message", message)
    parameters.putString("access_token", accessToken)
    if( time != null ) {
      time as Long
      parameters.putLong("scheduled_publish_time", time)
      parameters.putBoolean("published", false)
    }
    val graphPath = "$facebookId/photos"
    val gr = GraphRequest(
            AccessToken.getCurrentAccessToken(),
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

  private fun shareOnFacebookProfile(urlImage: String, result: Result) {
    val url = URL(urlImage)

    Thread {
      val image = BitmapFactory.decodeStream(url.openConnection().getInputStream())

      activity.runOnUiThread {
        val photo = SharePhoto.Builder().setBitmap(image).build()
        val content = SharePhotoContent.Builder().addPhoto(photo).build()
        val shareDialog = ShareDialog(activity)

        if (ShareDialog.canShow(SharePhotoContent::class.java)) {
          shareDialog.show(content)
        } else result.error("APP_NOT_FOUND", "Facebook app not found", null)
      }
    }.start()
  }

  private fun shareStoryOnInstagram(url: String, msg: String, result: Result) {
    if( isInstalled("com.instagram.android") ) {

    } else {
      result.error("APP_NOT_FOUND",  "Instagram app not found", null)
    }

  }

  private fun sharePostOnInstagram(url: String, msg: String, result: Result) {
    if( isInstalled("com.instagram.android") ) {
      val fileHelper = FileUtil(activity, url)

      val feedIntent = Intent(Intent.ACTION_SEND)
      feedIntent.type = "image/*"
      feedIntent.putExtra(Intent.EXTRA_TEXT, msg)
      feedIntent.putExtra(Intent.EXTRA_STREAM, fileHelper.getUri())
      feedIntent.setPackage("com.instagram.android")

      val storiesIntent = Intent("com.instagram.share.ADD_TO_STORY")
      storiesIntent.setDataAndType(fileHelper.getUri(),  "jpg")
      storiesIntent.addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
      storiesIntent.setPackage("com.instagram.android")
      // activity.grantUriPermission("com.instagram.android", fileHelper.getUri(), Intent.FLAG_GRANT_READ_URI_PERMISSION)

      val chooserIntent = Intent.createChooser(feedIntent, "Compartilhar no Instagram")
      val intents = ArrayList<Intent>()
      intents.add(storiesIntent)
      chooserIntent.putExtra(Intent.EXTRA_INITIAL_INTENTS, intents)
      activity.startActivity(chooserIntent)
    } else {
      result.error("APP_NOT_FOUND",  "Instagram app not found", null)
    }
  }

  private fun shareOnWhatsApp(url: String, msg: String, result: Result, shareToWhatsAppBiz: Boolean) {
    val app = if (shareToWhatsAppBiz) "com.whatsapp.w4b" else "com.whatsapp"
    if( isInstalled(app) ) {
      try {
        val whatsappIntent = Intent(Intent.ACTION_SEND)
        whatsappIntent.type = "text/plain"
        whatsappIntent.setPackage(app)
        whatsappIntent.putExtra(Intent.EXTRA_TEXT, msg)
        if (!TextUtils.isEmpty(url)) {
          val fileHelper = FileUtil(activity, url)
          if (fileHelper.isFile()) {
            whatsappIntent.addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            whatsappIntent.putExtra(Intent.EXTRA_STREAM, fileHelper.getUri())
            whatsappIntent.type = fileHelper.getType()
          }
        }
        whatsappIntent.addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
        activity.startActivity(whatsappIntent)
        result.success("POST_SENT")
      } catch (e: Exception) {

      }
    } else {
      result.error("APP_NOT_FOUND",  "App not found", null)
    }
  }

  private fun shareOnNative(url: String, msg: String, result: Result) {
    try {
      val intent = Intent(Intent.ACTION_SEND)
      intent.putExtra(Intent.EXTRA_TEXT, msg)

      Picasso.get()
              .load(url)
              .into(object: TargetPhoneGallery(){
                override fun onBitmapLoaded(bitmap: Bitmap?, from: Picasso.LoadedFrom?) {
                  val bitmapUri = getImageUri(bitmap)
                  intent.addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                  intent.putExtra(Intent.EXTRA_STREAM, bitmapUri)
                  val cr = activity.contentResolver
                  intent.type = cr.getType(bitmapUri)
                  activity.startActivity(Intent.createChooser(intent, "Enviar post..."))
                  result.success("POST_SENT")
                }
              })

    } catch (e: Exception) {
      result.error("ERROR_TO_POSTING", "Error to posting", null)
    }
  }

  fun getImageUri(inImage: Bitmap?): Uri {
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
