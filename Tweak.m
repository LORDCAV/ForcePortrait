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

    // 2. FORCE SYSTEM CONTRAST RENDERING (Fixes SwiftUI and Canvas Grey Text)
    // Intercepts the graphics layer and forces it to draw text with absolute white foreground properties
    if ([view respondsToSelector:@selector(setTintColor:)]) {
        #pragma clang diagnostic push
        #pragma clang diagnostic ignored "-Wdeprecated-declarations"
        view.tintColor = [UIColor whiteColor];
        #pragma clang diagnostic pop
    }

    if ([view isKindOfClass:[UILabel class]]) {
        UILabel *label = (UILabel *)view;
        label.textColor = [UIColor whiteColor];
        
        if (label.attributedText && label.attributedText.length > 0) {
            NSMutableAttributedString *mutableAttString = [label.attributedText mutableCopy];
            [mutableAttString addAttribute:NSForegroundColorAttributeName value:[UIColor whiteColor] range:NSMakeRange(0, mutableAttString.length)];
            label.attributedText = mutableAttString;
        }
    }

    if ([view isKindOfClass:[UITextView class]]) {
        UITextView *textView = (UITextView *)view;
        textView.backgroundColor = [UIColor clearColor];
        textView.textColor = [UIColor whiteColor];
        
        if (textView.attributedText && textView.attributedText.length > 0) {
            NSMutableAttributedString *mutableAttString = [textView.attributedText mutableCopy];
            [mutableAttString addAttribute:NSForegroundColorAttributeName value:[UIColor whiteColor] range:NSMakeRange(0, mutableAttString.length)];
            textView.attributedText = mutableAttString;
        }
    }

    // 3. Force buttons and icon titles to white
    if ([view isKindOfClass:[UIButton class]]) {
        UIButton *button = (UIButton *)view;
        [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [button setTitleColor:[UIColor whiteColor] forState:UIControlStateSelected];
        if (button.imageView) {
            button.imageView.tintColor = [UIColor whiteColor];
        }
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
                // Forces the entire window layout engine to use heavy high contrast configurations
                if (@available(iOS 13.0, *)) {
                    activeWindow.overrideUserInterfaceStyle = UIUserInterfaceStyleDark;
                }
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
