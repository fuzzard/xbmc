include ../../Makefile.include
DEPS= ../../Makefile.include Makefile

# lib name, version
LIBNAME=numpy
VERSION=1.20.1
BASE_URL=https://github.com/$(LIBNAME)/$(LIBNAME)/archive
SOURCE=v$(VERSION)
ARCHIVE=$(SOURCE).tar.gz

# numpy compilation test fails without arch provided as default computer tests just
# does CC which would do a build native compilation unit, and therefore be incorrect architecture
ifeq ($(CROSS_COMPILING),yes)
  ENVFLAGS:=CC="$(CC) -arch $(CPU)"
endif

ENVFLAGS+= NPY_BLAS_ORDER="" NPY_LAPACK_ORDER="" BLAS=None LAPACK=None ATLAS=None

PILPATH=$(PYTHON_SITE_PKG)
ifeq ($(OS),android)
  PILPATH=$(PREFIX)/share/$(APP_NAME)/addons/script.module.numpy
else ifeq ($(OS),darwin_embedded)
  PILPATH=$(PREFIX)/share/$(APP_NAME)/addons/script.module.numpy
endif

all: .installed-$(PLATFORM)

$(TARBALLS_LOCATION)/$(ARCHIVE):
	cd $(TARBALLS_LOCATION); $(RETRIEVE_TOOL) $(RETRIEVE_TOOL_FLAGS) $(BASE_URL)/$(ARCHIVE)

$(PLATFORM): $(TARBALLS_LOCATION)/$(ARCHIVE) $(DEPS)
	rm -rf $(PLATFORM)/*; mkdir -p $(PLATFORM)
	cd $(PLATFORM); $(ARCHIVE_TOOL) $(ARCHIVE_TOOL_FLAGS) $(TARBALLS_LOCATION)/$(ARCHIVE)

# Android and Darwinembedded platforms require the egg to be extracted to function
# May not be necessary, requires testing without
$(PILPATH)/lib:
ifeq ($(OS),android)
	mkdir -p $(PILPATH)/lib
else ifeq ($(OS),darwin_embedded)
	mkdir -p $(PILPATH)/lib
endif

.installed-$(PLATFORM): $(PLATFORM) $(PILPATH)/lib
	. $(NATIVEPREFIX)/bin/$(PYTHON_TARGETENV)/bin/activate \
	&& cd $(PLATFORM) && $(ENVFLAGS) cross-python setup.py \
		build_ext install --install-lib $(PILPATH)
# Extract the egg for Android/Darwinembedded platforms
# May not be necessary, requires testing without
ifeq ($(OS),android)
	cd $(PILPATH)/lib && cp -rf ../$(LIBNAME)-$(VERSION)-*.egg/* ./ && rm -rf ../$(LIBNAME)-$(VERSION-)*.egg
else ifeq ($(OS),darwin_embedded)
	cd $(PILPATH)/lib && cp -rf ../$(LIBNAME)-$(VERSION)-*.egg/* ./ && rm -rf ../$(LIBNAME)-$(VERSION-)*.egg
endif
	touch $@

clean:
	$(MAKE) -C $(PLATFORM) clean
	rm -f .installed-$(PLATFORM)

distclean::
	rm -rf $(PLATFORM) .installed-$(PLATFORM) $(PREFIX)/share/$(APP_NAME)/addons/script.module.numpy
