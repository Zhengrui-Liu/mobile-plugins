import 'dart:io';

import 'package:flutter/material.dart';
//import 'package:image_downloader/image_downloader.dart';

import 'package:photo_editor_sdk/photo_editor_sdk.dart';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _platformVersion = 'Unknown';

  @override
  void initState() {
    super.initState();
    _openEditor();
  }

  _openEditor() async {
    PhotoEditorSdk.editImage(null).then((r) {

    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: Center(
          child: Text('Running on: $_platformVersion\n'),
        ),
      ),
    );
  }
}
