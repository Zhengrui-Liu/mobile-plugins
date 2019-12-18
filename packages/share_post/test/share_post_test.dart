import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:share_post/share_post.dart';

void main() {
  const MethodChannel channel = MethodChannel('share_post');

  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    channel.setMockMethodCallHandler((MethodCall methodCall) async {
      return '42';
    });
  });

  tearDown(() {
    channel.setMockMethodCallHandler(null);
  });

  test('getPlatformVersion', () async {
    expect(await SharePost.platformVersion, '42');
  });
}
