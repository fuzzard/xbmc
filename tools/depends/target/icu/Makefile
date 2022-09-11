include ../../Makefile.include ICU-VERSION ../../download-files.include
DEPS = ../../Makefile.include ICU-VERSION Makefile ../../download-files.include

# configuration settings
CONFIGURE=./configure \
                      --enable-static \
                      --enable-release \
                      --enable-extras=no \
                      --enable-tools=no \
                      --with-data-packaging=static \
                      --enable-tests=no \
                      --enable-samples=no \
                      --prefix=$(PREFIX) \
                      --host=$(HOST) \
--with-cross-build=$(abs_top_srcdir)/native/icu/$(NATIVEPLATFORM)/icu4c/source

LIBDYLIB=$(PLATFORM)/.libs/$(BYPRODUCT)

export CFLAGS LDFLAGS CPPFLAGS CXXFLAGS
export CC

export LD
export CC
export CXX
export CPP
export AR
export AS
export NM
export STRIP
export RANLIB
export OBJDUMP

all: .installed-$(PLATFORM)

$(PLATFORM): $(TARBALLS_LOCATION)/$(ARCHIVE).$(HASH_TYPE) $(DEPS)
	rm -rf $(PLATFORM); mkdir -p $(PLATFORM)
	cd $(PLATFORM); $(ARCHIVE_TOOL) $(ARCHIVE_TOOL_FLAGS) $(TARBALLS_LOCATION)/$(ARCHIVE)
	cd $(PLATFORM)/icu4c/source; $(CONFIGURE)

$(LIBDYLIB): $(PLATFORM)
	$(MAKE) -C $(PLATFORM)/icu4c/source

.installed-$(PLATFORM): $(LIBDYLIB)
	$(MAKE) -C $(PLATFORM)/icu4c/source install
	touch $@

clean:
	$(MAKE) -C $(PLATFORM) clean
	rm -f .installed-$(PLATFORM)

distclean::
	rm -rf $(PLATFORM) .installed-$(PLATFORM)
