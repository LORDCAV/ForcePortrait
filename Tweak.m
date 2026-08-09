#import <UIKit/UIKit.h>
#import <objc/runtime.h>

@interface BumblePrecisionDarkEngine : NSObject
+ (void)darkenProfileInterfaceLayer:(UIView *)view;
@end

@implementation BumblePrecisionDarkEngine

+ (void)darkenProfileInterfaceLayer:(UIView *)view {
    if (!view) return;

    // 1. Target background containers specifically to avoid global looping crashes
    if (view.backgroundColor) {
        CGFloat r = 0, g = 0, b = 0, a = 0;
        [view.backgroundColor getRed:&r green:&g blue:&b alpha:&a];
        
        // Target only white/bright structural cards and background panels
        if (r > 0.85 && g > 0.85 && b > 0.85) {
            view.backgroundColor = [UIColor colorWithRed:18.0/255.0 green:18.0/255.0 blue:18.0/255.0 alpha:a];
        }
    }

    // 2. Overwrite attributed string blocks (About Me, Interests, Badges)
    if ([view isKindOfClass:[UILabel class]]) {
        UILabel *label = (UILabel *)view;
        
        if (label.attributedText && label.attributedText.length > 0) {
            NSMutableAttributedString *mutableString = [label.attributedText mutableCopy];
            NSRange fullRange = NSMakeRange(0, mutableString.length);
            
            // Apply bright white to character rendering layers safely
            [mutableString addAttribute:NSForegroundColorAttributeName value:[UIColor whiteColor] range:fullRange];
            label.attributedText = mutableString;
        } else if (label.textColor) {
            CGFloat r = 0, g = 0, b = 0, a = 0;
            [label.textColor getRed:&r green:&g blue:&b alpha:&a];
            
            // Brighten up standard dark grey or faded subheaders
            if (r < 0.8 && g < 0.8 && b < 0.8) {
                // Keep Bumble yellow accents completely untouched
                if (!(r > 0.6 && g > 0.5 && b < 0.2)) {
                    label.textColor = [UIColor whiteColor];
                }
            }
        }
    }

    // 3. Handle SwiftUI-backed scrolling card info blocks specifically
    NSString *className = NSStringFromClass([view class]);
    if ([className containsString:@"Button"] || [className containsString:@"Cell"] || [className containsString:@"Card"]) {
        if ([view respondsToSelector:@selector(setTintColor:)]) {
            view.tintColor = [UIColor whiteColor];
        }
    }

    // Safely recurse into subviews without creating infinite tracking cycles
    for (UIView *subview in view.subviews) {
        [BumblePrecisionDarkEngine darkenProfileInterfaceLayer:subview];
    }
}
@end

// ============================================================================
// STRUCTURAL RUNTIME HOOKS
// ============================================================================
__attribute__((constructor))
static void init(void) {
    @autoreleasepool {
        // Run deep styling scan when the application window registers active states
        [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidBecomeActiveNotification
                                                          object:nil
                                                           queue:[NSOperationQueue mainQueue]
                                                      usingBlock:^(NSNotification * _Nonnull note) {
            UIWindow *window = nil;
            if (@available(iOS 13.0, *)) {
                for (UIScene *scene in [UIApplication sharedApplication].connectedScenes) {
                    if (scene.activationState == UISceneActivationStateForegroundActive && [scene isKindOfClass:[UIWindowScene class]]) {
                        UIWindowScene *ws = (UIWindowScene *)scene;
                        for (UIWindow *w in ws.windows) {
                            if (w.isKeyWindow) { window = w; break; }
                        }
                    }
                }
            }
            if (!window) {
                #pragma clang diagnostic push
                #pragma clang diagnostic ignored "-Wdeprecated-declarations"
                window = [UIApplication sharedApplication].keyWindow;
                #pragma clang diagnostic pop
            }
            
            if (window) {
                if (@available(iOS 13.0, *)) {
                    window.overrideUserInterfaceStyle = UIUserInterfaceStyleDark;
                }
                [BumblePrecisionDarkEngine darkenProfileInterfaceLayer:window];
            }
        }];

        // Hook view controller loading sequence to execute coloring smoothly before layouts show up
        Class vcClass = [UIViewController class];
        SEL viewWillAppearSel = @selector(viewWillAppear:);
        __block IMP originalViewWillAppear = NULL;
        
        id block = ^(void *self, BOOL animated) {
            if (originalViewWillAppear) {
                ((void (*)(void *, BOOL))originalViewWillAppear)(self, animated);
            }
            UIViewController *vc = (__bridge UIViewController *)self;
            if (vc.view) {
                [BumblePrecisionDarkEngine darkenProfileInterfaceLayer:vc.view];
            }
        };
        
        IMP newViewWillAppear = imp_implementationWithBlock(block);
        Method origMethod = class_getInstanceMethod(vcClass, viewWillAppearSel);
        originalViewWillAppear = method_setImplementation(origMethod, newViewWillAppear);
    }
}
