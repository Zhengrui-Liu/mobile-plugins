import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:photo_editor_sdk/photo_editor_sdk.dart';

void main() {
  const MethodChannel channel = MethodChannel('photo_editor_sdk');

  setUp(() {
    channel.setMockMethodCallHandler((MethodCall methodCall) async {
      return '42';
    });
  });

  tearDown(() {
    channel.setMockMethodCallHandler(null);
  });

  test('getPlatformVersion', () async {
    expect(await PhotoEditorSdk.platformVersion, '42');
  });
}
