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
import com.orhanobut.hawk.Hawk
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import ly.img.android.pesdk.backend.decoder.ImageSource
import ly.img.android.pesdk.backend.model.config.ImageStickerAsset
import ly.img.android.pesdk.backend.model.state.AssetConfig
import ly.img.android.pesdk.backend.model.state.LayerListSettings
import ly.img.android.pesdk.backend.model.state.LoadSettings
import ly.img.android.pesdk.backend.model.state.layer.ImageStickerLayerSettings
import ly.img.android.pesdk.backend.model.state.layer.SpriteLayerSettings
import ly.img.android.pesdk.ui.activity.PhotoEditorBuilder
import ly.img.android.pesdk.ui.model.state.*
import ly.img.android.pesdk.ui.panels.item.ImageStickerItem
import ly.img.android.pesdk.ui.panels.item.StickerCategoryItem
import ly.img.android.pesdk.ui.panels.item.StickerColorOption
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
    Hawk.init(activity).build()
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
        Hawk.put("logos", args["logos"])
        Hawk.put("stickers", args["stickers"])

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
//                  .configure<UiConfigFilter> {
//                    it.setFilterList(FilterPackBasic.getFilterPack())
//                  }
                  .configure<UiConfigText> {
                    it.setFontList(FontPackBasic.getFontPack())
                  }


//                  .configure<UiConfigFrame> {
//                    it.setFrameList(FramePackBasic.getFramePack())
//                  }
//                  .configure<UiConfigOverlay> {
//                    it.setOverlayList(OverlayPackBasic.getOverlayPack())
//                  }
//                  .configure<UiConfigSticker> {
//                    it.setStickerLists(
//                            StickerCategoryItem(
//                                    "hue", "", ImageSource.create(R.drawable.imgly_sticker_emoticons_alien),
//                                    ImageStickerItem(
//                                            "imgly_sticker_emoticons_grin",
//                                            ly.img.android.pesdk.assets.sticker.emoticons.R.string.imgly_sticker_name_emoticons_grin,
//                                            ImageSource.create(ly.img.android.pesdk.assets.sticker.emoticons.R.drawable.imgly_sticker_emoticons_grin)
//                                    )
//                            )
//                    )
//                  }
//                  .configure<SaveSettings> {
//                    // Set custom editor image export settings
//                    it.setExportDir(DCIM, "SomeFolderName")
//                    it.setExportPrefix("result_")
//                    it.savePolicy = SaveSettings.SavePolicy.RETURN_ALWAYS_ONLY_OUTPUT
//                  }


  var PESDK_RESULT = 1

  private fun openEditor(inputImage: Uri?) {
    val a = Hawk.get<ArrayList<String>>("logos")

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
                      "hue1",
                      "logos",
                      ImageSource.create(
                              Uri.parse("https://encrypted-tbn0.gstatic.com/images?q=tbn%3AAN" +
                                      "d9GcQN5h7AhxdwNgR1hanAFyV4VA87ujSDaGpJymSwLQHJEMl573l6")),
                      arrayListSticker
              )
      )
//
//                      /*ImageStickerItem(
//                              "hue11", "imgly_sticker_emoticons_grin",
//                              ImageSource.create(Uri.parse("https://encrypted-tbn0.gstatic.com/images?q=tbn%3AANd9GcQN5h7AhxdwNgR1hanAFyV4VA87ujSDaGpJymSwLQHJEMl573l6")))*//*
//              )*//*,
//              StickerCategoryItem(
//                      "hue2",
//                      "adesivos",
//                      ImageSource.create(
//                              Uri.parse("https://encrypted-tbn0.gstatic.com/images?q=tbn%3AAN" +
//                                      "d9GcQN5h7AhxdwNgR1hanAFyV4VA87ujSDaGpJymSwLQHJEMl573l6"))*//*,
//                      ImageStickerItem.createFromAsset(imageStickerAsset)*//*
//              )*/
//      )
    }


//
//  //
//  //              StickerCategoryItem(
//  //                      "hue1",
//  //                      "hue1",
//  //                      ImageSource.create(Uri.parse("https://encrypted-tbn0.gstatic.com/images?q=tbn%3AANd9GcQN5h7AhxdwNgR1hanAFyV4VA87ujSDaGpJymSwLQHJEMl573l6")),
//                        ImageStickerItem(
//                                "hue11", "https://encrypted-tbn0.gstatic.com/images?q=tbn%3AANd9GcQN5h7AhxdwNgR1hanAFyV4VA87ujSDaGpJymSwLQHJEMl573l6",
//                                ImageSource.create(Uri.parse("https://encrypted-tbn0.gstatic.com/images?q=tbn%3AANd9GcQN5h7AhxdwNgR1hanAFyV4VA87ujSDaGpJymSwLQHJEMl573l6"))
//  //
//  //                      )
//  //              )
//
//                /*,
//
//                StickerCategoryItem(
//                        "hue2", "", ImageSource.create(R.drawable.imgly_sticker_emoticons_alien),
//                        ImageStickerItem(
//                                "imgly_sticker_emoticons_grin",
//                                ly.img.android.pesdk.assets.sticker.emoticons.R.string.imgly_sticker_name_emoticons_grin,
//                                ImageSource.create(ly.img.android.pesdk.assets.sticker.emoticons.R.drawable.imgly_sticker_emoticons_grin)
//                        )
//                )*/
//
//      }

//    }.start()

    PhotoEditorBuilder(activity)
            .setSettingsList(settingsList)
            .startActivityForResult(activity, PESDK_RESULT)
  }

}