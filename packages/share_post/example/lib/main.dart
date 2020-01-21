import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:share_post/share_post.dart';
import 'package:flutter_facebook_login/flutter_facebook_login.dart';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _platformVersion = 'Unknown';
  Image image;

  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    String platformVersion;
    // Platform messages may fail, so we use a try/catch PlatformException.
    try {
      platformVersion = await SharePost.platformVersion;
    } on PlatformException {
      platformVersion = 'Failed to get platform version.';
    }

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;

    setState(() {
      _platformVersion = platformVersion;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: Column(
          children: <Widget>[
            Center(
              child: Text('Running on: $_platformVersion\n'),
            ),
            RaisedButton(
              child: Text('Compartilhar'),
              onPressed: _onClick,
            ),
            image ?? Container()
          ],
        ),
      ),
    );
  }

  void _onClick() async {

//    final facebookLogin = FacebookLogin();
//    final result = await facebookLogin.logIn(["email", "pages_show_list",
//      "publish_pages", "manage_pages", "public_profile"]);
//    var page = await SharePost.getFacebookUserPages();

//    var user = await SharePost.getFacebookUser();
//
//    var map = page.first;
//    var token = map["access_token"];
//
//
//    await SharePost.shareOnFacebook(
//        "https://encrypted-tbn0.gstatic.com/images?q=tbn%3AANd9GcTYZqQeg5UFJJC6MvvBPkjTJNdnABMY1RZM6e__-K1eiCLIxUVm",
//        "message here",
//        token, null,
//        m

    await SharePost.shareOnNative(
      "https://encrypted-tbn0.gstatic.com/images?q=tbn%3AANd9GcTYZqQeg5UFJJC6MvvBPkjTJNdnABMY1RZM6e__-K1eiCLIxUVm",
      "message here",
    );

    var a = "";

//    String a = await SharePost.shareOnWhatsappBusiness(
//        "https://encrypted-tbn0.gstatic.com/images?q=tbn%3AANd9GcRdezBUdWFUbArwZCmQq7_nJNqEcK_02k9laUugbomQV5wtbhHz",
//        "message"
//    );

//    SharePost.openAppOnStore(SharePost.INSTAGRAM);

  }


}
