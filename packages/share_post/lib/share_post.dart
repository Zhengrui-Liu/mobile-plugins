import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';

class SharePost {

  static String INSTAGRAM         =
  type("https://apps.apple.com/br/app/instagram/id389801252",
      "https://play.google.com/store/apps/details?id=com.instagram.android");
  static String WHATSAPP          =
  type("https://apps.apple.com/br/app/whatsapp-messenger/id310633997",
      "https://play.google.com/store/apps/details?id=com.whatsapp");
  static String WHATSAPP_BUSINESS =
  type("https://apps.apple.com/br/app/whatsapp-business/id1386412985",
      "https://play.google.com/store/apps/details?id=com.whatsapp.w4b");

  static type(String appleStoreLink, String googlePlayLink) {
    return Platform.isIOS ? appleStoreLink : googlePlayLink;
  }

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

  static Future<List<Map<dynamic, dynamic>>> getFacebookUserPages() async {
    List<Map<dynamic, dynamic>> result;
    try {
      result = await _channel.invokeListMethod('getFacebookUserPages');
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
      return (e as PlatformException).code;
    }
    return result;
  }

  static Future<String> shareStoryOnInstagram(String url, String message) async {
    final Map<String, Object> arguments = Map<String, dynamic>();
    arguments.putIfAbsent('url', () => url);
    arguments.putIfAbsent('message', () => message);
    dynamic result;
    try {
      result = await _channel.invokeMethod('shareStoryOnInstagram', arguments);
    } catch (e) {
      return (e as PlatformException).code;
    }
    return result;
  }

  static Future<String> sharePostOnInstagram(String url, String message) async {
    final Map<String, Object> arguments = Map<String, dynamic>();
    arguments.putIfAbsent('url', () => url);
    arguments.putIfAbsent('message', () => message);
    dynamic result;
    try {
      result = await _channel.invokeMethod('sharePostOnInstagram', arguments);
    } catch (e) {
      return (e as PlatformException).code;
    }
    return result;
  }

  static Future<String> shareOnWhatsapp(String url, String message) async {
    final Map<String, Object> arguments = Map<String, dynamic>();
    arguments.putIfAbsent('url', () => url);
    arguments.putIfAbsent('message', () => message);
    dynamic result;
    try {
      result = await _channel.invokeMethod('shareOnWhatsapp', arguments);
    } catch (e) {
      return (e as PlatformException).code;
    }
    return result;
  }

  static Future<String> shareOnWhatsappBusiness(String url, String message) async {
    final Map<String, Object> arguments = Map<String, dynamic>();
    arguments.putIfAbsent('url', () => url);
    arguments.putIfAbsent('message', () => message);
    dynamic result;
    try {
      result = await _channel.invokeMethod('shareOnWhatsappBusiness', arguments);
    } catch (e) {
      return (e as PlatformException).code;
    }
    return result;
  }

  static Future<String> shareOnNative(String url, String message) async {
    final Map<String, Object> arguments = Map<String, dynamic>();
    arguments.putIfAbsent('url', () => url);
    arguments.putIfAbsent('message', () => message);
    dynamic result;
    try {
      result = await _channel.invokeMethod('shareOnNative', arguments);
    } catch (e) {
      return null;
    }
    return result;
  }

  static Future<String> openAppOnStore(String appUrl) async {
    final Map<String, Object> arguments = Map<String, dynamic>();
    arguments.putIfAbsent('appUrl', () => appUrl);
    dynamic result;
    try {
      result = await _channel.invokeMethod('openAppOnStore', arguments);
    } catch (e) {
      return (e as PlatformException).code;
    }
    return result;
  }

}
