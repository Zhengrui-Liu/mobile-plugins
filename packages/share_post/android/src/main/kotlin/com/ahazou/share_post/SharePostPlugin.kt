package com.ahazou.share_post

import android.app.Activity
import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.net.Uri
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
import java.io.File
import com.facebook.share.model.ShareLinkContent
import java.nio.file.Files
import android.provider.MediaStore
import com.facebook.AccessToken
import com.facebook.GraphRequest
import com.facebook.HttpMethod
import com.facebook.Profile
import org.json.JSONException
import org.json.JSONObject
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
      "isLoggedInWithFacebook" -> result.success(isLoggedInWithFacebook())
      "getFacebookUserPages" -> result.success(getFacebookUserPages())
      "shareFacebook" -> shareFacebook(
              urlImage = call.argument<String>("urlImage")!!, result = result)
      else -> result.notImplemented()
    }
  }

  private fun isLoggedInWithFacebook(): Boolean {
    val accessToken = AccessToken.getCurrentAccessToken()
    return accessToken != null
  }

  private fun getFacebookUserPages(): String {
    if (isLoggedInWithFacebook()) {
      val profile = Profile.getCurrentProfile()
      val parameters = Bundle()
      parameters.putString("fields", "id,name")

      GraphRequest(
              AccessToken.getCurrentAccessToken(),
              "/" + profile.id + "/accounts",
              parameters,
              HttpMethod.GET
      ) { response ->

        val a = ""

      }.executeAsync()

    }

    return "true"
  }

  private fun shareFacebook(urlImage: String, result: Result) {
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

}
