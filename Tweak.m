#import <UIKit/UIKit.h>
#import <objc/runtime.h>

// Global replacement function that forces rich text color variables to pure white
id hooked_initWithString_attributes(id self, SEL _cmd, NSString *str, NSDictionary *attrs) {
    NSMutableDictionary *newAttrs = attrs ? [attrs mutableCopy] : [NSMutableDictionary dictionary];
    
    // Intercept the foreground text color layer key and override it to white
    [newAttrs setObject:[UIColor whiteColor] forKey:NSForegroundColorAttributeName];
    
    // Pass the modified high-contrast attribute layout back to the original engine
    id (*original_initWithString_attributes)(id, SEL, NSString *, NSDictionary *) = 
        (id (*)(id, SEL, NSString *, NSDictionary *))class_getMethodImplementation([NSAttributedString class], @selector(initWithString:attributes:));
        
    return original_initWithString_attributes(self, _cmd, str, newAttrs);
}

// ============================================================================
// METHOD HOOKING INITIALIZATION RUNTIME
// ============================================================================
__attribute__((constructor))
static void init(void) {
    @autoreleasepool {
        // Target Apple's core rich text initialization layout engine
        Class targetClass = [NSAttributedString class];
        SEL targetSelector = @selector(initWithString:attributes:);
        
        Method originalMethod = class_getInstanceMethod(targetClass, targetSelector);
        if (originalMethod) {
            // Hot-swap the app's default text coloring function with our white text modifier
            class_replaceMethod(targetClass, targetSelector, (IMP)hooked_initWithString_attributes, method_getTypeEncoding(originalMethod));
        }

        // Keep the global system interface background dark mode preset locked safely on boot
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

