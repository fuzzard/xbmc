include ../../Makefile.include LIBAACS-VERSION ../../download-files.include
DEPS = ../../Makefile.include LIBAACS-VERSION Makefile ../../download-files.include

# configuration settings
CONFIGURE=./configure --prefix=$(PREFIX) \
                      --disable-static \
                      --with-libgcrypt-prefix=$(PREFIX)/bin \
                      --with-gpg-error-prefix=$(PREFIX)/bin

LIBSYM=libaacs.*.so
ifeq ($(OS),osx)
  BYPRODUCT=libaacs.dylib
  LIBSYM=libaacs.*.dylib
endif

LIBDYLIB=$(PLATFORM)/.libs/$(BYPRODUCT)

all: .installed-$(PLATFORM)

$(PLATFORM): $(DEPS) | $(TARBALLS_LOCATION)/$(ARCHIVE).$(HASH_TYPE)
	rm -rf $(PLATFORM); mkdir -p $(PLATFORM)
	cd $(PLATFORM); $(ARCHIVE_TOOL) $(ARCHIVE_TOOL_FLAGS) $(TARBALLS_LOCATION)/$(ARCHIVE)
	cd $(PLATFORM); ./bootstrap
	cd $(PLATFORM); $(CONFIGURE)

$(LIBDYLIB): $(PLATFORM)
	$(MAKE) -C $(PLATFORM)

.installed-$(PLATFORM): $(LIBDYLIB)
	$(MAKE) -C $(PLATFORM) install
# Remove symlink and rename shared lib to libaacs.<extension>
	rm -f $(PREFIX)/lib/$(BYPRODUCT)
	mv $(PREFIX)/lib/$(LIBSYM) $(PREFIX)/lib/$(BYPRODUCT)
	touch $@

clean:
	$(MAKE) -C $(PLATFORM) clean
	rm -f .installed-$(PLATFORM)

distclean::
	rm -rf $(PLATFORM) .installed-$(PLATFORM)
