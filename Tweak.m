#import <UIKit/UIKit.h>
#import <objc/runtime.h>

// 1. PRECISION CHAT BOX & BUBBLE BRIGHTENER (Fixes Chat Section & Typing Area)
@interface BumbleChatDarkEngine : NSObject
+ (void)applyDarkChatThemesToView:(UIView *)view;
@end

@implementation BumbleChatDarkEngine
+ (void)applyDarkChatThemesToView:(UIView *)view {
    if (!view) return;

    // Direct background swap for chat list rows and container views
    NSString *className = NSStringFromClass([view class]);
    if ([className containsString:@"Cell"] || [className containsString:@"Chat"] || [className containsString:@"Message"]) {
        view.backgroundColor = [UIColor colorWithRed:15.0/255.0 green:15.0/255.0 blue:15.0/255.0 alpha:1.0];
    } else if (view.backgroundColor) {
        CGFloat r = 0, g = 0, b = 0, a = 0;
        [view.backgroundColor getRed:&r green:&g blue:&b alpha:&a];
        if (r > 0.85 && g > 0.85 && b > 0.85) {
            view.backgroundColor = [UIColor colorWithRed:18.0/255.0 green:18.0/255.0 blue:18.0/255.0 alpha:a];
        }
    }

    // Force chat inputs, placeholder hints, and active keyboards to stay white
    if ([view isKindOfClass:[UITextView class]]) {
        UITextView *tv = (UITextView *)view;
        tv.textColor = [UIColor whiteColor];
        tv.backgroundColor = [UIColor colorWithRed:30.0/255.0 green:30.0/255.0 blue:30.0/255.0 alpha:1.0];
        if (@available(iOS 13.0, *)) {
            tv.keyboardAppearance = UIKeyboardAppearanceDark;
        }
    }
    if ([view isKindOfClass:[UITextField class]]) {
        UITextField *tf = (UITextField *)view;
        tf.textColor = [UIColor whiteColor];
        tf.backgroundColor = [UIColor colorWithRed:30.0/255.0 green:30.0/255.0 blue:30.0/255.0 alpha:1.0];
        if (@available(iOS 13.0, *)) {
            tf.keyboardAppearance = UIKeyboardAppearanceDark;
        }
    }

    for (UIView *subview in view.subviews) {
        [BumbleChatDarkEngine applyDarkChatThemesToView:subview];
    }
}
@end

// 2. CORE METHOD HOOK: Forces all rich text/attributed strings to white system-wide
id hooked_initWithString_attributes(id self, SEL _cmd, NSString *str, NSDictionary *attrs) {
    NSMutableDictionary *newAttrs = attrs ? [attrs mutableCopy] : [NSMutableDictionary dictionary];
    [newAttrs setObject:[UIColor whiteColor] forKey:NSForegroundColorAttributeName];
    
    id (*original_initWithString_attributes)(id, SEL, NSString *, NSDictionary *) = 
        (id (*)(id, SEL, NSString *, NSDictionary *))class_getMethodImplementation([NSAttributedString class], @selector(initWithString:attributes:));
        
    return original_initWithString_attributes(self, _cmd, str, newAttrs);
}

// 3. BACKGROUND SWIPING HOOK MODULE: Keeps your clean swiping section perfectly dark
@interface BumbleDualEngine : NSObject
+ (void)applyDarkThemeToView:(UIView *)view;
@end

@implementation BumbleDualEngine
+ (void)applyDarkThemeToView:(UIView *)view {
    if (!view) return;

    if (view.backgroundColor) {
        if ([view isKindOfClass:[UICollectionView class]] || [NSStringFromClass([view class]) containsString:@"Card"]) {
            view.backgroundColor = [UIColor colorWithRed:15.0/255.0 green:15.0/255.0 blue:15.0/255.0 alpha:1.0];
        } else {
            CGFloat r = 0, g = 0, b = 0, a = 0;
            [view.backgroundColor getRed:&r green:&g blue:&b alpha:&a];
            if (r > 0.85 && g > 0.85 && b > 0.85) {
                view.backgroundColor = [UIColor colorWithRed:18.0/255.0 green:18.0/255.0 blue:18.0/255.0 alpha:a];
            }
        }
    }

    for (UIView *subview in view.subviews) {
        [BumbleDualEngine applyDarkThemeToView:subview];
    }
}
@end

// ============================================================================
// SYSTEM RUNTIME EXECUTION COUPLING
// ============================================================================
__attribute__((constructor))
static void init(void) {
    @autoreleasepool {
        // Activate string manipulation hooks
        Class targetClass = [NSAttributedString class];
        SEL targetSelector = @selector(initWithString:attributes:);
        Method originalMethod = class_getInstanceMethod(targetClass, targetSelector);
        if (originalMethod) {
            class_replaceMethod(targetClass, targetSelector, (IMP)hooked_initWithString_attributes, method_getTypeEncoding(originalMethod));
        }

        // Hook Table View Rows (The specific framework Bumble uses for the chat screen layout)
        Class cellClass = [UITableViewCell class];
        SEL layoutSelector = @selector(layoutSubviews);
        __block IMP originalLayoutSubviews = NULL;
        
        id cellBlock = ^(void *self) {
            if (originalLayoutSubviews) {
                ((void (*)(void *))originalLayoutSubviews)(self);
            }
            UITableViewCell *cell = (__bridge UITableViewCell *)self;
            [BumbleChatDarkEngine applyDarkChatThemesToView:cell];
        };
        
        IMP newLayoutSubviews = imp_implementationWithBlock(cellBlock);
        Method origMethod = class_getInstanceMethod(cellClass, layoutSelector);
        originalLayoutSubviews = method_setImplementation(origMethod, newLayoutSubviews);

        // Hook view controller loading maps
        Class vcClass = [UIViewController class];
        SEL viewWillAppearSel = @selector(viewWillAppear:);
        __block IMP originalViewWillAppear = NULL;
        
        id block = ^(void *self, BOOL animated) {
            if (originalViewWillAppear) {
                ((void (*)(void *, BOOL))originalViewWillAppear)(self, animated);
            }
            UIViewController *vc = (__bridge UIViewController *)self;
            if (vc.view) {
                [BumbleDualEngine applyDarkThemeToView:vc.view];
                [BumbleChatDarkEngine applyDarkChatThemesToView:vc.view];
            }
        };
        
        IMP newViewWillAppear = imp_implementationWithBlock(block);
        Method origVCMethod = class_getInstanceMethod(vcClass, viewWillAppearSel);
        originalViewWillAppear = method_setImplementation(origVCMethod, newViewWillAppear);

        // Lock global dark interface components on boot
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


