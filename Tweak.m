#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import <dlfcn.h>

// Override UIKit responses
UIInterfaceOrientationMask custom_supportedInterfaceOrientations(id self, SEL _cmd) {
    return UIInterfaceOrientationMaskPortrait;
}

UIInterfaceOrientation custom_preferredInterfaceOrientationForPresentation(id self, SEL _cmd) {
    return UIInterfaceOrientationPortrait;
}

BOOL custom_shouldAutorotate(id self, SEL _cmd) {
    return YES;
}

// Force engine configuration requests to yield portrait values (Value 1 = Portrait)
int custom_UnityGetTargetDesiredOrientation() {
    return 1; 
}

__attribute__((constructor))
static void init(void) {
    @autoreleasepool {
        // 1. Hook the standard iOS base views
        Class class = [UIViewController class];
        
        Method method1 = class_getInstanceMethod(class, @selector(supportedInterfaceOrientations));
        class_replaceMethod(class, @selector(supportedInterfaceOrientations), (IMP)custom_supportedInterfaceOrientations, method_getTypeEncoding(method1));
        
        Method method2 = class_getInstanceMethod(class, @selector(preferredInterfaceOrientationForPresentation));
        class_replaceMethod(class, @selector(preferredInterfaceOrientationForPresentation), (IMP)custom_preferredInterfaceOrientationForPresentation, method_getTypeEncoding(method2));
        
        Method method3 = class_getInstanceMethod(class, @selector(shouldAutorotate));
        class_replaceMethod(class, @selector(shouldAutorotate), (IMP)custom_shouldAutorotate, method_getTypeEncoding(method3));
        
        // 2. Intercept Unity's specific internal C-function mapping 
        void *unity_func = dlsym(RTLD_DEFAULT, "UnityGetTargetDesiredOrientation");
        if (unity_func != NULL) {
            // Rebind the function pointer to force return values internally
            class_replaceMethod(class, NSSelectorFromString(@"updateOrientation:"), (IMP)custom_UnityGetTargetDesiredOrientation, "v@:i");
        }
    }
}
