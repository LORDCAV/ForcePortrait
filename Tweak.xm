#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <objc/runtime.h>

// ============================================================
//  COLOR DEFINITIONS (OLED Dark Theme - Readable)
// ============================================================
#define OLED_BLACK      [UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:1.0]
#define DARK_GRAY       [UIColor colorWithRed:0.1 green:0.1 blue:0.1 alpha:1.0]
#define CARD_GRAY       [UIColor colorWithRed:0.15 green:0.15 blue:0.15 alpha:1.0]
#define MEDIUM_GRAY     [UIColor colorWithRed:0.25 green:0.25 blue:0.25 alpha:1.0]
#define LIGHT_GRAY      [UIColor colorWithRed:0.35 green:0.35 blue:0.35 alpha:1.0]
#define TEXT_WHITE      [UIColor colorWithRed:0.95 green:0.95 blue:0.95 alpha:1.0]
#define TEXT_LIGHT      [UIColor colorWithRed:0.8 green:0.8 blue:0.8 alpha:1.0]
#define TEXT_GRAY       [UIColor colorWithRed:0.6 green:0.6 blue:0.6 alpha:1.0]
#define ACCENT_YELLOW   [UIColor colorWithRed:1.0 green:0.8 blue:0.0 alpha:1.0]
#define CHAT_BUBBLE_ME  [UIColor colorWithRed:0.2 green:0.35 blue:0.7 alpha:1.0]  // Blue for your messages
#define CHAT_BUBBLE_OTHER [UIColor colorWithRed:0.2 green:0.2 blue:0.2 alpha:1.0] // Dark gray for other messages

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
    NSLog(@"[BumbleDarkMode] ✅ Dark mode dylib loaded!");
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        UIWindow *keyWindow = [UIApplication sharedApplication].keyWindow;
        if (keyWindow) {
            keyWindow.backgroundColor = OLED_BLACK;
            // Apply dark mode to all windows
            for (UIWindow *window in [UIApplication sharedApplication].windows) {
                window.backgroundColor = OLED_BLACK;
                [self applyDarkModeToView:window];
            }
        }
    });
}

// ============================================================
//  RECURSIVE DARK MODE APPLIER
// ============================================================
static void applyDarkModeToView(UIView *view) {
    // Skip certain view types
    if ([view isKindOfClass:[UIImageView class]]) {
        return;
    }
    
    // Apply background color
    if ([view respondsToSelector:@selector(setBackgroundColor:)]) {
        UIColor *currentColor = view.backgroundColor;
        if (currentColor && isLightColor(currentColor) && 
            ![currentColor isEqual:[UIColor clearColor]]) {
            view.backgroundColor = DARK_GRAY;
        }
    }
    
    // Special handling for specific view types
    if ([view isKindOfClass:[UILabel class]]) {
        UILabel *label = (UILabel *)view;
        // Keep white text
        if (label.textColor && isLightColor(label.textColor)) {
            label.textColor = TEXT_WHITE;
        }
        // Make sure background is dark
        if (label.backgroundColor && isLightColor(label.backgroundColor)) {
            label.backgroundColor = [UIColor clearColor];
        }
    }
    
    if ([view isKindOfClass:[UITextView class]]) {
        UITextView *textView = (UITextView *)view;
        textView.textColor = TEXT_WHITE;
        textView.backgroundColor = DARK_GRAY;
        textView.keyboardAppearance = UIKeyboardAppearanceDark;
    }
    
    if ([view isKindOfClass:[UITextField class]]) {
        UITextField *textField = (UITextField *)view;
        textField.textColor = TEXT_WHITE;
        textField.backgroundColor = DARK_GRAY;
        textField.keyboardAppearance = UIKeyboardAppearanceDark;
    }
    
    if ([view isKindOfClass:[UIButton class]]) {
        UIButton *button = (UIButton *)view;
        // Keep button colors but ensure text is readable
        UIColor *titleColor = [button titleColorForState:UIControlStateNormal];
        if (titleColor && isLightColor(titleColor)) {
            [button setTitleColor:TEXT_WHITE forState:UIControlStateNormal];
        }
    }
    
    // Recursively apply to subviews
    for (UIView *subview in view.subviews) {
        applyDarkModeToView(subview);
    }
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
        table.sectionIndexColor = TEXT_WHITE;
        table.sectionIndexBackgroundColor = OLED_BLACK;
        if (@available(iOS 13.0, *)) {
            table.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
        }
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

- (void)reloadData {
    %orig;
    // Reapply dark mode after reload
    dispatch_async(dispatch_get_main_queue(), ^{
        for (UIView *subview in self.subviews) {
            applyDarkModeToView(subview);
        }
    });
}

%end

// ============================================================
//  HOOK: UITableViewCell - Dark Cells with White Text
// ============================================================
%hook UITableViewCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    UITableViewCell *cell = %orig(style, reuseIdentifier);
    if (isDarkModeEnabled) {
        cell.backgroundColor = CARD_GRAY;
        cell.textLabel.textColor = TEXT_WHITE;
        cell.detailTextLabel.textColor = TEXT_LIGHT;
        cell.selectedBackgroundView = [[UIView alloc] init];
        cell.selectedBackgroundView.backgroundColor = MEDIUM_GRAY;
        cell.contentView.backgroundColor = [UIColor clearColor];
        
        // Update all labels in contentView
        for (UIView *subview in cell.contentView.subviews) {
            if ([subview isKindOfClass:[UILabel class]]) {
                ((UILabel *)subview).textColor = TEXT_WHITE;
            }
            if ([subview isKindOfClass:[UITextView class]]) {
                ((UITextView *)subview).textColor = TEXT_WHITE;
                ((UITextView *)subview).backgroundColor = [UIColor clearColor];
            }
        }
    }
    return cell;
}

- (void)setBackgroundColor:(UIColor *)color {
    if (isDarkModeEnabled && isLightColor(color)) {
        %orig(CARD_GRAY);
        return;
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
        cell.backgroundColor = CARD_GRAY;
        for (UIView *subview in cell.contentView.subviews) {
            if ([subview isKindOfClass:[UILabel class]]) {
                ((UILabel *)subview).textColor = TEXT_WHITE;
            }
        }
    }
    return cell;
}

- (void)setBackgroundColor:(UIColor *)color {
    if (isDarkModeEnabled && isLightColor(color)) {
        %orig(CARD_GRAY);
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
        tabBar.tintColor = ACCENT_YELLOW;
        tabBar.unselectedItemTintColor = TEXT_GRAY;
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

- (void)setBackgroundColor:(UIColor *)color {
    if (isDarkModeEnabled && isLightColor(color) && 
        ![color isEqual:[UIColor clearColor]]) {
        %orig([UIColor clearColor]);
        return;
    }
    %orig(color);
}

%end

// ============================================================
//  HOOK: UITextView - Chat Messages
// ============================================================
%hook UITextView

- (instancetype)initWithFrame:(CGRect)frame textContainer:(NSTextContainer *)textContainer {
    UITextView *textView = %orig(frame, textContainer);
    if (isDarkModeEnabled) {
        textView.backgroundColor = DARK_GRAY;
        textView.textColor = TEXT_WHITE;
        textView.keyboardAppearance = UIKeyboardAppearanceDark;
    }
    return textView;
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
//  HOOK: UITextField - Input Fields
// ============================================================
%hook UITextField

- (instancetype)initWithFrame:(CGRect)frame {
    UITextField *field = %orig(frame);
    if (isDarkModeEnabled) {
        field.backgroundColor = DARK_GRAY;
        field.textColor = TEXT_WHITE;
        field.keyboardAppearance = UIKeyboardAppearanceDark;
        field.attributedPlaceholder = [[NSAttributedString alloc] 
            initWithString:field.placeholder ?: @""
            attributes:@{NSForegroundColorAttributeName: TEXT_GRAY}];
    }
    return field;
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
//  HOOK: UIView - Catch-All
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
    
    if (isDarkModeEnabled && isLightColor(color) && 
        ![color isEqual:[UIColor clearColor]] &&
        ![color isEqual:[UIColor whiteColor]]) {
        %orig(OLED_BLACK);
        return;
    }
    %orig(color);
}

%end

// ============================================================
//  HOOK: UIWindow - Ensure Dark Background
// ============================================================
%hook UIWindow

- (void)setBackgroundColor:(UIColor *)color {
    if (isDarkModeEnabled && isLightColor(color)) {
        %orig(OLED_BLACK);
        return;
    }
    %orig(color);
}

%end

// ============================================================
//  HOOK: UIViewController - Apply Dark Mode on Appear
// ============================================================
%hook UIViewController

- (void)viewDidLoad {
    %orig;
    if (isDarkModeEnabled) {
        self.view.backgroundColor = OLED_BLACK;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            applyDarkModeToView(self.view);
        });
    }
}

- (void)viewWillAppear:(BOOL)animated {
    %orig(animated);
    if (isDarkModeEnabled) {
        self.view.backgroundColor = OLED_BLACK;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            applyDarkModeToView(self.view);
        });
    }
}

%end

// ============================================================
//  HOOK: Chat Bubble Detection
// ============================================================
%hook UIView

- (void)didAddSubview:(UIView *)subview {
    %orig(subview);
    if (isDarkModeEnabled) {
        // Check if this looks like a chat bubble (custom view with dark background)
        if ([subview respondsToSelector:@selector(setBackgroundColor:)]) {
            UIColor *bgColor = subview.backgroundColor;
            if (bgColor && isLightColor(bgColor) && 
                ![bgColor isEqual:[UIColor clearColor]] &&
                ![bgColor isEqual:[UIColor whiteColor]]) {
                // Might be a chat bubble - keep it but ensure text is readable
                subview.backgroundColor = CARD_GRAY;
            }
        }
        // Apply dark mode to all subviews
        for (UIView *sub in subview.subviews) {
            applyDarkModeToView(sub);
        }
    }
}

%end