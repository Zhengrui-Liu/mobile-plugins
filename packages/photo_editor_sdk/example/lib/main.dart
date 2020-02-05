import 'dart:io';

import 'package:flutter/material.dart';

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


    PhotoEditorSdk.addAllContents(
        logos: [
          "https://encrypted-tbn0.gstatic.com/images?q=tbn%3AANd9GcQN5h7AhxdwNgR1hanAFyV4VA87ujSDaGpJymSwLQHJEMl573l6",
          "https://encrypted-tbn0.gstatic.com/images?q=tbn%3AANd9GcRw1jedDvieNuFQeXEKXp4F_ny9X1QFGU5HlZbB61nUliyxyy5Y",
          "https://pt.freelogodesign.org/Content/img/logo-samples/bakary.png"
        ],
        stickers: [
          "https://encrypted-tbn0.gstatic.com/images?q=tbn%3AANd9GcRqMKspUMJsK9fQsQJEHgmQx1U8IOTs5HP0vgbVfZqynEo6-IIm",
          "https://encrypted-tbn0.gstatic.com/images?q=tbn%3AANd9GcS0uCtvg269jcaKa2P2AyYcrw5h-DRJR0Lpe2by9I5LZu15GBZN",
          "https://encrypted-tbn0.gstatic.com/images?q=tbn%3AANd9GcSS0zCE8uqmkD1DaSLuaXxYpJSuatSOyWdkaFhafZe-z8RKC6Kk",
        ]
    );

    PhotoEditorSdk.editImage("https://images.carreirabeauty.com/uploads/feed/file/586bb563993a7a09230f8431/ahazou.jpg").then((r) {

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
