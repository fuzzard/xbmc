include ../../Makefile.include
DEPS= ../../Makefile.include Makefile 01-nosetuptool.patch 02-android-dlopen.patch 03-obey-crosscompileflags.patch

VERSION.TXT := $(CMAKE_SOURCE_DIR)/version.txt
APP_NAME=$(shell awk '/APP_NAME/ {print tolower($$2)}' $(VERSION.TXT))

# lib name, version
LIBNAME=pycryptodome
VERSION=3.4.3
SOURCE=$(LIBNAME)-$(VERSION)
ARCHIVE=$(SOURCE).tar.gz

export PYTHONPATH=$(PYTHON_SITE_PKG)
ifeq ($(OS),android)
LDFLAGS+= -L$(PREFIX)/lib/dummy-lib$(APP_NAME)/ -l$(APP_NAME) -lm
endif

ifeq (darwin, $(findstring darwin, $(HOST)))
LDSHARED:=$(CC) -bundle -undefined dynamic_lookup
CC+= $(CFLAGS)
endif

export CC LDSHARED LDFLAGS

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

.installed-$(PLATFORM): $(PLATFORM)
	cd $(PLATFORM); touch .separate_namespace && $(NATIVEPREFIX)/bin/python3 setup.py build install --prefix=$(PREFIX)
	touch $@

clean:
	rm -f .installed-$(PLATFORM)

distclean::
	rm -rf $(PLATFORM) .installed-$(PLATFORM)
