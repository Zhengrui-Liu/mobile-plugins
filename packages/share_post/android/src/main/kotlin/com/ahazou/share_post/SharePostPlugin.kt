package com.ahazou.share_post

import android.app.Activity
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
      "getFacebookUser" -> result.notImplemented()
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
      "shareStoryOnInstagram" -> result.notImplemented()
      "sharePostOnInstagram" -> result.notImplemented()
      "shareOnWhatsapp" -> result.notImplemented()
      "shareOnWhatsappBusiness" -> result.notImplemented()
      "openAppOnStore" -> result.notImplemented()
      "shareOnNative" -> result.notImplemented()
      else -> result.notImplemented()
    }
  }

  private fun getFacebookUserPages(result: Result) {
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
        } else result.error("FACEBOOK_APP_NOT_INSTALLED", "Facebook not installed", null)
      }
    }.start()
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
      val a = ""
    }
    gr.version = "v5.0"
    gr.executeAsync()
  }

  private fun isLoggedInWithFacebook(): Boolean {
    val accessToken = AccessToken.getCurrentAccessToken()
    return accessToken != null
  }


}
