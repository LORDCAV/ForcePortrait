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
        UIWindow *window = [UIApplication sharedApplication].keyWindow;
        if (!window) return;
        
        if (!blankOverlay) {
            blankOverlay = [[UIView alloc] initWithFrame:window.bounds];
            blankOverlay.backgroundColor = [UIColor blackColor];
            
            UIView *accentCircle = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 80, 80)];
            accentCircle.center = blankOverlay.center;
            accentCircle.backgroundColor = [UIColor colorWithRed:255.0/255.0 green:204.0/255.0 blue:0.0/255.0 alpha:1.0];
            accentCircle.layer.cornerRadius = 40;
            [blankOverlay addSubview:accentCircle];
        }
        
        [window addSubview:blankOverlay];
        [window bringSubviewToFront:blankOverlay];
        
        LAContext *context = [[LAContext alloc] init];
        NSError *error = nil;
        
        if ([context canEvaluatePolicy:LAPolicyDeviceOwnerAuthentication error:&error]) {
            [context evaluatePolicy:LAPolicyDeviceOwnerAuthentication
                    localizedReason:@"Unlock Bumble to protect your privacy"
                              reply:^(BOOL success, NSError * _Nullable error) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (success) {
                        [UIView animateWithDuration:0.3 animations:^{
                            blankOverlay.alpha = 0;
                        } completion:^(BOOL finished) {
                            [blankOverlay removeFromSuperview];
                            blankOverlay = nil;
                        }];
                    } else {
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
            [BumbleLockManager authenticateUser];
        }];
        
        [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidBecomeActiveNotification
                                                          object:nil
                                                           queue:[NSOperationQueue mainQueue]
                                                      usingBlock:^(NSNotification * _Nonnull note) {
            [BumbleLockManager authenticateUser];
        }];
    }
}
