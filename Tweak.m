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

    // 2. ATTRIBUTED TEXT OVERRIDER (Fixes About Me, Interest Tags, and Locations)
    if ([view isKindOfClass:[UILabel class]]) {
        UILabel *label = (UILabel *)view;
        
        // Check if Bumble is using an attributed string text layout format
        if (label.attributedText && label.attributedText.length > 0) {
            NSMutableAttributedString *mutableAttString = [label.attributedText mutableCopy];
            NSRange fullRange = NSMakeRange(0, mutableAttString.length);
            
            // Force the foreground text color layer key directly to pure white
            [mutableAttString addAttribute:NSForegroundColorAttributeName value:[UIColor whiteColor] range:fullRange];
            label.attributedText = mutableAttString;
        } else if (label.textColor) {
            // Fallback for standard string properties
            CGFloat red = 0, green = 0, blue = 0, alpha = 0;
            [label.textColor getRed:&red green:&green blue:&blue alpha:&alpha];
            
            if (red < 0.82 && green < 0.82 && blue < 0.82) {
                if (red > 0.6 && green > 0.5 && blue < 0.2) {
                    label.textColor = [UIColor colorWithRed:255.0/255.0 green:204.0/255.0 blue:0.0/255.0 alpha:1.0];
                } else {
                    label.textColor = [UIColor whiteColor];
                }
            }
        }
    }

    // 3. Multi-line Rich Text View Container Brightener (Fixes detailed prompt answers)
    if ([view isKindOfClass:[UITextView class]]) {
        UITextView *textView = (UITextView *)view;
        textView.backgroundColor = [UIColor clearColor];
        
        if (textView.attributedText && textView.attributedText.length > 0) {
            NSMutableAttributedString *mutableAttString = [textView.attributedText mutableCopy];
            NSRange fullRange = NSMakeRange(0, mutableAttString.length);
            [mutableAttString addAttribute:NSForegroundColorAttributeName value:[UIColor whiteColor] range:fullRange];
            textView.attributedText = mutableAttString;
        } else if (textView.textColor) {
            CGFloat red = 0, green = 0, blue = 0, alpha = 0;
            [textView.textColor getRed:&red green:&green blue:&blue alpha:&alpha];
            if (red < 0.82 && green < 0.82 && blue < 0.82) {
                textView.textColor = [UIColor whiteColor];
            }
        }
    }

    // 4. Interactive Profile Selection Buttons
    if ([view isKindOfClass:[UIButton class]]) {
        UIButton *button = (UIButton *)view;
        if (button.titleLabel) {
            [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
            [button setTitleColor:[UIColor whiteColor] forState:UIControlStateSelected];
        }
    }

    // 5. Active Chat Box Input Customization
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

