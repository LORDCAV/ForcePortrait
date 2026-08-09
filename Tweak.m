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
            view.backgroundColor = [UIColor colorWithRed:15.0/255.0 green:15.0/255.0 blue:15.0/255.0 alpha:alpha];
        }
    }

    // 2. Standard Label Text Brightener (Targeting basic profiles and headings)
    if ([view isKindOfClass:[UILabel class]]) {
        UILabel *label = (UILabel *)view;
        CGFloat red = 0, green = 0, blue = 0, alpha = 0;
        [label.textColor getRed:&red green:&green blue:&blue alpha:&alpha];
        
        if (red < 0.75 && green < 0.75 && blue < 0.75) {
            if (red > 0.6 && green > 0.5 && blue < 0.2) {
                label.textColor = [UIColor colorWithRed:255.0/255.0 green:204.0/255.0 blue:0.0/255.0 alpha:1.0];
            } else {
                label.textColor = [UIColor whiteColor];
            }
        }
    }

    // 3. Multi-line Bio & Chat Bubble Text View Brightener
    if ([view isKindOfClass:[UITextView class]]) {
        UITextView *textView = (UITextView *)view;
        textView.backgroundColor = [UIColor clearColor];
        
        CGFloat red = 0, green = 0, blue = 0, alpha = 0;
        [textView.textColor getRed:&red green:&green blue:&blue alpha:&alpha];
        
        if (red < 0.75 && green < 0.75 && blue < 0.75) {
            textView.textColor = [UIColor whiteColor];
        }
    }

    // 4. NEW: Interactive Button Text Overrider (Fixes grey info buttons/tags on swiping cards)
    if ([view isKindOfClass:[UIButton class]]) {
        UIButton *button = (UIButton *)view;
        
        // Target text inside standard buttons
        if (button.titleLabel) {
            CGFloat red = 0, green = 0, blue = 0, alpha = 0;
            [button.titleLabel.textColor getRed:&red green:&green blue:&blue alpha:&alpha];
            
            if (red < 0.75 && green < 0.75 && blue < 0.75) {
                [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
                [button setTitleColor:[UIColor whiteColor] forState:UIControlStateSelected];
            }
        }
        
        // Target modern configuration button styles introduced in newer iOS versions
        if (@available(iOS 15.0, *)) {
            if (button.configuration) {
                UIButtonConfiguration *config = button.configuration;
                if (config.baseForegroundColor) {
                    CGFloat red = 0, green = 0, blue = 0, alpha = 0;
                    [config.baseForegroundColor getRed:&red green:&green blue:&blue alpha:&alpha];
                    if (red < 0.75 && green < 0.75 && blue < 0.75) {
                        config.baseForegroundColor = [UIColor whiteColor];
                        button.configuration = config;
                    }
                }
            }
        }
    }

    // 5. Input Text Box Field Styling
    if ([view isKindOfClass:[UITextField class]]) {
        UITextField *field = (UITextField *)view;
        field.backgroundColor = [UIColor colorWithRed:30.0/255.0 green:30.0/255.0 blue:30.0/255.0 alpha:1.0];
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

