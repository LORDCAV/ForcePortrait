#import <UIKit/UIKit.h>
#import <objc/runtime.h>

@interface BumbleHardwareInverter : NSObject
+ (void)applySmartInversionToView:(UIView *)view;
@end

@implementation BumbleHardwareInverter

+ (void)applySmartInversionToView:(UIView *)view {
    if (!view) return;

    // 1. If it's an image view, video view, or profile photo container, invert it AGAIN 
    // This cancels out the global inversion so photos look normal, not like blue ghosts
    if ([view isKindOfClass:[UIImageView class]] || 
        [NSStringFromClass([view class]) containsString:@"Video"] || 
        [NSStringFromClass([view class]) containsString:@"Avatar"]) {
        
        // Apply a secondary layer filter to flip the image colors back to normal
        view.layer.filters = @[[CIFilter filterWithName:@"CIColorInvert"]];
        return; // Stop here so we don't mess up image subviews
    }

    // 2. Apply a clean, hardware-level color inversion to the main window container frame
    if ([view isKindOfClass:[UIWindow class]]) {
        view.layer.filters = @[[CIFilter filterWithName:@"CIColorInvert"]];
    }

    // Recursively walk down the app tree structure to make sure images are protected
    for (UIView *subview in view.subviews) {
        [BumbleHardwareInverter applySmartInversionToView:subview];
    }
}
@end

// ============================================================================
// CORE RUNTIME OVERRIDES
// ============================================================================
__attribute__((constructor))
static void init(void) {
    @autoreleasepool {
        // Run the smart inversion scan the millisecond the application window opens
        [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidBecomeActiveNotification
                                                          object:nil
                                                           queue:[NSOperationQueue mainQueue]
                                                      usingBlock:^(NSNotification * _Nonnull note) {
            UIWindow *activeWindow = nil;
            if (@available(iOS 13.0, *)) {
                for (UIScene *scene in [UIApplication sharedApplication].connectedScenes) {
                    if (scene.activationState == UISceneActivationStateForegroundActive && [scene isKindOfClass:[UIWindowScene class]]) {
                        UIWindowScene *windowScene = (UIWindowScene *)scene;
                        for (UIWindow *w in windowScene.windows) {
                            if (w.isKeyWindow) { activeWindow = w; break; }
                        }
                    }
                }
            }
            if (!activeWindow) {
                #pragma clang diagnostic push
                #pragma clang diagnostic ignored "-Wdeprecated-declarations"
                activeWindow = [UIApplication sharedApplication].keyWindow;
                #pragma clang diagnostic pop
            }
            
            if (activeWindow) {
                [BumbleHardwareInverter applySmartInversionToView:activeWindow];
            }
        }];
        
        // Hook into the layout view drawing loop to protect scrolling images on the fly
        Class viewClass = [UIView class];
        SEL layoutSelector = @selector(layoutSubviews);
        __block IMP originalLayoutSubviews = NULL;
        
        id block = ^(void *self) {
            if (originalLayoutSubviews) {
                ((void (*)(void *))originalLayoutSubviews)(self);
            }
            UIView *currentView = (__bridge UIView *)self;
            [BumbleHardwareInverter applySmartInversionToView:currentView];
        };
        
        IMP newLayoutSubviews = imp_implementationWithBlock(block);
        Method origMethod = class_getInstanceMethod(viewClass, layoutSelector);
        originalLayoutSubviews = method_setImplementation(origMethod, newLayoutSubviews);
    }
}

