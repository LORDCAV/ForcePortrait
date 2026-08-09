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
        CGFloat r = 0, g = 0, b = 0, a = 0;
        [view.backgroundColor getRed:&r green:&g blue:&b alpha:&a];
        
        // Force all white banners (like Opening Moves) and navbar layouts straight to black
        if (r > 0.85 && g > 0.85 && b > 0.85) {
            view.backgroundColor = [UIColor colorWithRed:15.0/255.0 green:15.0/255.0 blue:15.0/255.0 alpha:a];
        }
    }

    // 2. UNIVERSAL OVERLAY DETECTION
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
            
            if (r < 0.8 && g < 0.8 && b < 0.8) {
                if (!(r > 0.6 && g > 0.5 && b < 0.2)) { // Preserve yellow branding
                    label.textColor = [UIColor whiteColor];
                }
            }
        }
    }

    // 4. CHAT COMPONENT TEXT VIEWS & FIELDS
    if ([view isKindOfClass:[UITextView class]]) {
        UITextView *tv = (UITextView *)view;
        tv.textColor = [UIColor whiteColor];
    }
    if ([view isKindOfClass:[UITextField class]]) {
        UITextField *tf = (UITextField *)view;
        tf.textColor = [UIColor whiteColor];
        tf.backgroundColor = [UIColor colorWithRed:30.0/255.0 green:30.0/255.0 blue:30.0/255.0 alpha:1.0];
    }

    for (UIView *subview in view.subviews) {
        [BumbleUniversalDarkEngine applyThemeToView:subview];
    }
}
@end

// ============================================================================
// LIVE TRANSITION TRACKING RUNTIME HOOKS
// ============================================================================
__attribute__((constructor))
static void init(void) {
    @autoreleasepool {
        // Corrected notification hooks targeting window hierarchy changes
        [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationUserInterfaceStyleDidChangeNotification
                                                          object:nil
                                                           queue:[NSOperationQueue mainQueue]
                                                      usingBlock:^(NSNotification * _Nonnull note) {
            UIWindow *activeWindow = [UIApplication sharedApplication].keyWindow;
            if (activeWindow) {
                [BumbleUniversalDarkEngine applyThemeToView:activeWindow];
            }
        }];

        // Hook view lifecycle changes to cover tab navigation clicks smoothly
        Class vcClass = [UIViewController class];
        SEL viewDidAppearSel = @selector(viewDidAppear:);
        __block IMP originalViewDidAppear = NULL;
        
        id block = ^(void *self, BOOL animated) {
            if (originalViewDidAppear) {
                ((void (*)(void *, BOOL))originalViewDidAppear)(self, animated);
            }
            UIViewController *vc = (__bridge UIViewController *)self;
            if (vc.view) {
                [BumbleUniversalDarkEngine applyThemeToView:vc.view];
            }
        };
        
        IMP newViewDidAppear = imp_implementationWithBlock(block);
        Method origVCMethod = class_getInstanceMethod(vcClass, viewDidAppearSel);
        originalLayoutSubviews = method_setImplementation(origVCMethod, newViewDidAppear);

        // Lock dark theme parameters on startup
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

