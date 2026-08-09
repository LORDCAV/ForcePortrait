#import <UIKit/UIKit.h>

@interface BumbleStyleLoader : NSObject
+ (void)loadCustomSkin;
@end

@implementation BumbleStyleLoader

+ (void)loadCustomSkin {
    dispatch_async(dispatch_get_main_queue(), ^{
        // Set the global theme preference window to dark mode safely on boot
        if (@available(iOS 13.0, *)) {
            for (UIScene *scene in [UIApplication sharedApplication].connectedScenes) {
                if (scene.activationState == UISceneActivationStateForegroundActive && [scene isKindOfClass:[UIWindowScene class]]) {
                    UIWindowScene *windowScene = (UIWindowScene *)scene;
                    windowScene.keyWindow.overrideUserInterfaceStyle = UIUserInterfaceStyleDark;
                }
            }
        }
    });
}
@end

__attribute__((constructor))
static void init(void) {
    @autoreleasepool {
        // Run exactly once on launch to prevent memory loop crashes
        [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidFinishLaunchingNotification
                                                          object:nil
                                                           queue:[NSOperationQueue mainQueue]
                                                      usingBlock:^(NSNotification * _Nonnull note) {
            [BumbleStyleLoader loadCustomSkin];
        }];
    }
}

