include ../../Makefile.include
DEPS= ../../Makefile.include Makefile pillow-crosscompile.patch

VERSION.TXT := $(CMAKE_SOURCE_DIR)/version.txt
APP_NAME=$(shell awk '/APP_NAME/ {print tolower($$2)}' $(VERSION.TXT))

# lib name, version
LIBNAME=Pillow
VERSION=7.1.2
SOURCE=$(LIBNAME)-$(VERSION)
ARCHIVE=$(SOURCE).tar.gz

PYTHONPATH=$(PYTHON_SITE_PKG)
PILPATH=$(PYTHONPATH)
LDSHARED=$(CC) -shared

# Clear pkg-config data, as it will pull from Native pkg-config incorrectly
ifeq ($(CROSS_COMPILING), yes)
export PKG_CONFIG_PATH=
export PKG_CONFIG_LIBDIR=${PREFIX}/lib/pkgconfig
export PKG_CONFIG_SYSROOT_DIR=${SDKROOT}
endif

ifeq ($(OS),android)
PILPATH=$(PREFIX)/share/$(APP_NAME)/addons/script.module.pil
PYTHONPATH=$(PILPATH):$(PYTHON_SITE_PKG)
EXTRALDFLAGS=-L$(PREFIX)/lib/dummy-lib$(APP_NAME)/ -l$(APP_NAME) -lm
else ifeq ($(OS),darwin_embedded)
PILPATH=$(PREFIX)/share/$(APP_NAME)/addons/script.module.pil
PYTHONPATH=$(PILPATH):$(PYTHON_SITE_PKG)
ifeq ($(OS),darwin_embedded)
CFLAGS:=$(CFLAGS) -target arm64-apple-darwin
endif
endif

ifeq (darwin, $(findstring darwin, $(HOST)))
#ensure that only our target ldflags are passed to the python build
LDSHARED=$(CC) -bundle -undefined dynamic_lookup
ZLIB_ROOT=ZLIB_ROOT="$(SDKROOT)/usr"
endif

BUILD_OPTS=--plat-name $(OS)-$(CPU) --disable-jpeg2000 --disable-webp --disable-imagequant --disable-tiff --disable-webp --disable-webpmux --disable-xcb --disable-lcms --disable-platform-guessing
CROSSFLAGS=$(ZLIB_ROOT) PYTHONXINCLUDE="$(PREFIX)/include/python$(PYTHON_VERSION)" PYTHONXCPREFIX="$(PREFIX)" CC="$(CC)" CFLAGS="$(CFLAGS)" LDSHARED="$(LDSHARED)" LDFLAGS="$(LDFLAGS) $(EXTRALDFLAGS)" PYTHONPATH="$(PYTHONPATH)"

all: .installed-$(PLATFORM)

$(TARBALLS_LOCATION)/$(ARCHIVE):
	cd $(TARBALLS_LOCATION); $(RETRIEVE_TOOL) $(RETRIEVE_TOOL_FLAGS) $(BASE_URL)/$(ARCHIVE)

$(PLATFORM): $(TARBALLS_LOCATION)/$(ARCHIVE) $(DEPS)
	rm -rf $(PLATFORM)/*; mkdir -p $(PLATFORM)
	cd $(PLATFORM); $(ARCHIVE_TOOL) $(ARCHIVE_TOOL_FLAGS) $(TARBALLS_LOCATION)/$(ARCHIVE)
	cd $(PLATFORM); patch -p1 -i ../pillow-crosscompile.patch

.installed-$(PLATFORM): $(PLATFORM)
	cd $(PLATFORM); $(CROSSFLAGS) $(NATIVEPREFIX)/bin/python3 setup.py build_ext $(BUILD_OPTS) build --build-platlib $(PILPATH)
ifeq ($(OS),android)
	cd $(PILPATH)/PIL && \
          sed -i -e 's/import sys/import os, sys /' \
                 -e '/__file__/ s/_imaging/lib_imaging/g' \
                 -e 's/pkg_resources.resource_filename(__name__,/os.path.join(os.environ["KODI_ANDROID_LIBS"], /'  _imaging*.py
endif
	touch $@

clean:
	$(MAKE) -C $(PLATFORM) clean
	rm -f .installed-$(PLATFORM)
	rm -rf $(PILPATH)/PIL

distclean::
	rm -rf $(PLATFORM) .installed-$(PLATFORM)
	rm -rf $(PILPATH)/PIL
