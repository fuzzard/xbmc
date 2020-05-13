include ../../Makefile.include
DEPS= ../../Makefile.include Makefile pillow-crosscompile.patch

VERSION.TXT := $(CMAKE_SOURCE_DIR)/version.txt
APP_NAME=$(shell awk '/APP_NAME/ {print tolower($$2)}' $(VERSION.TXT))

# lib name, version
LIBNAME=Pillow
VERSION=5.1.0
BASE_URL=https://files.pythonhosted.org/packages/89/b8/2f49bf71cbd0e9485bb36f72d438421b69b7356180695ae10bd4fd3066f5
SOURCE=$(LIBNAME)-$(VERSION)
ARCHIVE=$(SOURCE).tar.gz

LIBDYLIB=$(PLATFORM)/dist/Pillow-$(VERSION)-py3.7-$(OS)-$(CPU).egg
PYTHONPATH=$(PREFIX)/lib/python3.7/site-packages/
LDSHARED=$(CC) -shared

ifeq ($(OS),android)
LIBDYLIB=$(PREFIX)/share/$(APP_NAME)/addons/script.module.pil/lib/PIL/_imaging.so
PILPATH=$(PREFIX)/share/$(APP_NAME)/addons/script.module.pil
PYTHONPATH=$(PILPATH):$(PREFIX)/lib/python3.7/site-packages/
EXTRALDFLAGS=-L$(PREFIX)/lib/dummy-lib$(APP_NAME)/ -l$(APP_NAME) -lm
else ifeq ($(OS),darwin_embedded)
LIBDYLIB=$(PREFIX)/share/$(APP_NAME)/addons/script.module.pil/lib/PIL/_imaging.so
PILPATH=$(PREFIX)/share/$(APP_NAME)/addons/script.module.pil
PYTHONPATH=$(PILPATH):$(PREFIX)/lib/python3.7/site-packages/
else ifeq ($(OS),osx)
LIBDYLIB=$(PLATFORM)/dist/Pillow-$(VERSION)-py3.7-macosx-10.4-x86_64.egg
endif

ifeq (darwin, $(findstring darwin, $(HOST)))
#ensure that only our target ldflags are passed to the python build
LDSHARED=$(CC) -bundle -undefined dynamic_lookup
endif

CROSSFLAGS=PYTHONXCPREFIX="$(PREFIX)" CC="$(CC) $(CFLAGS)" LDSHARED="$(LDSHARED)" LDFLAGS="$(LDFLAGS) $(EXTRALDFLAGS)" PYTHONPATH="$(PYTHONPATH)"

ifeq ($(CROSS_COMPILING),yes)
PLATFORM_GUESSING=--disable-platform-guessing
endif

all: .installed-$(PLATFORM)

$(TARBALLS_LOCATION)/$(ARCHIVE):
	cd $(TARBALLS_LOCATION); $(RETRIEVE_TOOL) $(RETRIEVE_TOOL_FLAGS) $(BASE_URL)/$(ARCHIVE)

$(PLATFORM): $(TARBALLS_LOCATION)/$(ARCHIVE) $(DEPS)
	rm -rf $(PLATFORM)/*; mkdir -p $(PLATFORM)
	cd $(PLATFORM); $(ARCHIVE_TOOL) $(ARCHIVE_TOOL_FLAGS) $(TARBALLS_LOCATION)/$(ARCHIVE)
	cd $(PLATFORM); patch -p1 -i ../pillow-crosscompile.patch

$(LIBDYLIB): $(PLATFORM)
	mkdir -p $(PLATFORM)/output
	cd $(PLATFORM); $(CROSSFLAGS) $(NATIVEPREFIX)/bin/python3 setup.py build_ext --plat-name $(OS)-$(CPU) --disable-jpeg2000 --disable-webp --disable-imagequant --disable-tiff --disable-webpmux --disable-lcms $(PLATFORM_GUESSING)

.installed-$(PLATFORM): $(LIBDYLIB)
ifeq ($(OS),android)
	mkdir -p $(PREFIX)/share/$(APP_NAME)/addons/script.module.pil/lib
	cd $(PLATFORM); $(CROSSFLAGS) $(NATIVEPREFIX)/bin/python3 setup.py install --install-lib  $(PILPATH)
	cd $(PILPATH)/lib && unzip -o ../Pillow-*.egg
	cd $(PILPATH)/lib/PIL && \
          sed -i -e 's/import sys/import os, sys /' \
                 -e '/__file__/ s/_imaging/lib_imaging/g' \
                 -e 's/pkg_resources.resource_filename(__name__,/os.path.join(os.environ["KODI_ANDROID_LIBS"], /'  _imaging*.py
	cd $(PILPATH) && rm -rf Pillow-*.egg
else ifeq ($(OS),darwin_embedded)
	mkdir -p $(PILPATH)/lib
	cd $(PLATFORM); $(CROSSFLAGS) $(NATIVEPREFIX)/bin/python3 setup.py install --install-lib  $(PILPATH)
	cd $(PILPATH)/lib && unzip -o ../Pillow-*.egg
	cd $(PILPATH) && rm -rf Pillow-*.egg
else
	cd $(PLATFORM); $(CROSSFLAGS) $(NATIVEPREFIX)/bin/python3 setup.py install --prefix=$(PREFIX)
endif
	touch $@

clean:
	$(MAKE) -C $(PLATFORM) clean
	rm -f .installed-$(PLATFORM)

distclean::
	rm -rf $(PLATFORM) .installed-$(PLATFORM)
