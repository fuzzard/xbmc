include ../../Makefile.include
DEPS= ../../Makefile.include Makefile 01-nosetuptool.patch 02-android-dlopen.patch 03-obey-crosscompileflags.patch

VERSION.TXT := $(CMAKE_SOURCE_DIR)/version.txt
APP_NAME=$(shell awk '/APP_NAME/ {print tolower($$2)}' $(VERSION.TXT))

# lib name, version
LIBNAME=pycryptodome
#VERSION=3.9.9
VERSION=3.4.3
SOURCE=$(LIBNAME)-$(VERSION)
ARCHIVE=$(SOURCE).tar.gz

#BASE_URL=https://files.pythonhosted.org/packages/c4/3a/5bca2cb1648b171afd6b7d29a11c6bca8b305bb75b7e2d78a0f5c61ff95e

export PYTHONPATH=$(PREFIX)/lib/python3.8/site-packages/
ifeq ($(OS),android)
LDFLAGS+= -L$(PREFIX)/lib/dummy-lib$(APP_NAME)/ -l$(APP_NAME) -lm
endif

ifeq (darwin, $(findstring darwin, $(HOST)))
LDSHARED:=$(CC) -bundle -undefined dynamic_lookup $(LDFLAGS)
CC+= $(CFLAGS)
export CC LDSHARED
endif

export _PYTHON_SYSCONFIGDATA_NAME="$(TARGET_PYTHON_SYSCONFIGDATA_NAME)"
export LDFLAGS

LIBDYLIB=$(PLATFORM)/build/lib.$(OS)-$(CPU)-$(PYTHON_VERSION)/Cryptodome
ifeq ($(NATIVE_OS), osx)
	LIBDYLIB=$(PLATFORM)/build/lib.macosx-10.4-x86_64-$(PYTHON_VERSION)/Cryptodome
endif

all: .installed-$(PLATFORM)

$(TARBALLS_LOCATION)/$(ARCHIVE):
	cd $(TARBALLS_LOCATION); $(RETRIEVE_TOOL) $(RETRIEVE_TOOL_FLAGS) $(BASE_URL)/$(ARCHIVE)

$(PLATFORM): $(TARBALLS_LOCATION)/$(ARCHIVE) $(DEPS)
	rm -rf $(PLATFORM)/*; mkdir -p $(PLATFORM)
	cd $(PLATFORM); $(ARCHIVE_TOOL) $(ARCHIVE_TOOL_FLAGS) $(TARBALLS_LOCATION)/$(ARCHIVE)
	cd $(PLATFORM); patch -p1 -i ../01-nosetuptool.patch
ifeq ($(OS),android)
	cd $(PLATFORM); patch -p1 -i ../02-android-dlopen.patch
endif
	cd $(PLATFORM); patch -p1 -i ../03-obey-crosscompileflags.patch

$(LIBDYLIB): $(PLATFORM)
	mkdir -p $(PLATFORM)/output
	cd $(PLATFORM); touch .separate_namespace && $(NATIVEPREFIX)/bin/python3 setup.py build_ext --plat-name $(OS)-$(CPU)

.installed-$(PLATFORM): $(LIBDYLIB)
	cd $(PLATFORM); $(NATIVEPREFIX)/bin/python3 setup.py install --prefix=$(PREFIX)
	touch $@

clean:
	$(MAKE) -C $(PLATFORM) clean
	rm -f .installed-$(PLATFORM)

distclean::
	rm -rf $(PLATFORM) .installed-$(PLATFORM)
