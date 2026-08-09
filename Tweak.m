#import <UIKit/UIKit.h>
#import <objc/runtime.h>

@interface BumbleDarkManager : NSObject
+ (void)applyDarkThemeToView:(UIView *)view;
@end

@implementation BumbleDarkManager

+ (void)applyDarkThemeToView:(UIView *)view {
    if (!view) return;

    // 1. Invert white or bright backgrounds to dark midnight grey
    if (view.backgroundColor) {
        CGFloat red = 0, green = 0, blue = 0, alpha = 0;
        [view.backgroundColor getRed:&red green:&green blue:&blue alpha:&alpha];
        
        if (red > 0.85 && green > 0.85 && blue > 0.85) {
            view.backgroundColor = [UIColor colorWithRed:20.0/255.0 green:20.0/255.0 blue:20.0/255.0 alpha:alpha];
        }
    }

    // 2. Invert dark text strings to pure white for perfect legibility
    if ([view isKindOfClass:[UILabel class]]) {
        UILabel *label = (UILabel *)view;
        CGFloat red = 0, green = 0, blue = 0, alpha = 0;
        [label.textColor getRed:&red green:&green blue:&blue alpha:&alpha];
        
        if (red < 0.3 && green < 0.3 && blue < 0.3) {
            label.textColor = [UIColor whiteColor];
        }
    }

    // 3. Handle text input fields safely
    if ([view isKindOfClass:[UITextField class]]) {
        UITextField *field = (UITextField *)view;
        field.backgroundColor = [UIColor colorWithRed:35.0/255.0 green:35.0/255.0 blue:35.0/255.0 alpha:1.0];
        field.textColor = [UIColor whiteColor];
    }

    // Deep-dive scan through child view arrays recursively
    for (UIView *subview in view.subviews) {
        [BumbleDarkManager applyDarkThemeToView:subview];
    }
}
@end

// ============================================================================
// SYSTEM-WIDE RUNTIME INTERCEPTIONS
// ============================================================================
__attribute__((constructor))
static void init(void) {
    @autoreleasepool {
        // Safe notification listener targeting active multitasking views
        [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidBecomeActiveNotification
                                                          object:nil
                                                           queue:[NSOperationQueue mainQueue]
                                                      usingBlock:^(NSNotification * _Nonnull note) {
            UIWindow *activeWindow = nil;
            
            // Loop through active scene arrays to satisfy the iOS 16 compiler requirements
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
            
            // Safe fallback configuration wrapped inside compiler ignore blocks
            if (!activeWindow) {
                #pragma clang diagnostic push
                #pragma clang diagnostic ignored "-Wdeprecated-declarations"
                activeWindow = [UIApplication sharedApplication].keyWindow;
                #pragma clang diagnostic pop
            }
            
            if (activeWindow) {
                [BumbleDarkManager applyDarkThemeToView:activeWindow];
            }
        }];
        
        // Intercept standard view sublayout rearrangements to maintain theme on scroll
        Class viewClass = [UIView class];
        SEL layoutSelector = @selector(layoutSubviews);
        __block IMP originalLayoutSubviews = NULL;
        
        id block = ^(void *self) {
            if (originalLayoutSubviews) {
                ((void (*)(void *))originalLayoutSubviews)(self);
            }
            UIView *currentView = (__bridge UIView *)self;
            [BumbleDarkManager applyDarkThemeToView:currentView];
        };
        
        IMP newLayoutSubviews = imp_implementationWithBlock(block);
        Method origMethod = class_getInstanceMethod(viewClass, layoutSelector);
        originalLayoutSubviews = method_setImplementation(origMethod, newLayoutSubviews);
    }
}
