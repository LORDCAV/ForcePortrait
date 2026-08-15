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
#define INPUT_GRAY      [UIColor colorWithRed:0.15 green:0.15 blue:0.15 alpha:1.0]
#define TEXT_WHITE      [UIColor colorWithRed:0.95 green:0.95 blue:0.95 alpha:1.0]
#define TEXT_LIGHT      [UIColor colorWithRed:0.8 green:0.8 blue:0.8 alpha:1.0]
#define TEXT_GRAY       [UIColor colorWithRed:0.6 green:0.6 blue:0.6 alpha:1.0]
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
//  RECURSIVE DARK MODE APPLIER (Targets all subviews)
// ============================================================
static void applyDarkModeToView(UIView *view) {
    @try {
        if (!view) return;
        
        // Skip certain view types
        if ([view isKindOfClass:[UIImageView class]]) return;
        if ([view isKindOfClass:[UIButton class]]) return;
        
        // Apply dark background to EVERY view
        @try {
            if ([view respondsToSelector:@selector(setBackgroundColor:)]) {
                UIColor *currentColor = view.backgroundColor;
                // If it's white, light gray, or transparent with white background
                if (currentColor && isLightColor(currentColor)) {
                    view.backgroundColor = DARK_GRAY;
                }
                // If it's clear but the view is a container, make it dark
                if ([currentColor isEqual:[UIColor clearColor]] && 
                    [view isKindOfClass:[UIView class]] &&
                    ![view isKindOfClass:[UILabel class]] &&
                    ![view isKindOfClass:[UIImageView class]]) {
                    view.backgroundColor = DARK_GRAY;
                }
            }
        } @catch (NSException *e) {}
        
        // Force labels to white text
        @try {
            if ([view isKindOfClass:[UILabel class]]) {
                UILabel *label = (UILabel *)view;
                if (label.textColor && isLightColor(label.textColor)) {
                    label.textColor = TEXT_WHITE;
                }
                // If label has light background, make it clear
                if (label.backgroundColor && isLightColor(label.backgroundColor)) {
                    label.backgroundColor = [UIColor clearColor];
                }
            }
        } @catch (NSException *e) {}
        
        // Recursively apply to subviews
        @try {
            for (UIView *subview in view.subviews) {
                applyDarkModeToView(subview);
            }
        } @catch (NSException *e) {}
    } @catch (NSException *e) {}
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
                applyDarkModeToView(keyWindow);
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
    } @catch (NSException *exception) {}
    %orig(color);
}

- (void)reloadData {
    %orig;
    @try {
        if (isDarkModeEnabled) {
            dispatch_async(dispatch_get_main_queue(), ^{
                applyDarkModeToView(self);
            });
        }
    } @catch (NSException *exception) {}
}

- (void)layoutSubviews {
    %orig;
    @try {
        if (isDarkModeEnabled) {
            applyDarkModeToView(self);
        }
    } @catch (NSException *exception) {}
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
            applyDarkModeToView(cell.contentView);
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
    } @catch (NSException *exception) {}
    %orig(color);
}

- (void)layoutSubviews {
    %orig;
    @try {
        if (isDarkModeEnabled) {
            applyDarkModeToView(self);
        }
    } @catch (NSException *exception) {}
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
    } @catch (NSException *exception) {}
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
            tabBar.unselectedItemTintColor = TEXT_GRAY;
            if (@available(iOS 13.0, *)) {
                UITabBarAppearance *appearance = [[UITabBarAppearance alloc] init];
                appearance.backgroundColor = OLED_BLACK;
                tabBar.standardAppearance = appearance;
                tabBar.scrollEdgeAppearance = appearance;
            }
        }
    } @catch (NSException *exception) {}
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
    } @catch (NSException *exception) {}
    %orig(color);
}

- (void)setBackgroundColor:(UIColor *)color {
    @try {
        if (isDarkModeEnabled && isLightColor(color) && 
            ![color isEqual:[UIColor clearColor]]) {
            %orig([UIColor clearColor]);
            return;
        }
    } @catch (NSException *exception) {}
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
            textView.backgroundColor = INPUT_GRAY;
            textView.textColor = TEXT_WHITE;
            textView.keyboardAppearance = UIKeyboardAppearanceDark;
        }
    } @catch (NSException *exception) {}
    return textView;
}

- (void)setBackgroundColor:(UIColor *)color {
    @try {
        if (isDarkModeEnabled && isLightColor(color)) {
            %orig(INPUT_GRAY);
            return;
        }
    } @catch (NSException *exception) {}
    %orig(color);
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
            field.backgroundColor = INPUT_GRAY;
            field.textColor = TEXT_WHITE;
            field.keyboardAppearance = UIKeyboardAppearanceDark;
            if (field.placeholder) {
                field.attributedPlaceholder = [[NSAttributedString alloc] 
                    initWithString:field.placeholder
                    attributes:@{NSForegroundColorAttributeName: TEXT_GRAY}];
            }
        }
    } @catch (NSException *exception) {}
    return field;
}

- (void)setBackgroundColor:(UIColor *)color {
    @try {
        if (isDarkModeEnabled && isLightColor(color)) {
            %orig(INPUT_GRAY);
            return;
        }
    } @catch (NSException *exception) {}
    %orig(color);
}

- (void)setPlaceholder:(NSString *)placeholder {
    %orig(placeholder);
    @try {
        if (isDarkModeEnabled && placeholder) {
            self.attributedPlaceholder = [[NSAttributedString alloc] 
                initWithString:placeholder
                attributes:@{NSForegroundColorAttributeName: TEXT_GRAY}];
        }
    } @catch (NSException *exception) {}
}

%end

// ============================================================
//  HOOK: UISearchBar - Search Bar Fix
// ============================================================
%hook UISearchBar

- (instancetype)initWithFrame:(CGRect)frame {
    UISearchBar *searchBar = %orig(frame);
    @try {
        if (isDarkModeEnabled) {
            searchBar.barTintColor = OLED_BLACK;
            searchBar.backgroundColor = OLED_BLACK;
            searchBar.tintColor = ACCENT_YELLOW;
            if (@available(iOS 13.0, *)) {
                searchBar.searchTextField.backgroundColor = INPUT_GRAY;
                searchBar.searchTextField.textColor = TEXT_WHITE;
            }
        }
    } @catch (NSException *exception) {}
    return searchBar;
}

- (void)setBackgroundColor:(UIColor *)color {
    @try {
        if (isDarkModeEnabled && isLightColor(color)) {
            %orig(OLED_BLACK);
            return;
        }
    } @catch (NSException *exception) {}
    %orig(color);
}

%end

// ============================================================
//  HOOK: UICollectionView - Dark Mode (For Opening Moves)
// ============================================================
%hook UICollectionView

- (instancetype)initWithFrame:(CGRect)frame collectionViewLayout:(UICollectionViewLayout *)layout {
    UICollectionView *collection = %orig(frame, layout);
    @try {
        if (isDarkModeEnabled) {
            collection.backgroundColor = OLED_BLACK;
        }
    } @catch (NSException *exception) {}
    return collection;
}

- (void)setBackgroundColor:(UIColor *)color {
    @try {
        if (isDarkModeEnabled && isLightColor(color)) {
            %orig(OLED_BLACK);
            return;
        }
    } @catch (NSException *exception) {}
    %orig(color);
}

- (void)reloadData {
    %orig;
    @try {
        if (isDarkModeEnabled) {
            dispatch_async(dispatch_get_main_queue(), ^{
                applyDarkModeToView(self);
            });
        }
    } @catch (NSException *exception) {}
}

%end

// ============================================================
//  HOOK: UICollectionViewCell - Dark Cells
// ============================================================
%hook UICollectionViewCell

- (instancetype)initWithFrame:(CGRect)frame {
    UICollectionViewCell *cell = %orig(frame);
    @try {
        if (isDarkModeEnabled) {
            cell.backgroundColor = CARD_GRAY;
            applyDarkModeToView(cell.contentView);
        }
    } @catch (NSException *exception) {}
    return cell;
}

- (void)setBackgroundColor:(UIColor *)color {
    @try {
        if (isDarkModeEnabled && isLightColor(color)) {
            %orig(CARD_GRAY);
            return;
        }
    } @catch (NSException *exception) {}
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
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                applyDarkModeToView(self.view);
            });
        }
    } @catch (NSException *exception) {}
}

- (void)viewWillAppear:(BOOL)animated {
    %orig(animated);
    @try {
        if (isDarkModeEnabled) {
            self.view.backgroundColor = OLED_BLACK;
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                applyDarkModeToView(self.view);
            });
        }
    } @catch (NSException *exception) {}
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
    } @catch (NSException *exception) {}
    %orig(color);
}

%end

// ============================================================
//  HOOK: UIScrollView - Dark Background
// ============================================================
%hook UIScrollView

- (void)setBackgroundColor:(UIColor *)color {
    @try {
        if (isDarkModeEnabled && isLightColor(color)) {
            %orig(OLED_BLACK);
            return;
        }
    } @catch (NSException *exception) {}
    %orig(color);
}

%end
