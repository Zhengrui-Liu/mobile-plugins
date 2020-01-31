#import "PhotoEditorSdkPlugin.h"
#if __has_include(<photo_editor_sdk/photo_editor_sdk-Swift.h>)
#import <photo_editor_sdk/photo_editor_sdk-Swift.h>
#else
// Support project import fallback if the generated compatibility header
// is not copied when this plugin is created as a library.
// https://forums.swift.org/t/swift-static-libraries-dont-copy-generated-objective-c-header/19816
#import "photo_editor_sdk-Swift.h"
#endif

@implementation PhotoEditorSdkPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftPhotoEditorSdkPlugin registerWithRegistrar:registrar];
}
@end
