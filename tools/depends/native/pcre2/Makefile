include ../../Makefile.include PCRE2-VERSION ../../download-files.include
PREFIX=$(NATIVEPREFIX)
PLATFORM=$(NATIVEPLATFORM)
DEPS = ../../Makefile.include Makefile PCRE2-VERSION ../../download-files.include

CMAKE_OPTIONS=-DBUILD_STATIC_LIBS=ON \
              -DPCRE2_BUILD_PCRE2_8=ON \
              -DPCRE2_BUILD_PCRE2_16=OFF \
              -DPCRE2_BUILD_PCRE2_32=OFF \
              -DPCRE2_SUPPORT_JIT=ON \
              -DPCRE2_SUPPORT_UNICODE=ON \
              -DPCRE2_BUILD_PCRE2GREP=OFF \
              -DPCRE2_BUILD_TESTS=OFF

LIBDYLIB=$(PLATFORM)/build/libpcre2-8.a

all: .installed-$(PLATFORM)

$(PLATFORM): $(DEPS) | $(TARBALLS_LOCATION)/$(ARCHIVE).$(HASH_TYPE)
	rm -rf $(PLATFORM)/*; mkdir -p $(PLATFORM)/build
	cd $(PLATFORM); $(ARCHIVE_TOOL) $(ARCHIVE_TOOL_FLAGS) $(TARBALLS_LOCATION)/$(ARCHIVE)
	cd $(PLATFORM)/build; $(CMAKE_FOR_BUILD) $(CMAKE_OPTIONS) ..

$(LIBDYLIB): $(PLATFORM)
	$(MAKE) -C $(PLATFORM)/build

.installed-$(PLATFORM): $(LIBDYLIB)
	$(MAKE) -C $(PLATFORM)/build install
	touch $@

clean:
	$(MAKE) -C $(PLATFORM)/build clean
	rm -f .installed-$(PLATFORM)

distclean::
	rm -rf $(PLATFORM) .installed-$(PLATFORM)
