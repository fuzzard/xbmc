include ../../Makefile.include
DEPS= ../../Makefile.include Makefile modules.setup \
    crosscompile.patch darwinembed_posixmodule.patch \
    darwinembed_config_sub.patch \
    darwinembed_configure_ac.patch \
    darwinembed_dynloadshlib.patch \
    site.patch \
    android.patch \
    Modules.new

VERSION.TXT := $(CMAKE_SOURCE_DIR)/version.txt
APP_NAME=$(shell awk '/APP_NAME/ {print tolower($$2)}' $(VERSION.TXT))

# lib name, version
LIBNAME=Python
VERSION=3.8.5
SOURCE=$(LIBNAME)-$(VERSION)
ARCHIVE=$(SOURCE).tar.xz
BASE_URL=https://www.python.org/ftp/python/$(VERSION)

ifeq ($(findstring apple-darwin, $(HOST)), apple-darwin)
  HOSTPLATFORM=_PYTHON_HOST_PLATFORM="darwin"
  LINK_ICONV=-framework CoreFoundation -liconv
endif

LDFLAGS+= -lpython3.8 -lintl -liconv -lssl -lcrypto -lz -lbz2 -lsqlite3 -lffi -framework Foundation
#  -static
#-L$(PREFIX)/lib/dummy-lib$(APP_NAME)/ -l$(APP_NAME)
export LDFLAGS
#export LDSHARED="$(CC) -undefined dynamic_lookup"
export LDSHARED="/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/clang"
#export LDSHARED='ld -arch arm64 -L/Users/brent/kivy-ios/dist/lib -L/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator14.3.sdk/usr/lib -miphoneos-version-min=11.0'
#export LD=/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/ld
#export LDFLAGS=-syslibroot $(SDKROOT) -arch arm64  -ios_version_min 11.0 -L/Users/Shared/xbmc-depends/iphoneos14.3_arm64-target-debug/lib -L/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS14.3.sdk/usr/lib -stdlib=libc++  -liconv
#export LDFLAGS=-arch arm64 -isysroot /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS14.3.sdk -L/Users/Shared/xbmc-depends/iphoneos14.3_arm64-target-debug/lib -stdlib=libc++ -liconv -lintl -lc -ldl -lm -lexpat -lffi -lintl -lssl
#export OTHER_LDFLAGS=-search_dylibs_first -syslibroot $(SDKROOT) -isysroot /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS14.3.sdk -ios_version_min 11.0

#export LDSHARED="ld -arch arm64 -L/Users/Shared/xbmc-depends/iphoneos14.3_arm64-target-debug/lib -L/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator14.3.sdk/usr/lib -miphoneos-version-min=11.0"
#export LDFLAGS=-arch arm64 -isysroot /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS14.3.sdk -L/Users/Shared/xbmc-depends/iphoneos14.3_arm64-target-debug/lib -L/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS14.3.sdk/usr/lib
#export OTHER_LDFLAGS=-search_dylibs_first -L/Users/Shared/xbmc-depends/iphoneos14.3_arm64-target-debug/lib

ifeq ($(OS), darwin_embedded)
  machdep=arm64-apple-ios
  pyplatform=ios-aarch64
  EXTRA_CONFIGURE=ac_cv_func_wait3=no ac_cv_func_wait4=no ac_cv_func_waitpid=no \
                  ac_cv_func_execv=no ac_cv_func_fexecv=no ac_cv_func_getentropy=no \
                  ac_cv_func_setpriority=no ac_cv_func_sendfile=no ac_cv_header_sched_h=no \
                  ac_cv_func_posix_spawn=no ac_cv_func_posix_spawnp=no \
                  ac_cv_func_forkpty=no ac_cv_lib_util_forkpty=no \
                  ac_cv_func_getgroups=no
endif

CONFIG_OPT=--host="$(HOST)" \
           --build="$(BUILD)" \
           PYTHON_FOR_BUILD='_PYTHON_PROJECT_BASE=$(CURDIR)/$(PLATFORM) _PYTHON_HOST_PLATFORM=$(pyplatform) PYTHONPATH=$(CURDIR)/$(PLATFORM)/build/lib.$(pyplatform)-$(PYTHON_VERSION):$(CURDIR)/$(PLATFORM)/Lib _PYTHON_SYSCONFIGDATA_NAME=$(TARGET_PYTHON_SYSCONFIGDATA_NAME) '$(NATIVEPREFIX)/bin/python3 \
           MACHDEP=$(machdep)

# configuration settings
CONFIGURE=./configure $(CONFIG_OPT) --prefix=$(PREFIX) \
           --disable-shared \
           --enable-static \
           --without-ensurepip \
           --disable-framework \
           --with-system-expat \
           --with-system-ffi \
           --without-pymalloc \
           --enable-ipv6 \
           $(EXTRA_CONFIGURE)

LIBDYLIB=$(PLATFORM)/libpython3.8.a

all: .installed-$(PLATFORM)

$(TARBALLS_LOCATION)/$(ARCHIVE):
	cd $(TARBALLS_LOCATION); $(RETRIEVE_TOOL) $(RETRIEVE_TOOL_FLAGS) $(BASE_URL)/$(ARCHIVE)

$(PLATFORM): $(TARBALLS_LOCATION)/$(ARCHIVE) $(DEPS)
	rm -rf $(PLATFORM)/*; mkdir -p $(PLATFORM)
	cd $(PLATFORM); $(ARCHIVE_TOOL) $(ARCHIVE_TOOL_FLAGS) $(TARBALLS_LOCATION)/$(ARCHIVE)
	cp modules.setup $(PLATFORM)/Modules/Setup.local
#	cp Modules.new $(PLATFORM)/Modules/Setup.local
	cd $(PLATFORM); patch -p1 -i ../crosscompile.patch
	cd $(PLATFORM); patch -p1 -i ../android.patch
#	cd $(PLATFORM); patch -p1 -i ../site.patch
ifeq ($(OS), darwin_embedded)
	cd $(PLATFORM); patch -p1 -i ../darwinembed_posixmodule.patch
	cd $(PLATFORM); patch -p1 -i ../darwinembed_config_sub.patch
	cd $(PLATFORM); patch -p1 -i ../darwinembed_configure_ac.patch
	cd $(PLATFORM); patch -p1 -i ../darwinembed_dynloadshlib.patch
endif
# Add -liconv as needed, and add the _scproxy module for darwin
# disable locale altogether for Android
ifeq ($(OS),android)
	cd $(PLATFORM); sed -ie 's|_locale -DPy_BUILD_CORE_BUILTIN _localemodule.c  # -lintl|#_locale -DPy_BUILD_CORE_BUILTIN _localemodule.c  # -lintl|' Modules/Setup
else
	cd $(PLATFORM); sed -ie 's|_locale -DPy_BUILD_CORE_BUILTIN _localemodule.c  # -lintl|_locale -DPy_BUILD_CORE_BUILTIN _localemodule.c   -lintl $(LINK_ICONV)|' Modules/Setup
endif
ifeq ($(OS),osx)
	echo "_scproxy \$$(srcdir)/Modules/_scproxy.c -framework SystemConfiguration -framework CoreFoundation" >> $(PLATFORM)/Modules/Setup
endif
	cd $(PLATFORM); $(AUTORECONF)
	cd $(PLATFORM); $(CONFIGURE)

$(LIBDYLIB): $(PLATFORM)
#	$(MAKE) -C $(PLATFORM) libpython3.8.a
	touch $@

.installed-$(PLATFORM): $(LIBDYLIB)
	$(MAKE) -C $(PLATFORM) install prefix=$(PREFIX)
#	copy _PYTHON_SYSCONFIGDATA to host. This allows host distutils to load target sysconfig for CCompiler info
	cp $(PLATFORM)/build/lib.$(pyplatform)-$(PYTHON_VERSION)/$(TARGET_PYTHON_SYSCONFIGDATA_NAME) $(NATIVEPREFIX)/lib/python$(PYTHON_VERSION)/
	touch $(LIBDYLIB)
	touch $@

clean:
	rm -rf $(PLATFORM) .installed-$(PLATFORM)

distclean::
	rm -rf $(PLATFORM) .installed-$(PLATFORM) $(NATIVEPREFIX)/lib/python$(PYTHON_VERSION)/$(TARGET_PYTHON_SYSCONFIGDATA_NAME)
