include ../../Makefile.include LIBCDIO-GPLV3 ../../download-files.include
DEPS = ../../Makefile.include Makefile LIBCDIO-GPLV3 osx.patch ../../download-files.include

# configuration settings
CONFIGURE=cp -f $(CONFIG_SUB) $(CONFIG_GUESS) .; \
          ./configure --prefix=$(PREFIX)  --with-cd-drive=no --with-cd-info=no \
          --with-cdda-player=no --with-cd-read=no --with-iso-info=no --with-iso-read=no --disable-example-progs \
          --disable-cpp-progs --enable-cxx --disable-shared

ifeq ($(OS),android)
  # GLOB is not available until SDK28. Use this god awful shell command to set
  # ac_cv_header_glob_h=no if NDK_LEVEL is less than 28
  $(if $(shell [ $(NDK_LEVEL) -lt 28 ] && echo " "), \
      $(eval CONFIG_OPT := ac_cv_header_glob_h=no), )

  # 32bit android before SDK24 incorrectly uses 64-bit off_t for fseeko when
  # _FILE_OFFSET_BITS=64 is set.
  ifeq ($(MESON_CPU),arm)
    $(if $(shell [ $(NDK_LEVEL) -lt 24 ] && echo " "), \
        $(eval CONFIG_OPT += ac_cv_func_fseeko=no ac_cv_func_fseeko64=no), )
  endif
endif

LIBDYLIB=$(PLATFORM)/lib/driver/.libs/$(LIBNAME).a

all: .installed-$(PLATFORM)


$(PLATFORM): $(DEPS) | $(TARBALLS_LOCATION)/$(ARCHIVE).$(HASH_TYPE)
	rm -rf $(PLATFORM)/*; mkdir -p $(PLATFORM)
	cd $(PLATFORM); $(ARCHIVE_TOOL) $(ARCHIVE_TOOL_FLAGS) $(TARBALLS_LOCATION)/$(ARCHIVE)
ifeq ($(TARGET_PLATFORM),macosx)
	cd $(PLATFORM); patch -p1 -i ../osx.patch
endif
	cd $(PLATFORM); $(AUTORECONF) -vif
	cd $(PLATFORM); $(CONFIGURE) $(CONFIG_OPT)

$(LIBDYLIB): $(PLATFORM)
	$(MAKE) -C $(PLATFORM)/lib

.installed-$(PLATFORM): $(LIBDYLIB)
	$(MAKE) -C $(PLATFORM)/lib install
	$(MAKE) -C $(PLATFORM)/include install
	$(MAKE) -C $(PLATFORM) install-data-am
	touch $@

clean:
	$(MAKE) -C $(PLATFORM) clean
	rm -f .installed-$(PLATFORM)

distclean::
	rm -rf $(PLATFORM) .installed-$(PLATFORM)
