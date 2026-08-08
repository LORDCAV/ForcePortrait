TARGET := iphone:clang:latest:16.0
ARCHS := arm64

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = BumbleLock
BumbleLock_FILES = Tweak.m
BumbleLock_FRAMEWORKS = UIKit Foundation LocalAuthentication
BumbleLock_LDFLAGS = -framework LocalAuthentication

include $(THEOS)/makefiles/tweak.mk
