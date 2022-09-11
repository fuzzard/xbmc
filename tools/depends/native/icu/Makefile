include ../../Makefile.include ICU-VERSION ../../download-files.include
DEPS = ../../Makefile.include ICU-VERSION Makefile ../../download-files.include
PREFIX=$(NATIVEPREFIX)
PLATFORM=$(NATIVEPLATFORM)

# configuration settings
CONFIGURE=./configure \
                      --enable-static \
                      --enable-release \
                      --enable-extras=no \
                      --enable-tools=yes \
                      --with-data-packaging=static \
                      --enable-tests=no \
                      --enable-samples=no \
                      --prefix=$(PREFIX) \
                      --host=$(BUILD)


LIBDYLIB=$(PLATFORM)/.libs/$(BYPRODUCT)



export LD=$(LD_FOR_BUILD)
export CC=$(CC_FOR_BUILD)
export CXX=$(CXX_FOR_BUILD)
export AR=$(AR_FOR_BUILD)
export AS=$(AS_FOR_BUILD)
export NM=$(NM_FOR_BUILD)
export STRIP=$(STRIP_FOR_BUILD)
export RANLIB=$(RANLIB_FOR_BUILD)
export OBJDUMP=$(OBJDUMP_FOR_BUILD)

export CFLAGS=$(NATIVE_CFLAGS)
export LDFLAGS=$(NATIVE_LDFLAGS)
export CPPFLAGS=$(NATIVE_CPPFLAGS)
export CXXFLAGS=$(NATIVE_CXXFLAGS)

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
