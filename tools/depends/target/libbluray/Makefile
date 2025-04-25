include ../../Makefile.include LIBBLURAY-VERSION ../../download-files.include
DEPS = ../../Makefile.include LIBBLURAY-VERSION Makefile ../../download-files.include \
                                  001-darwinembed_DiskArbitration-revert.patch \
                                  002-darwin-dlopen_searchpath.patch \
                                  003-all-java21-buildsupport.patch \
                                  004-all-build_without_bdj.patch \
                                  005-all-symbolvisibility.patch \
                                  006-win-cmake.patch \
                                  007-win-uwp.patch \
                                  008-win-build_fixes.patch \
                                  009-java-9_bdframepeer.patch \
                                  009-java-1.8_bdframepeer.patch

# configuration settings
CONFIGURE=./configure --prefix=$(PREFIX) \
                      --disable-shared \
                      --exec-prefix=$(PREFIX) \
                      --disable-examples \
                      --disable-doxygen-doc

ifeq ($(OS), osx)
  export PATH:=$(PREFIX)/share/ant/bin:$(PATH)
  export ANT_HOME=$(PREFIX)/share/ant

  # libbluray bd jars only build on =< java 17 currently, or upto 21 with buildsupport patch
  JAVA_MAJOR_VER := $(shell java -version 2>&1 | grep -i version | cut -d'"' -f2 | sed -e 's/^1\./1\%/' -e 's/\..*//' -e 's/%/./')

  ifeq ($(shell test $(JAVA_MAJOR_VER) -gt 21; echo $$?),0)
    # Log disable to be able to view on CI
    $(warning libbluray does not support building with Java > 21. Disabling bdjava-jar)
    CONFIGURE+= --disable-bdjava-jar
  else
    ifeq ($(shell test $(JAVA_MAJOR_VER) -gt 8; echo $$?),0)
      JAVA9:=1
    endif
  endif
else
  CONFIGURE+= --disable-bdjava-jar
endif

LIBDYLIB=$(PLATFORM)/.libs/$(BYPRODUCT)

all: .installed-$(PLATFORM)

$(PLATFORM): $(DEPS) | $(TARBALLS_LOCATION)/$(ARCHIVE).$(HASH_TYPE)
	rm -rf $(PLATFORM); mkdir -p $(PLATFORM)
	cd $(PLATFORM); $(ARCHIVE_TOOL) $(ARCHIVE_TOOL_FLAGS) $(TARBALLS_LOCATION)/$(ARCHIVE)
ifeq ($(OS),darwin_embedded)
	cd $(PLATFORM); patch -p1 -i ../001-darwinembed_DiskArbitration-revert.patch
endif
	cd $(PLATFORM); patch -p1 -i ../002-darwin-dlopen_searchpath.patch
	cd $(PLATFORM); patch -p1 -i ../003-all-java21-buildsupport.patch
	cd $(PLATFORM); patch -p1 -i ../004-all-build_without_bdj.patch
	cd $(PLATFORM); patch -p1 -i ../005-all-symbolvisibility.patch
	cd $(PLATFORM); patch -p1 -i ../006-win-cmake.patch
	cd $(PLATFORM); patch -p1 -i ../007-win-uwp.patch
	cd $(PLATFORM); patch -p1 -i ../008-win-build_fixes.patch
ifeq ($(JAVA9),1)
	cd $(PLATFORM); patch -p1 -i ../009-java-9_bdframepeer.patch
else
	cd $(PLATFORM); patch -p1 -i ../009-java-1.8_bdframepeer.patch
endif
	cd $(PLATFORM); ./bootstrap
	cd $(PLATFORM); $(CONFIGURE)

$(LIBDYLIB): $(PLATFORM)
	$(MAKE) -C $(PLATFORM)

.installed-$(PLATFORM): $(LIBDYLIB)
	$(MAKE) -C $(PLATFORM) install
	touch $@

clean:
	$(MAKE) -C $(PLATFORM) clean
	rm -f .installed-$(PLATFORM)

distclean::
	rm -rf $(PLATFORM) .installed-$(PLATFORM)
