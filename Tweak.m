#import <UIKit/UIKit.h>
#import <LocalAuthentication/LocalAuthentication.h>

@interface BumbleLockManager : NSObject
+ (void)runVerification;
@end

@implementation BumbleLockManager

static UIView *shieldView = nil;

+ (void)runVerification {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIWindow *window = [UIApplication sharedApplication].keyWindow;
        if (!window) return;

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

        LAContext *context = [[LAContext alloc] init];
        NSError *error = nil;

        if ([context canEvaluatePolicy:LAPolicyDeviceOwnerAuthentication error:&error]) {
            [context evaluatePolicy:LAPolicyDeviceOwnerAuthentication
                    localizedReason:@"Unlock Bumble to protect your privacy"
                              reply:^(BOOL success, NSError * _Nullable error) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (success) {
                        [UIView animateWithDuration:0.25 animations:^{
                            shieldView.alpha = 0;
                        } completion:^(BOOL finished) {
                            [shieldView removeFromSuperview];
                            shieldView = nil;
                        }];
                    } else {
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
            [shieldView removeFromSuperview];
            shieldView = nil;
        }
    });
}
@end

__attribute__((constructor))
static void init(void) {
    @autoreleasepool {
        [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidFinishLaunchingNotification
                                                          object:nil
                                                           queue:[NSOperationQueue mainQueue]
                                                      usingBlock:^(NSNotification * _Nonnull note) {
            [BumbleLockManager runVerification];
        }];

        [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidBecomeActiveNotification
                                                          object:nil
                                                           queue:[NSOperationQueue mainQueue]
                                                      usingBlock:^(NSNotification * _Nonnull note) {
            [BumbleLockManager runVerification];
        }];
    }
}
