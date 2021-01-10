include ../../Makefile.include
DEPS= ../../Makefile.include Makefile pillow-crosscompile.patch

VERSION.TXT := $(CMAKE_SOURCE_DIR)/version.txt
APP_NAME=$(shell awk '/APP_NAME/ {print tolower($$2)}' $(VERSION.TXT))

# lib name, version
LIBNAME=Pillow
VERSION=8.1.0
SOURCE=$(LIBNAME)-$(VERSION)
ARCHIVE=$(SOURCE).tar.gz

BASE_URL=https://files.pythonhosted.org/packages/73/59/3192bb3bc554ccbd678bdb32993928cb566dccf32f65dac65ac7e89eb311

# Clear pkg-config data, as it will pull from Native pkg-config incorrectly
ifeq ($(CROSS_COMPILING), yes)
export PKG_CONFIG_PATH=
export PKG_CONFIG_LIBDIR=${PREFIX}/lib/pkgconfig
export PKG_CONFIG_SYSROOT_DIR=${SDKROOT}
endif

PILPATH=$(PYTHON_SITE_PKG)
PYTHONPATH=$(PYTHON_SITE_PKG)
ifeq ($(OS),android)
PILPATH=$(PREFIX)/share/$(APP_NAME)/addons/script.module.pil
export PYTHONPATH=$(PILPATH):$(PYTHON_SITE_PKG)
LDFLAGS+= -L$(PREFIX)/lib/dummy-lib$(APP_NAME)/ -l$(APP_NAME) -lm
else ifeq ($(OS),darwin_embedded)
PILPATH=$(PREFIX)/share/$(APP_NAME)/addons/script.module.pil
PYTHONPATH=$(PILPATH):$(PYTHON_SITE_PKG)
endif

CCSHARED=$(CC) $(CFLAGS)
LDSHARED=$(CC) $(LDFLAGS)

ifeq (darwin, $(findstring darwin, $(HOST)))
export ZLIB_ROOT="$(SDKROOT)/usr"
LDSHARED=$(CC) -bundle -undefined dynamic_lookup $(LDFLAGS)
endif

export LDSHARED CCSHARED PYTHONPATH
export _PYTHON_SYSCONFIGDATA_NAME=$(TARGET_PYTHON_SYSCONFIGDATA_NAME)
export _PYTHON_HOST_PLATFORM=darwin

BUILD_OPTS=--plat-name $(OS)-$(CPU) --disable-jpeg2000 --disable-webp --disable-imagequant --disable-tiff --disable-webp --disable-webpmux --disable-xcb --disable-lcms --disable-platform-guessing

all: .installed-$(PLATFORM)

$(TARBALLS_LOCATION)/$(ARCHIVE):
	cd $(TARBALLS_LOCATION); $(RETRIEVE_TOOL) $(RETRIEVE_TOOL_FLAGS) $(BASE_URL)/$(ARCHIVE)

$(PLATFORM): $(TARBALLS_LOCATION)/$(ARCHIVE) $(DEPS)
	rm -rf $(PLATFORM)/*; mkdir -p $(PLATFORM)
	cd $(PLATFORM); $(ARCHIVE_TOOL) $(ARCHIVE_TOOL_FLAGS) $(TARBALLS_LOCATION)/$(ARCHIVE)

$(PILPATH)/lib:
ifeq ($(OS),android)
	mkdir -p $(PILPATH)/lib
else ifeq ($(OS),darwin_embedded)
	mkdir -p $(PILPATH)/lib
endif

.installed-$(PLATFORM): $(PLATFORM) $(PILPATH)/lib
	cd $(PLATFORM); $(NATIVEPREFIX)/bin/python3 setup.py build_ext $(BUILD_OPTS) install --install-lib $(PILPATH)

ifeq ($(OS),android)
	cd $(PILPATH)/lib && unzip -o ../Pillow-*.egg
	cd $(PILPATH)/lib/PIL && \
         sed -i -e 's/import sys/import os, sys /' \
                 -e '/__file__/ s/_imaging/lib_imaging/g' \
                 -e 's/pkg_resources.resource_filename(__name__,/os.path.join(os.environ["KODI_ANDROID_LIBS"], /'  _imaging*.py
	cd $(PILPATH) && rm -rf Pillow-*.egg
else ifeq ($(OS),darwin_embedded)
	cd $(PILPATH)/lib && unzip -o ../Pillow-*.egg
	cd $(PILPATH) && rm -rf Pillow-*.egg
endif
	touch $@

clean:
	$(MAKE) -C $(PLATFORM) clean
	rm -f .installed-$(PLATFORM)

distclean::
	rm -rf $(PLATFORM) .installed-$(PLATFORM)
