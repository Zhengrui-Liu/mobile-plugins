import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';

class PhotoEditorSdk {
  static const MethodChannel _channel =
      const MethodChannel('photo_editor_sdk');

  static Future editImage(File file) async {
    return await _channel.invokeMethod('editImage', file.readAsBytesSync());
  }
}
