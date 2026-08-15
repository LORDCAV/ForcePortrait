#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <objc/runtime.h>

// ============================================================
//  COLOR DEFINITIONS (OLED Dark Theme)
// ============================================================
#define OLED_BLACK      [UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:1.0]
#define DARK_GRAY       [UIColor colorWithRed:0.12 green:0.12 blue:0.12 alpha:1.0]
#define MEDIUM_GRAY     [UIColor colorWithRed:0.2 green:0.2 blue:0.2 alpha:1.0]
#define LIGHT_GRAY      [UIColor colorWithRed:0.3 green:0.3 blue:0.3 alpha:1.0]
#define TEXT_WHITE      [UIColor colorWithRed:0.95 green:0.95 blue:0.95 alpha:1.0]
#define TEXT_LIGHT      [UIColor colorWithRed:0.8 green:0.8 blue:0.8 alpha:1.0]
#define ACCENT_YELLOW   [UIColor colorWithRed:1.0 green:0.8 blue:0.0 alpha:1.0] // Bumble's yellow
#define ACCENT_BLUE     [UIColor colorWithRed:0.2 green:0.5 blue:0.9 alpha:1.0]

// ============================================================
//  HELPER: Safe color replacement
// ============================================================
static BOOL isDarkModeEnabled = YES; // Toggle this if you want to add a gesture

@interface BumbleDarkMode : NSObject
+ (void)applyDarkTheme;
+ (void)toggleDarkMode;
+ (void)showAlert:(NSString *)message;
@end

@implementation BumbleDarkMode

+ (void)applyDarkTheme {
    // Apply to the main window
    dispatch_async(dispatch_get_main_queue(), ^{
        UIWindow *keyWindow = [UIApplication sharedApplication].keyWindow;
        if (keyWindow) {
            keyWindow.backgroundColor = OLED_BLACK;
        }
        
        // Force all views to update
        for (UIWindow *window in [UIApplication sharedApplication].windows) {
            window.backgroundColor = OLED_BLACK;
            [self recursivelyApplyDarkMode:window];
        }
    });
}

+ (void)recursivelyApplyDarkMode:(UIView *)view {
    // Skip certain views to keep them readable
    if ([view isKindOfClass:NSClassFromString(@"UITextField")] ||
        [view isKindOfClass:NSClassFromString(@"UITextView")] ||
        [view isKindOfClass:NSClassFromString(@"UILabel")]) {
        return;
    }
    
    // Change background colors to dark
    if ([view respondsToSelector:@selector(setBackgroundColor:)]) {
        UIColor *currentColor = view.backgroundColor;
        
        // Don't override images or important UI elements
        if ([view isKindOfClass:[UIImageView class]]) {
            return;
        }
        
        // Replace white/light backgrounds with dark
        if (currentColor) {
            if ([self isLightColor:currentColor]) {
                view.backgroundColor = DARK_GRAY;
            }
        }
        
        // Special handling for specific view types
        if ([view isKindOfClass:[UINavigationBar class]]) {
            view.backgroundColor = OLED_BLACK;
        }
        
        if ([view isKindOfClass:[UITabBar class]]) {
            view.backgroundColor = OLED_BLACK;
        }
        
        if ([view isKindOfClass:[UITableView class]]) {
            view.backgroundColor = OLED_BLACK;
            UITableView *tableView = (UITableView *)view;
            tableView.separatorColor = MEDIUM_GRAY;
        }
        
        if ([view isKindOfClass:[UICollectionView class]]) {
            view.backgroundColor = OLED_BLACK;
        }
        
        if ([view isKindOfClass:[UIScrollView class]]) {
            view.backgroundColor = OLED_BLACK;
        }
    }
    
    // Recurse through subviews
    for (UIView *subview in view.subviews) {
        [self recursivelyApplyDarkMode:subview];
    }
}

+ (BOOL)isLightColor:(UIColor *)color {
    CGFloat red, green, blue, alpha;
    [color getRed:&red green:&green blue:&blue alpha:&alpha];
    CGFloat brightness = (red + green + blue) / 3.0;
    return brightness > 0.5;
}

+ (void)toggleDarkMode {
    isDarkModeEnabled = !isDarkModeEnabled;
    [self showAlert:isDarkModeEnabled ? @"🌙 Dark Mode ON" : @"☀️ Light Mode ON"];
    [self applyDarkTheme];
}

+ (void)showAlert:(NSString *)message {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIWindow *keyWindow = [UIApplication sharedApplication].keyWindow;
        if (!keyWindow) return;
        
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 80, keyWindow.bounds.size.width, 44)];
        label.text = message;
        label.textAlignment = NSTextAlignmentCenter;
        label.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.8];
        label.textColor = [UIColor whiteColor];
        label.font = [UIFont boldSystemFontOfSize:16];
        label.alpha = 0.0;
        [keyWindow addSubview:label];
        
        [UIView animateWithDuration:0.3 animations:^{
            label.alpha = 1.0;
        } completion:^(BOOL finished) {
            [UIView animateWithDuration:0.3 delay:1.5 options:UIViewAnimationOptionCurveEaseOut animations:^{
                label.alpha = 0.0;
            } completion:^(BOOL finished) {
                [label removeFromSuperview];
            }];
        }];
    });
}

@end

// ============================================================
//  HOOK 1: UITableView - Dark Mode for Lists
// ============================================================
%hook UITableView

- (instancetype)initWithFrame:(CGRect)frame style:(UITableViewStyle)style {
    UITableView *table = %orig(frame, style);
    if (isDarkModeEnabled) {
        table.backgroundColor = OLED_BLACK;
        table.separatorColor = MEDIUM_GRAY;
        table.sectionIndexColor = TEXT_WHITE;
        table.sectionIndexBackgroundColor = OLED_BLACK;
        if (@available(iOS 13.0, *)) {
            table.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
        }
    }
    return table;
}

- (void)setBackgroundColor:(UIColor *)color {
    if (isDarkModeEnabled) {
        // Intercept and replace light colors
        if ([BumbleDarkMode isLightColor:color]) {
            %orig(OLED_BLACK);
            return;
        }
    }
    %orig(color);
}

%end

// ============================================================
//  HOOK 2: UITableViewCell - Dark Cells with White Text
// ============================================================
%hook UITableViewCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    UITableViewCell *cell = %orig(style, reuseIdentifier);
    if (isDarkModeEnabled) {
        cell.backgroundColor = DARK_GRAY;
        cell.textLabel.textColor = TEXT_WHITE;
        cell.detailTextLabel.textColor = TEXT_LIGHT;
        cell.selectedBackgroundView = [[UIView alloc] init];
        cell.selectedBackgroundView.backgroundColor = MEDIUM_GRAY;
        
        // Also handle image views
        for (UIView *subview in cell.contentView.subviews) {
            if ([subview isKindOfClass:[UILabel class]]) {
                ((UILabel *)subview).textColor = TEXT_WHITE;
            }
        }
    }
    return cell;
}

- (void)setBackgroundColor:(UIColor *)color {
    if (isDarkModeEnabled) {
        if ([BumbleDarkMode isLightColor:color]) {
            %orig(DARK_GRAY);
            return;
        }
    }
    %orig(color);
}

- (void)setTextLabel:(UILabel *)textLabel {
    if (isDarkModeEnabled) {
        textLabel.textColor = TEXT_WHITE;
    }
    %orig(textLabel);
}

%end

// ============================================================
//  HOOK 3: UICollectionView - Grid Views
// ============================================================
%hook UICollectionView

- (instancetype)initWithFrame:(CGRect)frame collectionViewLayout:(UICollectionViewLayout *)layout {
    UICollectionView *collection = %orig(frame, layout);
    if (isDarkModeEnabled) {
        collection.backgroundColor = OLED_BLACK;
    }
    return collection;
}

- (void)setBackgroundColor:(UIColor *)color {
    if (isDarkModeEnabled) {
        if ([BumbleDarkMode isLightColor:color]) {
            %orig(OLED_BLACK);
            return;
        }
    }
    %orig(color);
}

%end

// ============================================================
//  HOOK 4: UICollectionViewCell - Dark Cells
// ============================================================
%hook UICollectionViewCell

- (instancetype)initWithFrame:(CGRect)frame {
    UICollectionViewCell *cell = %orig(frame);
    if (isDarkModeEnabled) {
        cell.backgroundColor = DARK_GRAY;
        for (UIView *subview in cell.contentView.subviews) {
            if ([subview isKindOfClass:[UILabel class]]) {
                ((UILabel *)subview).textColor = TEXT_WHITE;
            }
        }
    }
    return cell;
}

- (void)setBackgroundColor:(UIColor *)color {
    if (isDarkModeEnabled) {
        if ([BumbleDarkMode isLightColor:color]) {
            %orig(DARK_GRAY);
            return;
        }
    }
    %orig(color);
}

%end

// ============================================================
//  HOOK 5: UINavigationBar - Dark Mode
// ============================================================
%hook UINavigationBar

- (instancetype)initWithFrame:(CGRect)frame {
    UINavigationBar *nav = %orig(frame);
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
    return nav;
}

- (void)setBarTintColor:(UIColor *)barTintColor {
    if (isDarkModeEnabled) {
        %orig(OLED_BLACK);
        return;
    }
    %orig(barTintColor);
}

%end

// ============================================================
//  HOOK 6: UITabBar - Dark Mode
// ============================================================
%hook UITabBar

- (instancetype)initWithFrame:(CGRect)frame {
    UITabBar *tabBar = %orig(frame);
    if (isDarkModeEnabled) {
        tabBar.barTintColor = OLED_BLACK;
        tabBar.backgroundColor = OLED_BLACK;
        tabBar.tintColor = ACCENT_YELLOW;
        tabBar.unselectedItemTintColor = TEXT_LIGHT;
        if (@available(iOS 13.0, *)) {
            UITabBarAppearance *appearance = [[UITabBarAppearance alloc] init];
            appearance.backgroundColor = OLED_BLACK;
            tabBar.standardAppearance = appearance;
            tabBar.scrollEdgeAppearance = appearance;
        }
    }
    return tabBar;
}

- (void)setBarTintColor:(UIColor *)barTintColor {
    if (isDarkModeEnabled) {
        %orig(OLED_BLACK);
        return;
    }
    %orig(barTintColor);
}

%end

// ============================================================
//  HOOK 7: UILabel - Force White Text
// ============================================================
%hook UILabel

- (void)setTextColor:(UIColor *)color {
    if (isDarkModeEnabled) {
        // Keep system colors for certain elements (like error messages)
        if ([color isEqual:[UIColor redColor]]) {
            %orig(color);
            return;
        }
        // Force white text for readability
        if ([BumbleDarkMode isLightColor:color] || [color isEqual:[UIColor blackColor]]) {
            %orig(TEXT_WHITE);
            return;
        }
    }
    %orig(color);
}

- (void)setBackgroundColor:(UIColor *)color {
    if (isDarkModeEnabled) {
        if ([BumbleDarkMode isLightColor:color]) {
            // Don't override labels with transparent backgrounds
            if (![color isEqual:[UIColor clearColor]]) {
                %orig([UIColor clearColor]);
                return;
            }
        }
    }
    %orig(color);
}

%end

// ============================================================
//  HOOK 8: UIButton - Dark Mode
// ============================================================
%hook UIButton

- (void)setTitleColor:(UIColor *)color forState:(UIControlState)state {
    if (isDarkModeEnabled) {
        if ([BumbleDarkMode isLightColor:color] || [color isEqual:[UIColor blackColor]]) {
            %orig(TEXT_WHITE, state);
            return;
        }
    }
    %orig(color, state);
}

%end

// ============================================================
//  HOOK 9: UITextField - Dark Mode
// ============================================================
%hook UITextField

- (instancetype)initWithFrame:(CGRect)frame {
    UITextField *field = %orig(frame);
    if (isDarkModeEnabled) {
        field.backgroundColor = DARK_GRAY;
        field.textColor = TEXT_WHITE;
        field.keyboardAppearance = UIKeyboardAppearanceDark;
    }
    return field;
}

- (void)setBackgroundColor:(UIColor *)color {
    if (isDarkModeEnabled) {
        if ([BumbleDarkMode isLightColor:color]) {
            %orig(DARK_GRAY);
            return;
        }
    }
    %orig(color);
}

%end

// ============================================================
//  HOOK 10: UIView - Catch-All for Dark Mode
// ============================================================
%hook UIView

- (void)setBackgroundColor:(UIColor *)color {
    // Skip certain view types
    if ([self isKindOfClass:[UILabel class]] ||
        [self isKindOfClass:[UITextField class]] ||
        [self isKindOfClass:[UITextView class]] ||
        [self isKindOfClass:[UIImageView class]]) {
        %orig(color);
        return;
    }
    
    // Skip views with images
    if ([self isKindOfClass:[UIButton class]] && [self respondsToSelector:@selector(imageView)]) {
        %orig(color);
        return;
    }
    
    if (isDarkModeEnabled) {
        if ([BumbleDarkMode isLightColor:color] && 
            ![color isEqual:[UIColor clearColor]] &&
            ![color isEqual:[UIColor whiteColor]]) {
            %orig(OLED_BLACK);
            return;
        }
    }
    %orig(color);
}

%end

// ============================================================
//  MAIN ENTRY: Initialize Dark Mode + Toggle Gesture
// ============================================================
%ctor {
    NSLog(@"[BumbleDarkMode] ✅ Dark mode dylib loaded!");
    
    // Apply dark mode
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [BumbleDarkMode applyDarkTheme];
        [BumbleDarkMode showAlert:@"🌙 OLED Dark Mode ON"];
    });
    
    // Add toggle gesture: Triple tap with 2 fingers
    dispatch_async(dispatch_get_main_queue(), ^{
        UIWindow *keyWindow = [UIApplication sharedApplication].keyWindow;
        if (!keyWindow) return;
        
        UITapGestureRecognizer *tripleTap = [[UITapGestureRecognizer alloc] initWithTarget:[BumbleDarkMode class] 
                                                                                   action:@selector(toggleDarkMode)];
        tripleTap.numberOfTapsRequired = 3;
        tripleTap.numberOfTouchesRequired = 2; // Two fingers, triple tap
        [keyWindow addGestureRecognizer:tripleTap];
    });
}