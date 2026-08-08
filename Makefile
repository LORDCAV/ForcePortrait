TARGET := iphone:clang:latest:15.0
ARCHS := arm64

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = ForcePortrait
ForcePortrait_FILES = Tweak.m
ForcePortrait_FRAMEWORKS = UIKit Foundation

include $(THEOS)/makefiles/tweak.mk
