include ../../Makefile.include LCMS2-VERSION ../../download-files.include
DEPS = ../../Makefile.include Makefile LCMS2-VERSION ../../download-files.include

CONFIGURE=./configure --prefix=$(PREFIX)

export CC CFLAGS LD LDFLAGS

LIBDYLIB=$(PLATFORM)/$(LIBNAME)/.libs/$(LIBNAME).a

all: .installed-$(PLATFORM)

$(PLATFORM): $(TARBALLS_LOCATION)/$(ARCHIVE).$(HASH_TYPE) $(DEPS)
	rm -rf $(PLATFORM)/*; mkdir -p $(PLATFORM)
	cd $(PLATFORM); $(ARCHIVE_TOOL) $(ARCHIVE_TOOL_FLAGS) $(TARBALLS_LOCATION)/$(ARCHIVE)
	cd $(PLATFORM); $(AUTORECONF) -vif
	cd $(PLATFORM); $(CONFIGURE)

$(PLATFORM)/.libs/$(LIBNAME).a: $(PLATFORM)
	$(MAKE) -C $(PLATFORM)

.installed-$(PLATFORM): $(PLATFORM)/.libs/$(LIBNAME).a
	$(MAKE) -C $(PLATFORM) install
	touch $@

clean:
	$(MAKE) -C $(PLATFORM) clean
	rm -f .installed-$(PLATFORM)

distclean::
	rm -rf $(PLATFORM) .installed-$(PLATFORM)