include ../../Makefile.include
DEPS= ../../Makefile.include Makefile pillow-crosscompile.patch

VERSION.TXT := $(CMAKE_SOURCE_DIR)/version.txt
APP_NAME=$(shell awk '/APP_NAME/ {print tolower($$2)}' $(VERSION.TXT))

# lib name, version
LIBNAME=Pillow
VERSION=7.1.2
SOURCE=$(LIBNAME)-$(VERSION)
ARCHIVE=$(SOURCE).tar.gz

# Clear pkg-config data, as it will pull from Native pkg-config incorrectly
ifeq ($(CROSS_COMPILING), yes)
export PKG_CONFIG_PATH=
export PKG_CONFIG_LIBDIR=${PREFIX}/lib/pkgconfig
export PKG_CONFIG_SYSROOT_DIR=${SDKROOT}
endif

ifeq ($(OS),android)
PILPATH=$(PREFIX)/share/$(APP_NAME)/addons/script.module.pil
export PYTHONPATH=$(PILPATH):$(PREFIX)/lib/python3.8/site-packages/
LDFLAGS+= -L$(PREFIX)/lib/dummy-lib$(APP_NAME)/ -l$(APP_NAME) -lm
export LDFLAGS
else ifeq ($(OS),darwin_embedded)
PILPATH=$(PREFIX)/share/$(APP_NAME)/addons/script.module.pil
export PYTHONPATH=$(PILPATH):$(PREFIX)/lib/python$(PYTHON_VERSION)/site-packages/
endif

ifeq (darwin, $(findstring darwin, $(HOST)))
export ZLIB_ROOT="$(SDKROOT)/usr"
endif

BUILD_OPTS=--plat-name $(OS)-$(CPU) --disable-jpeg2000 --disable-webp --disable-imagequant --disable-tiff --disable-webp --disable-webpmux --disable-xcb --disable-lcms --disable-platform-guessing
#CROSSFLAGS=$(ZLIB_ROOT) PYTHONXCPREFIX="$(PREFIX)" CC="$(CC) $(CFLAGS)" LDSHARED="$(LDSHARED)" LDFLAGS="$(LDFLAGS) $(EXTRALDFLAGS)" PYTHONPATH="$(PYTHONPATH)"

all: .installed-$(PLATFORM)

$(TARBALLS_LOCATION)/$(ARCHIVE):
	cd $(TARBALLS_LOCATION); $(RETRIEVE_TOOL) $(RETRIEVE_TOOL_FLAGS) $(BASE_URL)/$(ARCHIVE)

$(PLATFORM): $(TARBALLS_LOCATION)/$(ARCHIVE) $(DEPS)
	rm -rf $(PLATFORM)/*; mkdir -p $(PLATFORM)
	cd $(PLATFORM); $(ARCHIVE_TOOL) $(ARCHIVE_TOOL_FLAGS) $(TARBALLS_LOCATION)/$(ARCHIVE)
#	cd $(PLATFORM); patch -p1 -i ../pillow-crosscompile.patch

$(PILPATH)/lib:
ifeq ($(OS),android)
	mkdir -p $(PILPATH)/lib
else ifeq ($(OS),darwin_embedded)
	mkdir -p $(PILPATH)/lib
endif

.installed-$(PLATFORM): $(PLATFORM) $(PILPATH)/lib
	cd $(PLATFORM); $(CROSSFLAGS) $(NATIVEPREFIX)/bin/python3 setup.py build_ext $(BUILD_OPTS) install --install-lib $(PILPATH)

#	cd $(PLATFORM); source $(NATIVEPREFIX)/bin/$(TARGETENV)/bin/activate; \
#	                python3 setup.py build_ext $(BUILD_OPTS) install --install-lib $(PILPATH) \
#	                deactivate

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
