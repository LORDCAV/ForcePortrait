#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <objc/runtime.h>

// ============================================================
//  COLOR DEFINITIONS
// ============================================================
#define OLED_BLACK      [UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:1.0]
#define DARK_GRAY       [UIColor colorWithRed:0.12 green:0.12 blue:0.12 alpha:1.0]
#define CARD_GRAY       [UIColor colorWithRed:0.18 green:0.18 blue:0.18 alpha:1.0]
#define MEDIUM_GRAY     [UIColor colorWithRed:0.3 green:0.3 blue:0.3 alpha:1.0]
#define TEXT_WHITE      [UIColor colorWithRed:0.95 green:0.95 blue:0.95 alpha:1.0]
#define TEXT_LIGHT      [UIColor colorWithRed:0.8 green:0.8 blue:0.8 alpha:1.0]
#define ACCENT_YELLOW   [UIColor colorWithRed:1.0 green:0.8 blue:0.0 alpha:1.0]

static BOOL isDarkModeEnabled = YES;

// ============================================================
//  HELPER: Check if color is light
// ============================================================
static BOOL isLightColor(UIColor *color) {
    if (!color) return NO;
    CGFloat red, green, blue, alpha;
    [color getRed:&red green:&green blue:&blue alpha:&alpha];
    CGFloat brightness = (red + green + blue) / 3.0;
    return brightness > 0.5;
}

// ============================================================
//  MAIN ENTRY POINT
// ============================================================
%ctor {
    NSLog(@"[BumbleDarkMode] Dark mode dylib loaded!");
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        @try {
            UIWindow *keyWindow = [UIApplication sharedApplication].keyWindow;
            if (keyWindow) {
                keyWindow.backgroundColor = OLED_BLACK;
            }
        } @catch (NSException *exception) {
            NSLog(@"[BumbleDarkMode] Error: %@", exception);
        }
    });
}

// ============================================================
//  HOOK: UITableView - Dark Mode
// ============================================================
%hook UITableView

- (instancetype)initWithFrame:(CGRect)frame style:(UITableViewStyle)style {
    UITableView *table = %orig(frame, style);
    @try {
        if (isDarkModeEnabled) {
            table.backgroundColor = OLED_BLACK;
            table.separatorColor = MEDIUM_GRAY;
        }
    } @catch (NSException *exception) {
        NSLog(@"[BumbleDarkMode] Error: %@", exception);
    }
    return table;
}

- (void)setBackgroundColor:(UIColor *)color {
    @try {
        if (isDarkModeEnabled && isLightColor(color)) {
            %orig(OLED_BLACK);
            return;
        }
    } @catch (NSException *exception) {
        // Ignore
    }
    %orig(color);
}

%end

// ============================================================
//  HOOK: UITableViewCell - Dark Cells
// ============================================================
%hook UITableViewCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    UITableViewCell *cell = %orig(style, reuseIdentifier);
    @try {
        if (isDarkModeEnabled) {
            cell.backgroundColor = CARD_GRAY;
            cell.textLabel.textColor = TEXT_WHITE;
            cell.detailTextLabel.textColor = TEXT_LIGHT;
        }
    } @catch (NSException *exception) {
        NSLog(@"[BumbleDarkMode] Error: %@", exception);
    }
    return cell;
}

- (void)setBackgroundColor:(UIColor *)color {
    @try {
        if (isDarkModeEnabled && isLightColor(color)) {
            %orig(CARD_GRAY);
            return;
        }
    } @catch (NSException *exception) {
        // Ignore
    }
    %orig(color);
}

%end

// ============================================================
//  HOOK: UINavigationBar - Dark Mode
// ============================================================
%hook UINavigationBar

- (instancetype)initWithFrame:(CGRect)frame {
    UINavigationBar *nav = %orig(frame);
    @try {
        if (isDarkModeEnabled) {
            nav.barTintColor = OLED_BLACK;
            nav.backgroundColor = OLED_BLACK;
            nav.tintColor = ACCENT_YELLOW;
            nav.titleTextAttributes = @{NSForegroundColorAttributeName: TEXT_WHITE};
            if (@available(iOS 13.0, *)) {
                UINavigationBarAppearance *appearance = [[UINavigationBarAppearance alloc] init];
                appearance.backgroundColor = OLED_BLACK;
                appearance.titleTextAttributes = @{NSForegroundColorAttributeName: TEXT_WHITE};
                nav.standardAppearance = appearance;
                nav.scrollEdgeAppearance = appearance;
            }
        }
    } @catch (NSException *exception) {
        NSLog(@"[BumbleDarkMode] Error: %@", exception);
    }
    return nav;
}

%end

// ============================================================
//  HOOK: UITabBar - Dark Mode
// ============================================================
%hook UITabBar

- (instancetype)initWithFrame:(CGRect)frame {
    UITabBar *tabBar = %orig(frame);
    @try {
        if (isDarkModeEnabled) {
            tabBar.barTintColor = OLED_BLACK;
            tabBar.backgroundColor = OLED_BLACK;
            tabBar.tintColor = ACCENT_YELLOW;
            if (@available(iOS 13.0, *)) {
                UITabBarAppearance *appearance = [[UITabBarAppearance alloc] init];
                appearance.backgroundColor = OLED_BLACK;
                tabBar.standardAppearance = appearance;
                tabBar.scrollEdgeAppearance = appearance;
            }
        }
    } @catch (NSException *exception) {
        NSLog(@"[BumbleDarkMode] Error: %@", exception);
    }
    return tabBar;
}

%end

// ============================================================
//  HOOK: UILabel - Force White Text
// ============================================================
%hook UILabel

- (void)setTextColor:(UIColor *)color {
    @try {
        if (isDarkModeEnabled && isLightColor(color)) {
            %orig(TEXT_WHITE);
            return;
        }
    } @catch (NSException *exception) {
        // Ignore
    }
    %orig(color);
}

%end

// ============================================================
//  HOOK: UITextView - Dark Background
// ============================================================
%hook UITextView

- (instancetype)initWithFrame:(CGRect)frame textContainer:(NSTextContainer *)textContainer {
    UITextView *textView = %orig(frame, textContainer);
    @try {
        if (isDarkModeEnabled) {
            textView.backgroundColor = DARK_GRAY;
            textView.textColor = TEXT_WHITE;
            textView.keyboardAppearance = UIKeyboardAppearanceDark;
        }
    } @catch (NSException *exception) {
        NSLog(@"[BumbleDarkMode] Error: %@", exception);
    }
    return textView;
}

%end

// ============================================================
//  HOOK: UITextField - Dark Background
// ============================================================
%hook UITextField

- (instancetype)initWithFrame:(CGRect)frame {
    UITextField *field = %orig(frame);
    @try {
        if (isDarkModeEnabled) {
            field.backgroundColor = DARK_GRAY;
            field.textColor = TEXT_WHITE;
            field.keyboardAppearance = UIKeyboardAppearanceDark;
        }
    } @catch (NSException *exception) {
        NSLog(@"[BumbleDarkMode] Error: %@", exception);
    }
    return field;
}

%end

// ============================================================
//  HOOK: UIView - Simple Background Color Change
// ============================================================
%hook UIView

- (void)setBackgroundColor:(UIColor *)color {
    @try {
        // Skip certain view types
        if ([self isKindOfClass:[UIImageView class]] ||
            [self isKindOfClass:[UIButton class]] ||
            [self isKindOfClass:[UISegmentedControl class]]) {
            %orig(color);
            return;
        }
        
        if (isDarkModeEnabled && 
            isLightColor(color) && 
            ![color isEqual:[UIColor clearColor]] &&
            ![color isEqual:[UIColor whiteColor]]) {
            %orig(OLED_BLACK);
            return;
        }
    } @catch (NSException *exception) {
        // Ignore
    }
    %orig(color);
}

%end

// ============================================================
//  HOOK: UIViewController - Dark Background
// ============================================================
%hook UIViewController

- (void)viewDidLoad {
    %orig;
    @try {
        if (isDarkModeEnabled) {
            self.view.backgroundColor = OLED_BLACK;
        }
    } @catch (NSException *exception) {
        NSLog(@"[BumbleDarkMode] Error: %@", exception);
    }
}

%end

// ============================================================
//  HOOK: UIWindow - Dark Background
// ============================================================
%hook UIWindow

- (void)setBackgroundColor:(UIColor *)color {
    @try {
        if (isDarkModeEnabled && isLightColor(color)) {
            %orig(OLED_BLACK);
            return;
        }
    } @catch (NSException *exception) {
        // Ignore
    }
    %orig(color);
}

%end