#import <UIKit/UIKit.h>
#import <objc/runtime.h>

@interface BumbleDarkManager : NSObject
+ (void)applyDarkThemeToView:(UIView *)view;
@end

@implementation BumbleDarkManager

+ (void)applyDarkThemeToView:(UIView *)view {
    if (!view) return;

    // 1. Invert white or bright backgrounds to dark grey / black
    if (view.backgroundColor) {
        CGFloat red = 0, green = 0, blue = 0, alpha = 0;
        [view.backgroundColor getRed:&red green:&green blue:&blue alpha:&alpha];
        
        // If background is white or close to white, make it dark midnight grey
        if (red > 0.85 && green > 0.85 && blue > 0.85) {
            view.backgroundColor = [UIColor colorWithRed:20.0/255.0 green:20.0/255.0 blue:20.0/255.0 alpha:alpha];
        }
    }

    // 2. Invert dark text to pure white so it remains legible
    if ([view isKindOfClass:[UILabel class]]) {
        UILabel *label = (UILabel *)view;
        CGFloat red = 0, green = 0, blue = 0, alpha = 0;
        [label.textColor getRed:&red green:&green blue:&blue alpha:&alpha];
        
        // If text color is black or dark grey, flip it to pure white
        if (red < 0.3 && green < 0.3 && blue < 0.3) {
            label.textColor = [UIColor whiteColor];
        }
    }

    // 3. Handle standard text fields and inputs
    if ([view isKindOfClass:[UITextField class]]) {
        UITextField *field = (UITextField *)view;
        field.backgroundColor = [UIColor colorWithRed:35.0/255.0 green:35.0/255.0 blue:35.0/255.0 alpha:1.0];
        field.textColor = [UIColor whiteColor];
    }

    // Recursively dive into child views to apply formatting system-wide
    for (UIView *subview in view.subviews) {
        [BumbleDarkManager applyDarkThemeToView:subview];
    }
}
@end

// ============================================================================
// RUNTIME VIEW CONTROLLER HOOKS
// ============================================================================
__attribute__((constructor))
static void init(void) {
    @autoreleasepool {
        // Intercept every view panel right before it displays on screen
        [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidBecomeActiveNotification
                                                          object:nil
                                                           queue:[NSOperationQueue mainQueue]
                                                      usingBlock:^(NSNotification * _Nonnull note) {
            UIWindow *window = [UIApplication sharedApplication].keyWindow;
            if (window) {
                [BumbleDarkManager applyDarkThemeToView:window];
            }
        }];
        
        // Setup hooks into the layout subviews engine to handle scrolling transformations
        Class viewClass = [UIView class];
        SEL layoutSelector = @selector(layoutSubviews);
        __block IMP originalLayoutSubviews = NULL;
        
        id block = ^(void *self) {
            if (originalLayoutSubviews) {
                ((void (*)(void *))originalLayoutSubviews)(self);
            }
            // Run the deep darkening scan whenever objects rearrange or scroll
            UIView *currentView = (__bridge UIView *)self;
            [BumbleDarkManager applyDarkThemeToView:currentView];
        };
        
        IMP newLayoutSubviews = imp_implementationWithBlock(block);
        Method origMethod = class_getInstanceMethod(viewClass, layoutSelector);
        originalLayoutSubviews = method_setImplementation(origMethod, newLayoutSubviews);
    }
}
