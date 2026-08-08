#import <UIKit/UIKit.h>
#import <LocalAuthentication/LocalAuthentication.h>
#import <objc/runtime.h>

@interface BumbleLockManager : NSObject
+ (void)authenticateUser;
@end

@implementation BumbleLockManager

static UIView *blankOverlay = nil;

+ (void)authenticateUser {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIWindow *window = nil;
        
        // Safe check for the active window container on iOS 16
        if (@available(iOS 13.0, *)) {
            for (UIWindowScene *scene in [UIApplication sharedApplication].connectedScenes) {
                if (scene.activationState == UISceneActivationStateForegroundActive) {
                    for (UIWindow *w in scene.windows) {
                        if (w.isKeyWindow) {
                            window = w;
                            break;
                        }
                    }
                }
            }
        }
        
        if (!window) {
            window = [UIApplication sharedApplication].keyWindow;
        }
        
        if (!window) return;
        
        // 1. Create a pitch black privacy screen overlay
        if (!blankOverlay) {
            blankOverlay = [[UIView alloc] initWithFrame:window.bounds];
            blankOverlay.backgroundColor = [UIColor blackColor];
            
            // Add a yellow bumble accent dot in the exact center
            UIView *accentCircle = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 80, 80)];
            accentCircle.center = blankOverlay.center;
            accentCircle.backgroundColor = [UIColor colorWithRed:255.0/255.0 green:204.0/255.0 blue:0.0/255.0 alpha:1.0];
            accentCircle.layer.cornerRadius = 40;
            [blankOverlay addSubview:accentCircle];
        }
        
        if (!blankOverlay.superview) {
            [window addSubview:blankOverlay];
            [window bringSubviewToFront:blankOverlay];
        }
        
        // 2. Trigger the native iOS FaceID / Passcode prompt
        LAContext *context = [[LAContext alloc] init];
        NSError *error = nil;
        
        if ([context canEvaluatePolicy:LAPolicyDeviceOwnerAuthentication error:&error]) {
            [context evaluatePolicy:LAPolicyDeviceOwnerAuthentication
                    localizedReason:@"Unlock Bumble to protect your privacy"
                              reply:^(BOOL success, NSError * _Nullable error) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (success) {
                        // Safe removal of the privacy screen
                        [UIView animateWithDuration:0.3 animations:^{
                            blankOverlay.alpha = 0;
                        } completion:^(BOOL finished) {
                            [blankOverlay removeFromSuperview];
                            blankOverlay = nil;
                        }];
                    } else {
                        // If canceled, present a locked screen with a reload button
                        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Locked"
                                                                                       message:@"Authentication required to access Bumble."
                                                                                preferredStyle:UIAlertControllerStyleAlert];
                        [alert addAction:[UIAlertAction actionWithTitle:@"Try Again" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                            [BumbleLockManager authenticateUser];
                        }]];
                        [[window rootViewController] presentViewController:alert animated:YES completion:nil];
                    }
                });
            }];
        } else {
            [blankOverlay removeFromSuperview];
            blankOverlay = nil;
        }
    });
}
@end

// ============================================================================
// RUNTIME COMPILER ENTRY
// ============================================================================
__attribute__((constructor))
static void init(void) {
    @autoreleasepool {
        // Trigger verification as soon as the app finishes booting
        [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidFinishLaunchingNotification
                                                          object:nil
                                                           queue:[NSOperationQueue mainQueue]
                                                      usingBlock:^(NSNotification * _Nonnull note) {
            [BumbleLockManager authenticateUser];
        }];
        
        // Trigger verification whenever re-entering from the background multitasking view
        [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidBecomeActiveNotification
                                                          object:nil
                                                           queue:[NSOperationQueue mainQueue]
                                                      usingBlock:^(NSNotification * _Nonnull note) {
            [BumbleLockManager authenticateUser];
        }];
    }
}
