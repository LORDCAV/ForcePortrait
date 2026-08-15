#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <objc/runtime.h>

// ============================================================
//  COLOR DEFINITIONS (OLED Dark Theme)
// ============================================================
#define OLED_BLACK      [UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:1.0]
#define DARK_GRAY       [UIColor colorWithRed:0.12 green:0.12 blue:0.12 alpha:1.0]
#define MEDIUM_GRAY     [UIColor colorWithRed:0.2 green:0.2 blue:0.2 alpha:1.0]
#define TEXT_WHITE      [UIColor colorWithRed:0.95 green:0.95 blue:0.95 alpha:1.0]
#define TEXT_LIGHT      [UIColor colorWithRed:0.8 green:0.8 blue:0.8 alpha:1.0]

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
//  MAIN ENTRY POINT - THIS IS REQUIRED FOR DYLIB TO WORK!
// ============================================================
%ctor {
    NSLog(@"[BumbleDarkMode] ✅ Dark mode dylib loaded successfully!");
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        UIWindow *keyWindow = [UIApplication sharedApplication].keyWindow;
        if (keyWindow) {
            keyWindow.backgroundColor = OLED_BLACK;
            NSLog(@"[BumbleDarkMode] 🌙 Dark mode applied!");
        }
    });
}

// ============================================================
//  HOOK: UITableView - Dark Mode
// ============================================================
%hook UITableView

- (instancetype)initWithFrame:(CGRect)frame style:(UITableViewStyle)style {
    UITableView *table = %orig(frame, style);
    if (isDarkModeEnabled) {
        table.backgroundColor = OLED_BLACK;
        table.separatorColor = MEDIUM_GRAY;
    }
    return table;
}

- (void)setBackgroundColor:(UIColor *)color {
    if (isDarkModeEnabled && isLightColor(color)) {
        %orig(OLED_BLACK);
        return;
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
    if (isDarkModeEnabled) {
        cell.backgroundColor = DARK_GRAY;
        cell.textLabel.textColor = TEXT_WHITE;
        cell.detailTextLabel.textColor = TEXT_LIGHT;
    }
    return cell;
}

- (void)setBackgroundColor:(UIColor *)color {
    if (isDarkModeEnabled && isLightColor(color)) {
        %orig(DARK_GRAY);
        return;
    }
    %orig(color);
}

%end

// ============================================================
//  HOOK: UICollectionView - Dark Mode
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
    if (isDarkModeEnabled && isLightColor(color)) {
        %orig(OLED_BLACK);
        return;
    }
    %orig(color);
}

%end

// ============================================================
//  HOOK: UICollectionViewCell - Dark Cells
// ============================================================
%hook UICollectionViewCell

- (instancetype)initWithFrame:(CGRect)frame {
    UICollectionViewCell *cell = %orig(frame);
    if (isDarkModeEnabled) {
        cell.backgroundColor = DARK_GRAY;
    }
    return cell;
}

- (void)setBackgroundColor:(UIColor *)color {
    if (isDarkModeEnabled && isLightColor(color)) {
        %orig(DARK_GRAY);
        return;
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
    if (isDarkModeEnabled) {
        nav.barTintColor = OLED_BLACK;
        nav.backgroundColor = OLED_BLACK;
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

%end

// ============================================================
//  HOOK: UITabBar - Dark Mode
// ============================================================
%hook UITabBar

- (instancetype)initWithFrame:(CGRect)frame {
    UITabBar *tabBar = %orig(frame);
    if (isDarkModeEnabled) {
        tabBar.barTintColor = OLED_BLACK;
        tabBar.backgroundColor = OLED_BLACK;
        if (@available(iOS 13.0, *)) {
            UITabBarAppearance *appearance = [[UITabBarAppearance alloc] init];
            appearance.backgroundColor = OLED_BLACK;
            tabBar.standardAppearance = appearance;
            tabBar.scrollEdgeAppearance = appearance;
        }
    }
    return tabBar;
}

%end

// ============================================================
//  HOOK: UILabel - Force White Text
// ============================================================
%hook UILabel

- (void)setTextColor:(UIColor *)color {
    if (isDarkModeEnabled && isLightColor(color)) {
        %orig(TEXT_WHITE);
        return;
    }
    %orig(color);
}

%end

// ============================================================
//  HOOK: UIView - Catch-All
// ============================================================
%hook UIView

- (void)setBackgroundColor:(UIColor *)color {
    // Skip certain view types
    if ([self isKindOfClass:[UILabel class]] ||
        [self isKindOfClass:[UITextField class]] ||
        [self isKindOfClass:[UIImageView class]]) {
        %orig(color);
        return;
    }
    
    if (isDarkModeEnabled && isLightColor(color) && 
        ![color isEqual:[UIColor clearColor]]) {
        %orig(OLED_BLACK);
        return;
    }
    %orig(color);
}

%end