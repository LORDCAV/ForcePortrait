#import <UIKit/UIKit.h>
#import <objc/runtime.h>

@interface BumbleUniversalDarkEngine : NSObject
+ (void)applyThemeToView:(UIView *)view;
@end

@implementation BumbleUniversalDarkEngine

+ (void)applyThemeToView:(UIView *)view {
    if (!view) return;

    // 1. GLOBAL BACKGROUND CONVERSION PANEL
    if (view.backgroundColor) {
        NSString *className = NSStringFromClass([view class]);
        if ([className containsString:@"Grid"] || [className containsString:@"List"] || [className containsString:@"Collection"] || [className containsString:@"Scroll"]) {
            view.backgroundColor = [UIColor colorWithRed:15.0/255.0 green:15.0/255.0 blue:15.0/255.0 alpha:1.0];
        } else {
            CGFloat r = 0, g = 0, b = 0, a = 0;
            [view.backgroundColor getRed:&r green:&g blue:&b alpha:&a];
            
            // Force all bright layout grids, rows, and banners straight to dark grey/black
            if (r > 0.82 && g > 0.82 && b > 0.82) {
                view.backgroundColor = [UIColor colorWithRed:15.0/255.0 green:15.0/255.0 blue:15.0/255.0 alpha:a];
            }
        }
    }

    // 2. UNIVERSAL OVERLAY DETECTION (Fixes headers, navbars, and custom banner cards)
    NSString *className = NSStringFromClass([view class]);
    if ([className containsString:@"Header"] || [className containsString:@"Banner"] || [className containsString:@"Bar"] || [className containsString:@"Card"]) {
        CGFloat r = 0, g = 0, b = 0, a = 0;
        if (view.backgroundColor) {
            [view.backgroundColor getRed:&r green:&g blue:&b alpha:&a];
            if (r > 0.8 || g > 0.8 || b > 0.8) {
                view.backgroundColor = [UIColor colorWithRed:22.0/255.0 green:22.0/255.0 blue:22.0/255.0 alpha:1.0];
            }
        }
    }

    // 3. PRECISION LABEL RE-COLORING
    if ([view isKindOfClass:[UILabel class]]) {
        UILabel *label = (UILabel *)view;
        
        if (label.attributedText && label.attributedText.length > 0) {
            NSMutableAttributedString *mutableString = [label.attributedText mutableCopy];
            [mutableString addAttribute:NSForegroundColorAttributeName value:[UIColor whiteColor] range:NSMakeRange(0, mutableString.length)];
            label.attributedText = mutableString;
        } else if (label.textColor) {
            CGFloat r = 0, g = 0, b = 0, a = 0;
            [label.textColor getRed:&r green:&g blue:&b alpha:&a];
            
            if (r < 0.85 && g < 0.85 && b < 0.85) {
                if (!(r > 0.6 && g > 0.5 && b < 0.2)) { // Preserve yellow branding strings
                    label.textColor = [UIColor whiteColor];
                }
            }
        }
    }

    // 4. CHAT COMPONENT TEXT VIEWS & INPUT BOXES
    if ([view isKindOfClass:[UITextView class]]) {
        UITextView *tv = (UITextView *)view;
        tv.textColor = [UIColor whiteColor];
    }
    if ([view isKindOfClass:[UITextField class]]) {
        UITextField *tf = (UITextField *)view;
        tf.textColor = [UIColor whiteColor];
        tf.backgroundColor = [UIColor colorWithRed:30.0/255.0 green:30.0/255.0 blue:30.0/255.0 alpha:1.0];
    }

    // Safely look into subviews
    for (UIView *subview in view.subviews) {
        [BumbleUniversalDarkEngine applyThemeToView:subview];
    }
}
@end

// ============================================================================
// CONTINUOUS GLOBAL CANVAS HEARTBEAT HOOKS
// ============================================================================
__attribute__((constructor))
static void init(void) {
    @autoreleasepool {
        // Core Layout Heartbeat Hook (Triggers every time the app updates, flips tabs, or redraws)
        Class viewClass = [UIView class];
        SEL layoutSelector = @selector(layoutSubviews);
        __block IMP originalLayoutSubviews = NULL;
        
        id block = ^(void *self) {
            if (originalLayoutSubviews) {
                ((void (*)(void *))originalLayoutSubviews)(self);
            }
            UIView *currentView = (__bridge UIView *)self;
            // Instantly catch any tab switches, collection refreshes, or server changes on the fly
            [BumbleUniversalDarkEngine applyThemeToView:currentView];
        };
        
        IMP newLayoutSubviews = imp_implementationWithBlock(block);
        Method origMethod = class_getInstanceMethod(viewClass, layoutSelector);
        originalLayoutSubviews = method_setImplementation(origMethod, newLayoutSubviews);

        // Lock global dark appearance layouts on cold boot
        [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidFinishLaunchingNotification
                                                          object:nil
                                                           queue:[NSOperationQueue mainQueue]
                                                      usingBlock:^(NSNotification * _Nonnull note) {
            if (@available(iOS 13.0, *)) {
                for (UIScene *scene in [UIApplication sharedApplication].connectedScenes) {
                    if (scene.activationState == UISceneActivationStateForegroundActive && [scene isKindOfClass:[UIWindowScene class]]) {
                        UIWindowScene *windowScene = (UIWindowScene *)scene;
                        windowScene.keyWindow.overrideUserInterfaceStyle = UIUserInterfaceStyleDark;
                    }
                }
            }
        }];
    }
}
