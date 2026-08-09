#import <UIKit/UIKit.h>
#import <objc/runtime.h>

// 1. ADVANCED METHOD HOOK: Forces all rich text/attributed strings to white
id hooked_initWithString_attributes(id self, SEL _cmd, NSString *str, NSDictionary *attrs) {
    NSMutableDictionary *newAttrs = attrs ? [attrs mutableCopy] : [NSMutableDictionary dictionary];
    [newAttrs setObject:[UIColor whiteColor] forKey:NSForegroundColorAttributeName];
    
    id (*original_initWithString_attributes)(id, SEL, NSString *, NSDictionary *) = 
        (id (*)(id, SEL, NSString *, NSDictionary *))class_getMethodImplementation([NSAttributedString class], @selector(initWithString:attributes:));
        
    return original_initWithString_attributes(self, _cmd, str, newAttrs);
}

// 2. BACKGROUND HOOK MODULE: Darkens layout backgrounds safely as they load
@interface BumbleDualEngine : NSObject
+ (void)applyDarkThemeToView:(UIView *)view;
@end

@implementation BumbleDualEngine
+ (void)applyDarkThemeToView:(UIView *)view {
    if (!view) return;

    if (view.backgroundColor) {
        CGFloat r = 0, g = 0, b = 0, a = 0;
        [view.backgroundColor getRed:&r green:&g blue:&b alpha:&a];
        // Target bright or pure white container walls and change them to deep dark midnight grey
        if (r > 0.85 && g > 0.85 && b > 0.85) {
            view.backgroundColor = [UIColor colorWithRed:18.0/255.0 green:18.0/255.0 blue:18.0/255.0 alpha:a];
        }
    }

    for (UIView *subview in view.subviews) {
        [BumbleDualEngine applyDarkThemeToView:subview];
    }
}
@end

// ============================================================================
// SYSTEM ARCHITECTURE RUNTIME COUPLING
// ============================================================================
__attribute__((constructor))
static void init(void) {
    @autoreleasepool {
        // Activate the white text modification hook
        Class targetClass = [NSAttributedString class];
        SEL targetSelector = @selector(initWithString:attributes:);
        Method originalMethod = class_getInstanceMethod(targetClass, targetSelector);
        if (originalMethod) {
            class_replaceMethod(targetClass, targetSelector, (IMP)hooked_initWithString_attributes, method_getTypeEncoding(originalMethod));
        }

        // Hook view controller loading sequence to execute background coloring before panels show up
        Class vcClass = [UIViewController class];
        SEL viewWillAppearSel = @selector(viewWillAppear:);
        __block IMP originalViewWillAppear = NULL;
        
        id block = ^(void *self, BOOL animated) {
            if (originalViewWillAppear) {
                ((void (*)(void *, BOOL))originalViewWillAppear)(self, animated);
            }
            UIViewController *vc = (__bridge UIViewController *)self;
            if (vc.view) {
                // Apply the dark theme layers immediately to the view container canvas
                [BumbleDualEngine applyDarkThemeToView:vc.view];
            }
        };
        
        IMP newViewWillAppear = imp_implementationWithBlock(block);
        Method origMethod = class_getInstanceMethod(vcClass, viewWillAppearSel);
        originalViewWillAppear = method_setImplementation(origMethod, newViewWillAppear);

        // Lock global dark interface style elements on boot
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

