#import "PhotoEditorSdkPlugin.h"
#import <photo_editor_sdk/photo_editor_sdk-Swift.h>

@implementation PhotoEditorSdkPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftPhotoEditorSdkPlugin registerWithRegistrar:registrar];
}
@end
