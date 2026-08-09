#import <UIKit/UIKit.h>
#import <objc/runtime.h>

@interface BumblePersistentDarkEngine : NSObject
+ (void)applyThemeToView:(UIView *)view;
@end

@implementation BumblePersistentDarkEngine

+ (void)applyThemeToView:(UIView *)view {
    if (!view) return;

    // 1. Instantly capture bright backgrounds and force them dark midnight grey
    if (view.backgroundColor) {
        CGFloat r = 0, g = 0, b = 0, a = 0;
        [view.backgroundColor getRed:&r green:&g blue:&b alpha:&a];
        if (r > 0.85 && g > 0.85 && b > 0.85) {
            view.backgroundColor = [UIColor colorWithRed:18.0/255.0 green:18.0/255.0 blue:18.0/255.0 alpha:a];
        }
    }

    // 2. Overwrite rich text attributes (About Me, Location, Badges)
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
                if (!(r > 0.6 && g > 0.5 && b < 0.2)) {
                    label.textColor = [UIColor whiteColor];
                }
            }
        }
    }

    // 3. Keep SwiftUI / Canvas components forced to use white text assets
    NSString *className = NSStringFromClass([view class]);
    if ([className containsString:@"Button"] || [className containsString:@"Cell"] || [className containsString:@"Card"]) {
        if ([view respondsToSelector:@selector(setTintColor:)]) {
            view.tintColor = [UIColor whiteColor];
        }
    }

    // Safely look into subviews
    for (UIView *subview in view.subviews) {
        [BumblePersistentDarkEngine applyThemeToView:subview];
    }
}
@end

// ============================================================================
// CONTINUOUS BACKGROUND HOOKS
// ============================================================================
__attribute__((constructor))
static void init(void) {
    @autoreleasepool {
        // Core layout heartbeat hook (Triggers every time the app updates a card or scrolls)
        Class viewClass = [UIView class];
        SEL layoutSelector = @selector(layoutSubviews);
        __block IMP originalLayoutSubviews = NULL;
        
        id block = ^(void *self) {
            if (originalLayoutSubviews) {
                ((void (*)(void *))originalLayoutSubviews)(self);
            }
            UIView *currentView = (__bridge UIView *)self;
            // Instantly darken any newly recycled or generated cards on the fly
            [BumblePersistentDarkEngine applyThemeToView:currentView];
        };
        
        IMP newLayoutSubviews = imp_implementationWithBlock(block);
        Method origMethod = class_getInstanceMethod(viewClass, layoutSelector);
        originalLayoutSubviews = method_setImplementation(origMethod, newLayoutSubviews);
    }
}
