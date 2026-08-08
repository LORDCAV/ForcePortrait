#import <UIKit/UIKit.h>
#import <objc/runtime.h>

UIInterfaceOrientationMask custom_supportedInterfaceOrientations(id self, SEL _cmd) {
    return UIInterfaceOrientationMaskPortrait;
}

UIInterfaceOrientation custom_preferredInterfaceOrientationForPresentation(id self, SEL _cmd) {
    return UIInterfaceOrientationPortrait;
}

BOOL custom_shouldAutorotate(id self, SEL _cmd) {
    return YES;
}

__attribute__((constructor))
static void init(void) {
    @autoreleasepool {
        Class class = [UIViewController class];
        
        Method method1 = class_getInstanceMethod(class, @selector(supportedInterfaceOrientations));
        class_replaceMethod(class, @selector(supportedInterfaceOrientations), (IMP)custom_supportedInterfaceOrientations, method_getTypeEncoding(method1));
        
        Method method2 = class_getInstanceMethod(class, @selector(preferredInterfaceOrientationForPresentation));
        class_replaceMethod(class, @selector(preferredInterfaceOrientationForPresentation), (IMP)custom_preferredInterfaceOrientationForPresentation, method_getTypeEncoding(method2));
        
        Method method3 = class_getInstanceMethod(class, @selector(shouldAutorotate));
        class_replaceMethod(class, @selector(shouldAutorotate), (IMP)custom_shouldAutorotate, method_getTypeEncoding(method3));
    }
}
