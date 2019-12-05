#import "PhotoEditorPlugin.h"
#import <photo_editor/photo_editor-Swift.h>

@implementation PhotoEditorPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftPhotoEditorPlugin registerWithRegistrar:registrar];
}
@end
