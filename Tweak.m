#import <UIKit/UIKit.h>
#import <objc/runtime.h>

@interface BumbleDarkManager : NSObject
+ (void)applyDarkThemeToView:(UIView *)view;
@end

@implementation BumbleDarkManager

+ (void)applyDarkThemeToView:(UIView *)view {
    if (!view) return;

    // 1. Invert white or bright backgrounds to a premium dark midnight theme
    if (view.backgroundColor) {
        CGFloat red = 0, green = 0, blue = 0, alpha = 0;
        [view.backgroundColor getRed:&red green:&green blue:&blue alpha:&alpha];
        
        if (red > 0.85 && green > 0.85 && blue > 0.85) {
            view.backgroundColor = [UIColor colorWithRed:18.0/255.0 green:18.0/255.0 blue:18.0/255.0 alpha:alpha];
        }
    }

    // 2. UNIVERSAL DEEP TEXT BRIGHTENER (Fixes swiping profile cards text)
    if ([view isKindOfClass:[UILabel class]]) {
        UILabel *label = (UILabel *)view;
        CGFloat red = 0, green = 0, blue = 0, alpha = 0;
        if (label.textColor) {
            [label.textColor getRed:&red green:&green blue:&blue alpha:&alpha];
            
            // Check if the text is dark or greyish (not yellow or bright white)
            if (red < 0.82 && green < 0.82 && blue < 0.82) {
                // Preserve Bumble's yellow text links and tags perfectly
                if (red > 0.6 && green > 0.5 && blue < 0.2) {
                    label.textColor = [UIColor colorWithRed:255.0/255.0 green:204.0/255.0 blue:0.0/255.0 alpha:1.0];
                } else {
                    // Force all grey profile info, distance text, and bios to crisp white
                    label.textColor = [UIColor whiteColor];
                }
            }
        }
    }

    // 3. Multi-line Text Field & Chat Bubble Content Brightener
    if ([view isKindOfClass:[UITextView class]]) {
        UITextView *textView = (UITextView *)view;
        textView.backgroundColor = [UIColor clearColor];
        
        CGFloat red = 0, green = 0, blue = 0, alpha = 0;
        if (textView.textColor) {
            [textView.textColor getRed:&red green:&green blue:&blue alpha:&alpha];
            if (red < 0.82 && green < 0.82 && blue < 0.82) {
                textView.textColor = [UIColor whiteColor];
            }
        }
    }

    // 4. Interactive Profile Buttons & Info Tag Labels
    if ([view isKindOfClass:[UIButton class]]) {
        UIButton *button = (UIButton *)view;
        if (button.titleLabel) {
            CGFloat red = 0, green = 0, blue = 0, alpha = 0;
            [button.titleLabel.textColor getRed:&red green:&green blue:&blue alpha:&alpha];
            if (red < 0.82 && green < 0.82 && blue < 0.82) {
                [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
                [button setTitleColor:[UIColor whiteColor] forState:UIControlStateSelected];
            }
        }
    }

    // 5. Active Chat Input Field Customization
    if ([view isKindOfClass:[UITextField class]]) {
        UITextField *field = (UITextField *)view;
        field.backgroundColor = [UIColor colorWithRed:32.0/255.0 green:32.0/255.0 blue:32.0/255.0 alpha:1.0];
        field.textColor = [UIColor whiteColor];
    }

    // Deep-dive scan through child view arrays recursively to sweep all layouts
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
                [BumbleDarkManager applyDarkThemeToView:activeWindow];
            }
        }];
        
        // Main view rendering heartbeat hook (keeps layout dark while scrolling)
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

