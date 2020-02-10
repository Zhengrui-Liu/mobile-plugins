package com.ahazou.photo_editor_sdk

import android.app.Activity
import androidx.annotation.NonNull
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import ly.img.android.pesdk.PhotoEditorSettingsList
import ly.img.android.pesdk.assets.font.basic.FontPackBasic
import android.net.Uri
import com.bumptech.glide.Glide
import com.bumptech.glide.load.DataSource
import com.bumptech.glide.load.engine.GlideException
import com.bumptech.glide.request.RequestListener
import com.bumptech.glide.request.target.Target
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import ly.img.android.pesdk.backend.decoder.ImageSource
import ly.img.android.pesdk.backend.model.config.ImageStickerAsset
import ly.img.android.pesdk.backend.model.constant.Directory.DCIM
import ly.img.android.pesdk.backend.model.state.LoadSettings
import ly.img.android.pesdk.backend.model.state.SaveSettings
import ly.img.android.pesdk.ui.activity.PhotoEditorBuilder
import ly.img.android.pesdk.ui.model.state.*
import ly.img.android.pesdk.ui.panels.item.ImageStickerItem
import ly.img.android.pesdk.ui.panels.item.StickerCategoryItem
import ly.img.android.pesdk.ui.panels.item.ToolItem
import java.io.File
import java.util.ArrayList

/** PhotoEditorSdkPlugin */
class PhotoEditorSdkPlugin: ActivityAware, FlutterPlugin, MethodCallHandler {

  val arrayListSticker = ArrayList<ImageStickerItem>()

  companion object {
    lateinit var activity: Activity
  }

  override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    val channel = MethodChannel(flutterPluginBinding.binaryMessenger, "photo_editor_sdk")
    channel.setMethodCallHandler(PhotoEditorSdkPlugin())
  }

  override fun onDetachedFromActivity() {
  }

  override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
  }

  override fun onAttachedToActivity(binding: ActivityPluginBinding) {
    activity = binding.activity
  }

  override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
  }

  override fun onDetachedFromActivityForConfigChanges() {
  }

  override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
    when ( call.method ) {
      "getPlatformVersion" -> result.success("Android ${android.os.Build.VERSION.RELEASE}")
      "addAllContents" -> {
        val args = call.arguments as Map<*, *>
        val list: ArrayList<*> = args["logos"] as ArrayList<*>

        list.forEach {
          Glide
                  .with(activity)
                  .asFile()
                  .load(it)
                  .listener(object : RequestListener<File> {
                    override fun onLoadFailed(e: GlideException?, model: Any?,
                                              target: Target<File>?, isFirstResource: Boolean): Boolean {
                      return false
                    }

                    override fun onResourceReady(resource: File?, model: Any?, target: Target<File>?,
                                                 dataSource: DataSource?, isFirstResource: Boolean): Boolean {
                      val imageStickerConfig = ImageStickerItem.createFromAsset(ImageStickerAsset.createTemporaryStickerAsset(Uri.fromFile(resource)))
                      arrayListSticker.add(imageStickerConfig)
                      return false
                    }
                  })
                  .submit()
        }
      }
      "editImage" -> {
        val args = call.arguments as? String
        val uri = Uri.parse(args)
        openEditor(uri)
      }
      else -> result.notImplemented()
    }
  }

  private fun createPesdkSettingsList() =
          PhotoEditorSettingsList()
                  .configure<UiConfigText> {
                    it.setFontList(FontPackBasic.getFontPack())
                  }
                  .configure<SaveSettings> {
                    // Set custom editor image export settings
                    it.setExportDir(DCIM, "SomeFolderName")
                    it.setExportPrefix("result_")
                    it.savePolicy = SaveSettings.SavePolicy.RETURN_ALWAYS_ONLY_OUTPUT
                  }

  var PESDK_RESULT = 1

  private fun openEditor(inputImage: Uri?) {
    val settingsList = createPesdkSettingsList()
    settingsList.configure<LoadSettings> {
      it.source = inputImage
      it.isDeleteProtectedSource = true
    }
    settingsList.configure<UiConfigTheme> {
      it.theme =  R.style.Imgly_Theme_TopActionBar_NoFullscreen
    }
    settingsList.configure<UiConfigMainMenu> {
      it.setToolList(
              ToolItem("imgly_tool_sticker_selection", R.string.pesdk_sticker_title_name, ImageSource.create(R.drawable.imgly_icon_tool_sticker)),
              ToolItem("imgly_tool_text", R.string.pesdk_text_title_name, ImageSource.create(R.drawable.imgly_icon_tool_text))
      )
    }
    settingsList.configure<UiConfigSticker> {
      it.setStickerLists(
              StickerCategoryItem(
                      "logos_id",
                      "logos",
                      ImageSource.create(
                              Uri.parse("https://encrypted-tbn0.gstatic.com/images?q=tbn%3AAN" +
                                      "d9GcQN5h7AhxdwNgR1hanAFyV4VA87ujSDaGpJymSwLQHJEMl573l6")),
                      arrayListSticker
              )
      )
    }

    PhotoEditorBuilder(activity)
            .setSettingsList(settingsList)
            .startActivityForResult(activity, PESDK_RESULT)
  }

}