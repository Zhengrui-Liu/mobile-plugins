package com.ahazou.photo_editor_sdk

import android.app.Activity
import androidx.annotation.NonNull
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import ly.img.android.pesdk.PhotoEditorSettingsList
import ly.img.android.pesdk.backend.model.state.SaveSettings
import ly.img.android.pesdk.backend.model.constant.Directory.DCIM
import ly.img.android.pesdk.assets.sticker.shapes.StickerPackShapes
import ly.img.android.pesdk.assets.sticker.emoticons.StickerPackEmoticons
import ly.img.android.pesdk.ui.model.state.UiConfigSticker
import ly.img.android.pesdk.assets.overlay.basic.OverlayPackBasic
import ly.img.android.pesdk.ui.model.state.UiConfigOverlay
import ly.img.android.pesdk.assets.frame.basic.FramePackBasic
import ly.img.android.pesdk.ui.model.state.UiConfigFrame
import ly.img.android.pesdk.assets.font.basic.FontPackBasic
import ly.img.android.pesdk.ui.model.state.UiConfigText
import ly.img.android.pesdk.assets.filter.basic.FilterPackBasic
import ly.img.android.pesdk.ui.model.state.UiConfigFilter
import android.net.Uri
import com.orhanobut.hawk.Hawk
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import ly.img.android.pesdk.backend.decoder.ImageSource
import ly.img.android.pesdk.backend.model.config.ImageStickerAsset
import ly.img.android.pesdk.backend.model.state.LoadSettings
import ly.img.android.pesdk.ui.activity.PhotoEditorBuilder
import ly.img.android.pesdk.ui.panels.item.ImageStickerItem
import ly.img.android.pesdk.ui.panels.item.StickerCategoryItem
import java.util.ArrayList

/** PhotoEditorSdkPlugin */
class PhotoEditorSdkPlugin: ActivityAware, FlutterPlugin, MethodCallHandler {

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
    Hawk.init(activity).build()
  }

  override fun onDetachedFromActivityForConfigChanges() {
  }

  override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
    when ( call.method ) {
      "getPlatformVersion" -> result.success("Android ${android.os.Build.VERSION.RELEASE}")
      "addAllContents" -> {
        val args = call.arguments as Map<*, *>
        Hawk.put("logos", args["logos"])
        Hawk.put("stickers", args["stickers"])
      }
      "editImage" -> {
        val args = call.arguments as? String
        val uri = Uri.parse(args)
        openEditor(uri)
      }
      else -> result.notImplemented()
    }
  }

  override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
  }

  private fun createPesdkSettingsList() =
          PhotoEditorSettingsList()
                  .configure<UiConfigFilter> {
                    it.setFilterList(FilterPackBasic.getFilterPack())
                  }
                  .configure<UiConfigText> {
                    it.setFontList(FontPackBasic.getFontPack())
                  }
                  .configure<UiConfigFrame> {
                    it.setFrameList(FramePackBasic.getFramePack())
                  }
                  .configure<UiConfigOverlay> {
                    it.setOverlayList(OverlayPackBasic.getOverlayPack())
                  }
                  .configure<UiConfigSticker> {
                    it.setStickerLists(
                            StickerPackEmoticons.getStickerCategory(),
                            StickerPackShapes.getStickerCategory(),
                            StickerCategoryItem(
                              "hue", "", ImageSource.create(R.drawable.imgly_sticker_emoticons_alien),
                                    ImageStickerItem("imgly_sticker_emoticons_grin", ly.img.android.pesdk.assets.sticker.emoticons.R.string.imgly_sticker_name_emoticons_grin, ImageSource.create(ly.img.android.pesdk.assets.sticker.emoticons.R.drawable.imgly_sticker_emoticons_grin))
                            )
                    )
                  }
                  .configure<SaveSettings> {
                    // Set custom editor image export settings
                    it.setExportDir(DCIM, "SomeFolderName")
                    it.setExportPrefix("result_")
                    it.savePolicy = SaveSettings.SavePolicy.RETURN_ALWAYS_ONLY_OUTPUT
                  }


  var PESDK_RESULT = 1

  private fun openEditor(inputImage: Uri?) {
    val a = Hawk.get<ArrayList<String>>("logos")

    val settingsList = createPesdkSettingsList()

    settingsList.configure<LoadSettings> {
      it.source = inputImage
    }

    settingsList[LoadSettings::class].source = inputImage

    PhotoEditorBuilder(activity)
            .setSettingsList(settingsList)
            .startActivityForResult(activity, PESDK_RESULT)
  }

}
