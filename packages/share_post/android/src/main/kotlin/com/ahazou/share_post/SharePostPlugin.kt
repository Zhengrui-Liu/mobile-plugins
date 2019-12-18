package com.ahazou.share_post

import android.app.Activity
import android.net.Uri
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


/** SharePostPlugin */
class SharePostPlugin : ActivityAware, FlutterPlugin, MethodCallHandler {

  private lateinit var activity: Activity

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
      "facebookShare" -> facebookShare(caption = call.argument<String>("caption")!!,
              mediaPath = call.argument<String>("mediaPath")!!)
      else -> result.notImplemented()
    }
  }

  private fun facebookShare(caption: String, mediaPath: String) {
    val media = File(mediaPath)
    val uri = Uri.fromFile(media)
    val photo = SharePhoto.Builder().setImageUrl(uri).setCaption(caption).build()
    val content = SharePhotoContent.Builder().addPhoto(photo).build()
    val shareDialog = ShareDialog(activity)

    if (ShareDialog.canShow(SharePhotoContent::class.java)) {
      shareDialog.show(content)
    }
  }

}
