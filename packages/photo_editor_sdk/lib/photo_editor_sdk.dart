import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';

class PhotoEditorSdk {
  static const MethodChannel _channel =
      const MethodChannel('photo_editor_sdk');

  static Future addAllContents({List<String> logos, List<String> stickers}) async {
    return await _channel.invokeMethod('addAllContents', <String, List<String>> {
      'logos' : logos, 'stickers' : stickers
    });
  }

  static Future editImage(String url) async {
    return await _channel.invokeMethod('editImage', url);
  }
}
