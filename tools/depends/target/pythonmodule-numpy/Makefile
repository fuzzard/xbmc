include ../../Makefile.include
DEPS= ../../Makefile.include Makefile crosscompile-systeminfo.patch crosscompile-unixcompiler.patch

VERSION.TXT := $(CMAKE_SOURCE_DIR)/version.txt
APP_NAME=$(shell awk '/APP_NAME/ {print tolower($$2)}' $(VERSION.TXT))

# lib name, version
LIBNAME=numpy
VERSION=1.18.5
BASE_URL=https://files.pythonhosted.org/packages/01/1b/d3ddcabd5817be02df0e6ee20d64f77ff6d0d97f83b77f65e98c8a651981
SOURCE=$(LIBNAME)-$(VERSION)
ARCHIVE=$(SOURCE).zip

ifeq ($(OS),darwin_embedded)
PILPATH=$(PREFIX)/share/$(APP_NAME)/addons/script.module.numpy
#ensure that only our target ldflags are passed to the python build
LDSHARED:=$(CC) -bundle -undefined dynamic_lookup $(LDFLAGS)
SDKPATH:=$(shell xcrun --sdk iphoneos --show-sdk-path)
CROSSFLAGS=_PYTHON_HOST_PLATFORM="$(OS)-$(CPU)" PYTHONXCPREFIX="$(PREFIX)" BLAS=None LAPACK=None ATLAS=None CC="$(CC) -arch $(CPU) --sysroot=$(SDKPATH)" OPT="$(CFLAGS) $(LDFLAGS)" LDSHARED="$(LDSHARED)" PYTHONPATH="$(PILPATH):$(PREFIX)/lib/python3.7/site-packages/"
LIBDYLIB=$(PILPATH)/libnumpy.a
endif

all: .installed-$(PLATFORM)

$(TARBALLS_LOCATION)/$(ARCHIVE):
	cd $(TARBALLS_LOCATION); $(RETRIEVE_TOOL) $(RETRIEVE_TOOL_FLAGS) $(BASE_URL)/$(ARCHIVE)

$(PLATFORM): $(TARBALLS_LOCATION)/$(ARCHIVE) $(DEPS)
	rm -rf $(PLATFORM)/*; mkdir -p $(PLATFORM)
	cd $(PLATFORM); $(ARCHIVE_TOOL) $(ARCHIVE_TOOL_FLAGS) $(TARBALLS_LOCATION)/$(ARCHIVE)
	cd $(PLATFORM); patch -p1 -i ../crosscompile-systeminfo.patch
	cd $(PLATFORM); patch -p1 -i ../crosscompile-unixcompiler.patch

$(LIBDYLIB): $(PLATFORM)
	mkdir -p $(PLATFORM)/output
	cd $(PLATFORM); $(CROSSFLAGS) $(NATIVEPREFIX)/bin/python3 setup.py build_ext --plat-name $(OS)-$(CPU)

.installed-$(PLATFORM): $(LIBDYLIB)
ifeq ($(OS),darwin_embedded)
	mkdir -p $(PILPATH)/lib
	cd $(PLATFORM); $(CROSSFLAGS) $(NATIVEPREFIX)/bin/python3 setup.py bdist_egg --dist-dir=$(PILPATH)
	cd $(PILPATH)/lib && unzip -o ../numpy-*.egg
	cd $(PILPATH) && rm -rf numpy-*.egg
endif
	touch $@

clean:
	$(MAKE) -C $(PLATFORM) clean
	rm -f .installed-$(PLATFORM)

distclean::
	rm -rf $(PLATFORM) .installed-$(PLATFORM)
