import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/services.dart';

class SharePost {
  static const MethodChannel _channel = const MethodChannel('share_post');

  static Future<String> get platformVersion async {
    final String version = await _channel.invokeMethod('getPlatformVersion');
    return version;
  }

  static Future<dynamic> getFacebookUser() async {
    dynamic result;
    try {
      result = await _channel.invokeMethod('getFacebookUser');
    } catch (e) {
      return null;
    }
    return result;
  }

  static Future<List<dynamic>> getFacebookUserPages() async {
    dynamic result;
    try {
      result = await _channel.invokeMethod('getFacebookUserPages');
    } catch (e) {
      return List();
    }
    return result;
  }

  static Future<String> shareOnFacebookPage(String url) async {
    final Map<String, Object> arguments = Map<String, dynamic>();
    arguments.putIfAbsent('url', () => url);
    dynamic result;
    try {
      result = await _channel.invokeMethod('shareOnFacebookPage', arguments);
    } catch (e) {
      return "false";
    }
    return result;
  }

  static Future<String> shareOnFacebookProfile(String url) async {
    final Map<String, Object> arguments = Map<String, dynamic>();
    arguments.putIfAbsent('url', () => url);
    dynamic result;
    try {
      result = await _channel.invokeMethod('shareOnFacebookProfile', arguments);
    } catch (e) {
      return "false";
    }
    return result;
  }
}
