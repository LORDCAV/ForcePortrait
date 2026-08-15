TARGET := iphone:clang:latest
ARCHS = arm64 arm64e

TWEAK_NAME = BumbleDarkMode
BumbleDarkMode_FILES = Tweak.xm
BumbleDarkMode_CFLAGS = -fobjc-arc -Wno-deprecated-declarations
BumbleDarkMode_LDFLAGS = -framework Foundation -framework UIKit
BumbleDarkMode_FILTER = BumbleDarkMode.plist

include $(THEOS)/makefiles/common.mk
include $(THEOS_MAKE_PATH)/tweak.mk 