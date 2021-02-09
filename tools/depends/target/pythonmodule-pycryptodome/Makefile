include ../../Makefile.include
DEPS= ../../Makefile.include Makefile 01-nosetuptool.patch 02-android-dlopen.patch

# lib name, version
LIBNAME=pycryptodome
VERSION=3.4.3
SOURCE=$(LIBNAME)-$(VERSION)
ARCHIVE=$(SOURCE).tar.gz

ifeq ($(OS),android)
  LDFLAGS+= -L$(PREFIX)/lib/dummy-lib$(APP_NAME)/ -l$(APP_NAME) -lm
endif

ifeq ($(TARGET_PLATFORM),appletvos)
  # -fembedbitcode means we cannot do any undefined things like -undefined, -U<symbol>
  # At linktime, have to supply static link flags
  export LDSHARED=$(CC) $(PYTHON_MODULELDFLAGS) $(LDFLAGS)
endif

export PYTHONPATH=$(PYTHON_SITE_PKG)

export CC CFLAGS LDFLAGS PYTHONPATH

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

$(PLATFORM)/.separate_namespace: $(PLATFORM)
	cd $(PLATFORM); touch ../$@ && $(NATIVEPREFIX)/bin/python3 setup.py build_ext --plat-name $(OS)-$(TARGET_ARCH)

.installed-$(PLATFORM): $(PLATFORM)/.separate_namespace
	cd $(PLATFORM); $(NATIVEPREFIX)/bin/python3 setup.py install --prefix=$(PREFIX)
	touch $@

clean:
	$(MAKE) -C $(PLATFORM) clean
	rm -f .installed-$(PLATFORM)

distclean::
	rm -rf $(PLATFORM) .installed-$(PLATFORM)
