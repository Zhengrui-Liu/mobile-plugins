import 'dart:async';

import 'package:flutter/services.dart';

class SharePost {
  static const MethodChannel _channel = const MethodChannel('share_post');

  static Future<String> get platformVersion async {
    final String version = await _channel.invokeMethod('getPlatformVersion');
    return version;
  }

  static Future<Map<dynamic, dynamic>> getFacebookUser() async {
    Map<dynamic, dynamic> result;
    try {
      result = await _channel.invokeMethod('getFacebookUser');
    } catch (e) {
      return null;
    }
    return result;
  }

  static Future<List<dynamic>> getFacebookUserPages() async {
    List<dynamic> result;
    try {
      result = await _channel.invokeMethod('getFacebookUserPages');
    } catch (e) {
      return null;
    }
    return result;
  }

  static Future<String> shareOnFacebook(String url, String message,
      String accessToken, int time, String facebookId) async {
    final Map<String, Object> arguments = Map<String, dynamic>();
    arguments.putIfAbsent('url', () => url);
    arguments.putIfAbsent('message', () => message);
    arguments.putIfAbsent('accessToken', () => accessToken);
    arguments.putIfAbsent('time', () => time);
    arguments.putIfAbsent('facebookId', () => facebookId);
    dynamic result;
    try {
      result = await _channel.invokeMethod('shareOnFacebook', arguments);
    } catch (e) {
      return null;
    }
    return result;
  }

}
