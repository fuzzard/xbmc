include ../../Makefile.include PCRE-VERSION ../../download-files.include
DEPS = ../../Makefile.include Makefile PCRE-VERSION tvos-bitcode-fix.patch jit_aarch64.patch ios-clear_cache.patch ../../download-files.include

# configuration settings
CMAKE_OPTIONS=-DPCRE_NEWLINE=ANYCRLF \
              -DPCRE_NO_RECURSE=ON \
              -DPCRE_SUPPORT_JIT=ON \
              -DPCRE_SUPPORT_PCREGREP_JIT=OFF \
              -DPCRE_SUPPORT_UTF=ON \
              -DPCRE_SUPPORT_UNICODE_PROPERTIES=ON \
              -DPCRE_BUILD_PCREGREP=OFF \
              -DPCRE_BUILD_TESTS=OFF

LIBDYLIB=$(PLATFORM)/build/$(BYPRODUCT)

all: .installed-$(PLATFORM)

$(PLATFORM): $(TARBALLS_LOCATION)/$(ARCHIVE).$(HASH_TYPE) $(DEPS)
	rm -rf $(PLATFORM); mkdir -p $(PLATFORM)
	cd $(PLATFORM); $(ARCHIVE_TOOL) $(ARCHIVE_TOOL_FLAGS) $(TARBALLS_LOCATION)/$(ARCHIVE)
	cd $(PLATFORM); mkdir -p build
	cd $(PLATFORM); patch -p1 -i ../tvos-bitcode-fix.patch
	cd $(PLATFORM); patch -p1 -i ../jit_aarch64.patch
	cd $(PLATFORM); patch -p1 -i ../ios-clear_cache.patch
	cd $(PLATFORM)/build; $(CMAKE) $(CMAKE_OPTIONS) ..

$(LIBDYLIB): $(PLATFORM)
	$(MAKE) -C $(PLATFORM)/build

.installed-$(PLATFORM): $(PLATFORM)
	$(MAKE) -C $(PLATFORM)/build install
	touch $@

clean:
	$(MAKE) -C $(PLATFORM)/build clean
	rm -f .installed-$(PLATFORM)

distclean::
	rm -rf $(PLATFORM) .installed-$(PLATFORM)
