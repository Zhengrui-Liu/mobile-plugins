import 'dart:async';

import 'package:flutter/services.dart';

class SharePost {
  static const MethodChannel _channel =
      const MethodChannel('share_post');

  static Future<String> get platformVersion async {
    final String version = await _channel.invokeMethod('getPlatformVersion');
    return version;
  }
}
