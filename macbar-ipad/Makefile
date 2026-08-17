# MacBar — macOS menu bar ported to iPadOS (jailbreak tweak, ROOTLESS)
#
# Rootless layout: install prefix /var/jb  (Palera1n / Dopamine / others)
# Architecture: arm64 + arm64e
# Target: iOS 15.5+ (built against iPhoneOS15.6.sdk, ABI compatible)
#
# Cross-compile on Linux using the cctools-port toolchain
# (https://github.com/L1ghtmann/llvm-project) — clang + ld64 + ldid.
#
# Build:   make
# Package: make package   (produces a .deb)
#
# Toolchain / SDK locations (override on the command line):
#   make TOOLCHAIN=/path/iphone SDK=/path/iPhoneOS15.6.sdk

TOOLCHAIN ?= /tmp/ios_toolchain/linux/iphone
SDK       ?= /tmp/ios_toolchain/sdks/iPhoneOS15.6.sdk

CL  := $(TOOLCHAIN)/bin/clang
LD  := $(TOOLCHAIN)/bin/ld
LDID := $(TOOLCHAIN)/bin/ldid
LIPO := $(TOOLCHAIN)/bin/lipo

TARGET     = -target arm64-apple-ios15.6
SYSROOT    = -isysroot $(SDK)
ARC        = -fobjc-arc
WARN       = -Wno-deprecated-declarations -Wno-unused -Wno-nullability-completeness
INCLUDES   = -IHeaders -ISource
CFLAGS     = $(TARGET) $(SYSROOT) $(ARC) $(WARN) $(INCLUDES) -O2 -g
LDFLAGS    = $(TARGET) $(SYSROOT) -fuse-ld=$(LD) -framework UIKit -framework Foundation \
             -framework AudioToolbox -framework CoreGraphics -framework QuartzCore \
             -lobjc -lz -lc++ -lc++abi -L$(SDK)/usr/lib \
             -Wl,-undefined,dynamic_lookup

NAME       = MacBar
PREFIX     = /var/jb
LIBDIR     = $(PREFIX)/Library/MobileSubstrate/DynamicLibraries
BUNDLEDIR  = $(PREFIX)/Library/MobileSubstrate/DynamicLibraries

SRCS_C = \
	Source/MBCore.mm \
	Source/NSStatusBar.mm \
	Source/NSStatusItem.mm \
	Source/NSStatusBarButton.mm \
	Source/NSMenu.mm \
	Source/NSMenuExtra.mm \
	Source/MBMenuWindow.mm \
	Source/MBMenuExtraLoader.mm \
	Source/MBMenuBarWindow.mm \
	Source/MBMenuBarView.mm \
	Source/MBAppMenuController.mm \
	Source/Extras/AppleClockExtra.mm \
	Source/Extras/BatteryExtra.mm \
	Source/Extras/AirPortExtra.mm \
	Source/Extras/AppleVolumeExtra.mm \
	Source/Extras/MBRotationLockExtra.mm \
	Source/Hooks/MBSpringBoardHooks.mm \
	Source/Hooks/MBVolumeHooks.mm

OBJS = $(SRCS_C:.mm=.o)

.PHONY: all clean package install

all: $(NAME).dylib

%.o: %.mm
	$(CL) $(CFLAGS) -c $< -o $@

$(NAME).dylib: $(OBJS)
	$(CL) $(LDFLAGS) -dynamiclib -install_name $(LIBDIR)/$(NAME).dylib \
		-o $@ $(OBJS)
	$(LDID) -S $@ 2>/dev/null || true

# Resource bundle (.bundle of plists + strings) and the MobileSubstrate filter
# plist are installed beside the dylib.
RESOURCES = \
	Resources/Autoload.plist \
	Resources/MenuExtras.plist \
	Resources/en.lproj/Localizable.strings \
	Resources/zh-Hans.lproj/Localizable.strings

package: $(NAME).dylib
	@rm -rf _package
	@mkdir -p _package/$(LIBDIR)
	@mkdir -p _package/$(BUNDLEDIR)/MacBar.bundle/en.lproj
	@mkdir -p _package/$(BUNDLEDIR)/MacBar.bundle/zh-Hans.lproj
	@mkdir -p _package/DEBIAN
	cp $(NAME).dylib _package/$(LIBDIR)/
	cp $(NAME).plist _package/$(BUNDLEDIR)/
	cp Resources/Autoload.plist Resources/MenuExtras.plist _package/$(BUNDLEDIR)/MacBar.bundle/
	cp -R Resources/extras _package/$(BUNDLEDIR)/MacBar.bundle/extras
	cp Resources/en.lproj/Localizable.strings _package/$(BUNDLEDIR)/MacBar.bundle/en.lproj/
	cp Resources/zh-Hans.lproj/Localizable.strings _package/$(BUNDLEDIR)/MacBar.bundle/zh-Hans.lproj/
	@chmod 0755 _package/DEBIAN
	@printf '#!/bin/sh\nexit 0\n' > _package/DEBIAN/preinst; chmod 0755 _package/DEBIAN/preinst
	@printf '#!/bin/sh\nif [ -x /var/jb/usr/bin/killall ]; then /var/jb/usr/bin/killall -9 SpringBoard 2>/dev/null; fi\n' > _package/DEBIAN/postinst; chmod 0755 _package/DEBIAN/postinst
	sed -e 's/@ARCH@/iphoneos-arm64/' control_rootless > _package/DEBIAN/control
	@dpkg-deb -Zxz --root-owner-group -b _package $(NAME)_1.0.0_rootless.deb
	@echo "Built: $(NAME)_1.0.0_rootless.deb"

clean:
	rm -f $(OBJS) $(NAME).dylib
	rm -rf _package $(NAME)_*.deb

