package com.ahazou.share_post

import android.graphics.drawable.Drawable
import com.squareup.picasso.Target
import java.lang.Exception

abstract class TargetPhoneGallery: Target {

    override fun onPrepareLoad(placeHolderDrawable: Drawable?) {
    }

    override fun onBitmapFailed(e: Exception?, errorDrawable: Drawable?) {
    }
}