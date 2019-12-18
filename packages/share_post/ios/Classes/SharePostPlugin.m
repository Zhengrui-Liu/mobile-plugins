#import "SharePostPlugin.h"
#if __has_include(<share_post/share_post-Swift.h>)
#import <share_post/share_post-Swift.h>
#else
// Support project import fallback if the generated compatibility header
// is not copied when this plugin is created as a library.
// https://forums.swift.org/t/swift-static-libraries-dont-copy-generated-objective-c-header/19816
#import "share_post-Swift.h"
#endif

@implementation SharePostPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftSharePostPlugin registerWithRegistrar:registrar];
}
@end
