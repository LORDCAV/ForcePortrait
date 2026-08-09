#import <UIKit/UIKit.h>
#import <LocalAuthentication/LocalAuthentication.h>

@interface BumbleLockManager : NSObject
+ (void)runVerification;
@end

@implementation BumbleLockManager

static UIView *shieldView = nil;
static BOOL isProcessingAuth = NO;

+ (void)runVerification {
    dispatch_async(dispatch_get_main_queue(), ^{
        // Safety lock: if already processing a scan, do not launch another one
        if (isProcessingAuth) return;
        
        UIWindow *window = nil;
        if (@available(iOS 13.0, *)) {
            for (UIScene *scene in [UIApplication sharedApplication].connectedScenes) {
                if (scene.activationState == UISceneActivationStateForegroundActive && [scene isKindOfClass:[UIWindowScene class]]) {
                    UIWindowScene *windowScene = (UIWindowScene *)scene;
                    for (UIWindow *w in windowScene.windows) {
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
        
        if (!window) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [BumbleLockManager runVerification];
            });
            return;
        }

        // 1. Instantly pin the black privacy screen to hide your profiles
        if (!shieldView) {
            shieldView = [[UIView alloc] initWithFrame:window.bounds];
            shieldView.backgroundColor = [UIColor blackColor];
            
            UIView *dot = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 80, 80)];
            dot.center = shieldView.center;
            dot.backgroundColor = [UIColor colorWithRed:255.0/255.0 green:204.0/255.0 blue:0.0/255.0 alpha:1.0];
            dot.layer.cornerRadius = 40;
            [shieldView addSubview:dot];
        }

        if (!shieldView.superview) {
            [window addSubview:shieldView];
            [window bringSubviewToFront:shieldView];
        }

        // 2. Fire the Face ID request cleanly
        isProcessingAuth = YES;
        LAContext *context = [[LAContext alloc] init];
        NSError *error = nil;

        if ([context canEvaluatePolicy:LAPolicyDeviceOwnerAuthentication error:&error]) {
            [context evaluatePolicy:LAPolicyDeviceOwnerAuthentication
                    localizedReason:@"Unlock Bumble to protect your privacy"
                              reply:^(BOOL success, NSError * _Nullable error) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (success) {
                        // Success: Fade out the privacy wall and unlock the processing flag
                        [UIView animateWithDuration:0.25 animations:^{
                            shieldView.alpha = 0;
                        } completion:^(BOOL finished) {
                            [shieldView removeFromSuperview];
                            shieldView = nil;
                            isProcessingAuth = NO;
                        }];
                    } else {
                        // Failed/Canceled: Keep the flag locked so it can't loop, show try again button
                        isProcessingAuth = NO;
                        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Locked"
                                                                                       message:@"Authentication required to access Bumble."
                                                                                preferredStyle:UIAlertControllerStyleAlert];
                        [alert addAction:[UIAlertAction actionWithTitle:@"Try Again" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                            [BumbleLockManager runVerification];
                        }]];
                        [[window rootViewController] presentViewController:alert animated:YES completion:nil];
                    }
                });
            }];
        } else {
            isProcessingAuth = NO;
            [shieldView removeFromSuperview];
            shieldView = nil;
        }
    });
}
@end

// ============================================================================
// CLEAN INITIALIZATION ENTRY
// ============================================================================
__attribute__((constructor))
static void init(void) {
    @autoreleasepool {
        // Only trigger on clean cold launch to prevent multi-tasking overlay loops
        [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidFinishLaunchingNotification
                                                          object:nil
                                                           queue:[NSOperationQueue mainQueue]
                                                      usingBlock:^(NSNotification * _Nonnull note) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [BumbleLockManager runVerification];
            });
        }];
    }
}
