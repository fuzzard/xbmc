include ../../Makefile.include
DEPS= ../../Makefile.include Makefile

# lib name, version
LIBNAME=lxml
VERSION=4.6.2
BASE_URL=https://github.com/lxml/lxml/archive
SOURCE=$(LIBNAME)-$(VERSION)
ARCHIVE=$(SOURCE).tar.gz

ENVFLAGS:=STATIC_CFLAGS="$(CFLAGS)" STATIC_INCLUDE_DIRS="$(PREFIX)/include" STATIC_LIBRARY_DIRS="$(PREFIX)/lib" LIBRARY="$(PREFIX)/lib"

PILPATH=$(PYTHON_SITE_PKG)
PILPATHLIB:=$(PILPATH)
ifeq ($(OS),android)
  PILPATH=$(PREFIX)/share/$(APP_NAME)/addons/script.module.lxml
  PILPATHLIB:=$(PILPATH)/lib
else ifeq ($(OS),darwin_embedded)
  PILPATH=$(PREFIX)/share/$(APP_NAME)/addons/script.module.lxml
  PILPATHLIB:=$(PILPATH)/lib
endif

BDISTEGG=./$(PLATFORM)/dist/$(LIBNAME)-$(VERSION)-py$(PYTHON_VERSION)-*.egg

all: .installed-$(PLATFORM)

$(TARBALLS_LOCATION)/$(ARCHIVE):
	cd $(TARBALLS_LOCATION); $(RETRIEVE_TOOL) $(RETRIEVE_TOOL_FLAGS) $(BASE_URL)/$(ARCHIVE)

$(PLATFORM): $(TARBALLS_LOCATION)/$(ARCHIVE) $(DEPS)
	rm -rf $(PLATFORM)/*; mkdir -p $(PLATFORM)
	cd $(PLATFORM); $(ARCHIVE_TOOL) $(ARCHIVE_TOOL_FLAGS) $(TARBALLS_LOCATION)/$(ARCHIVE)
ifeq ($(findstring apple-darwin, $(HOST)), apple-darwin)
	# lxml module explicitly adds an osx sdk path to ldflags. remove this and rely on 
	# our environment flags
	cd $(PLATFORM); patch -p1 -i ../apple-removeldflag.patch
endif	

# Android and Darwinembedded platforms require the egg to be extracted to function
# May not be necessary, requires testing without
$(PILPATHLIB):
ifeq ($(OS),android)
	mkdir -p $(PILPATH)/lib
else ifeq ($(OS),darwin_embedded)
	mkdir -p $(PILPATH)/lib
endif

$(BDISTEGG):$(PLATFORM) $(PILPATHLIB)
	. $(NATIVEPREFIX)/bin/$(PYTHON_TARGETENV)/bin/activate \
	&& cd $(PLATFORM) && $(ENVFLAGS) cross-python setup.py \
	build --with-cython --static bdist_egg

.installed-$(PLATFORM): $(BDISTEGG)
	cd $(PLATFORM); cp -rf ./dist/$(LIBNAME)-$(VERSION)-*.egg $(PILPATH)
# Extract the egg for Android/Darwinembedded platforms
# May not be necessary, requires testing without
ifeq ($(OS),android)
	cd $(PILPATH)/lib && unzip -o ../$(LIBNAME)-$(VERSION)-*.egg && rm -rf ../$(LIBNAME)-$(VERSION)-*.egg
else ifeq ($(OS),darwin_embedded)
	cd $(PILPATH)/lib && unzip -o ../$(LIBNAME)-$(VERSION)-*.egg && rm -rf ../$(LIBNAME)-$(VERSION)-*.egg
endif
	touch $@

clean:
	$(MAKE) -C $(PLATFORM) clean
	rm -f .installed-$(PLATFORM)

distclean::
	rm -rf $(PLATFORM) .installed-$(PLATFORM) $(PREFIX)/share/$(APP_NAME)/addons/script.module.lxml
