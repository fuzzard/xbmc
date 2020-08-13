include ../../Makefile.include
DEPS= ../../Makefile.include Makefile

VERSION.TXT := $(CMAKE_SOURCE_DIR)/version.txt
APP_NAME=$(shell awk '/APP_NAME/ {print tolower($$2)}' $(VERSION.TXT))

# lib name, version
LIBNAME=lxml
VERSION=4.5.2
BASE_URL=https://github.com/lxml/lxml/archive
SOURCE=$(LIBNAME)-$(VERSION)
ARCHIVE=$(SOURCE).tar.gz

# Clear pkg-config data, as it will pull from Native pkg-config incorrectly
ifeq ($(CROSS_COMPILING), yes)
#export CFLAGS=-fheinous-gnu-extensions -no-cpp-precomp -arch x86_64 -mmacosx-version-min=10.13 -g -D_DEBUG  -isysroot /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX10.15.sdk -isystem /Users/Shared/xbmc-depends/macosx10.15_x86_64-target-debug/include
#export LDFLAGS=-L/Users/Shared/xbmc-depends/macosx10.15_x86_64-target-debug/lib -Wl,-search_paths_first -arch x86_64 -mmacosx-version-min=10.13 -isysroot /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX10.15.sdk -stdlib=libc++  -liconv 
#export CPPFLAGS=-fheinous-gnu-extensions -no-cpp-precomp -arch x86_64 -mmacosx-version-min=10.13 -g -D_DEBUG  -isysroot /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX10.15.sdk -isystem /Users/Shared/xbmc-depends/macosx10.15_x86_64-target-debug/include

export CFLAGS=
export CPPFLAGS=
export LDFLAGS=
export _PYTHON_SYSCONFIGDATA_NAME=_sysconfigdata__darwin_darwin.py
export PKG_CONFIG=${NATIVEPREFIX}/bin/pkg-config
export PKG_CONFIG_PATH=${PREFIX}/lib/pkgconfig
export PKG_CONFIG_LIBDIR=${PREFIX}/lib/pkgconfig
export PKG_CONFIG_SYSROOT_DIR=${SDKROOT}}
endif

ifeq (darwin, $(findstring darwin, $(HOST)))
  SDKPATH:=$(shell xcrun --sdk $(TARGET_PLATFORM) --show-sdk-path)
  LDSHARED:="$(CC) -bundle -undefined dynamic_lookup $(LDFLAGS)"
  ifeq ($(OS),darwin_embedded)
#    ADDONPATH=$(PREFIX)/share/$(APP_NAME)/addons/script.module.numpy
#    PYTHONPATH="$(ADDONPATH):$(PREFIX)/lib/python3.7/site-packages/"
#    LIBDYLIB=$(ADDONPATH)/lib/numpy/core/lib/libnumpy.a
#    # native_cflags are somehow being picked up by distutils. explicitly remove them using this env var and crosscompiler-unixcompiler.patch
#    REMOVECFLAG="$(NATIVE_CFLAGS)"
#    # required for distutils to allow a cross compile build and not enforce host info
    PYTHONHOSTPLATFORM=_PYTHON_HOST_PLATFORM="$(OS)-$(CPU)"
  else ifeq ($(OS),osx)
    ADDONPATH="$(PREFIX)/lib/python3.7/site-packages/"
    PYTHONPATH=$(ADDONPATH)
    PYTHONHOSTPLATFORM=_PYTHON_HOST_PLATFORM="$(OS)-$(CPU)"
    LIBDYLIB=$(PLATFORM)/build/lib.$(OS)-$(CPU)-3.7/lxml
  endif
#  REMOVECFLAG="$(NATIVE_CFLAGS)"
  CROSSFLAGS=$(PYTHONHOSTPLATFORM) PYTHONXCPREFIX="$(PREFIX)" CC="$(CC) -arch $(CPU) --sysroot=$(SDKPATH)" STATIC_CFLAGS="$(CFLAGS)" STATIC_BINARIES=$(LDSHARED) STATIC_INCLUDE_DIRS="$(PREFIX)/include" STATIC_LIBRARY_DIRS="$(PREFIX)/lib" LIBRARY="$(PREFIX)/lib" PYTHONPATH=$(PYTHONPATH)
endif



all: .installed-$(PLATFORM)

$(TARBALLS_LOCATION)/$(ARCHIVE):
	cd $(TARBALLS_LOCATION); $(RETRIEVE_TOOL) $(RETRIEVE_TOOL_FLAGS) $(BASE_URL)/$(ARCHIVE)

$(PLATFORM): $(TARBALLS_LOCATION)/$(ARCHIVE) $(DEPS)
	rm -rf $(PLATFORM)/*; mkdir -p $(PLATFORM)
	cd $(PLATFORM); $(ARCHIVE_TOOL) $(ARCHIVE_TOOL_FLAGS) $(TARBALLS_LOCATION)/$(ARCHIVE)
#	cd $(PLATFORM); patch -p1 -i ../crosscompile-systeminfo.patch
#	cd $(PLATFORM); patch -p1 -i ../crosscompile-unixcompiler.patch

$(LIBDYLIB): $(PLATFORM)
#	mkdir -p $(PLATFORM)/output
	cd $(PLATFORM); $(CROSSFLAGS) $(NATIVEPREFIX)/bin/python3 setup.py build --with-cython --static --auto-rpath

.installed-$(PLATFORM): $(LIBDYLIB)
ifeq ($(OS),darwin_embedded)
#	mkdir -p $(ADDONPATH)/lib
#	cd $(PLATFORM); $(CROSSFLAGS) $(NATIVEPREFIX)/bin/python3 setup.py bdist_egg --dist-dir=$(ADDONPATH)
#	cd $(ADDONPATH)/lib && unzip -o ../numpy-*.egg
#	cd $(ADDONPATH) && rm -rf numpy-*.egg
#else ifeq ($(OS),osx)
#	cd $(PLATFORM); $(CROSSFLAGS) $(NATIVEPREFIX)/bin/python3 setup.py bdist_egg --dist-dir=$(ADDONPATH)
endif
	touch $@

clean:
	$(MAKE) -C $(PLATFORM) clean
	rm -f .installed-$(PLATFORM)

distclean::
	rm -rf $(PLATFORM) .installed-$(PLATFORM)
