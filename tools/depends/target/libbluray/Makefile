include ../../Makefile.include LIBBLURAY-VERSION ../../download-files.include
DEPS = ../../Makefile.include Makefile LIBBLURAY-VERSION 001-darwinembed_DiskArbitration-revert.patch tvos.patch ../../download-files.include

# configuration settings
CONFIGURE=./configure --prefix=$(PREFIX) --disable-shared --exec-prefix=$(PREFIX) \
  --disable-examples --disable-doxygen-doc \
  --disable-bdjava-jar

LIBDYLIB=$(PLATFORM)/.libs/$(BYPRODUCT)

all: .installed-$(PLATFORM)

$(PLATFORM): $(TARBALLS_LOCATION)/$(ARCHIVE).$(HASH_TYPE) $(DEPS)
	rm -rf $(PLATFORM); mkdir -p $(PLATFORM)
	cd $(PLATFORM); $(ARCHIVE_TOOL) $(ARCHIVE_TOOL_FLAGS) $(TARBALLS_LOCATION)/$(ARCHIVE)
	cd $(PLATFORM); ./bootstrap
	cd $(PLATFORM); $(CONFIGURE)
ifeq ($(OS),darwin_embedded)
	cd $(PLATFORM); patch -p1 -i ../001-darwinembed_DiskArbitration-revert.patch
endif
ifeq ($(TARGET_PLATFORM),appletvos)
	cd $(PLATFORM); patch -p1 -i ../tvos.patch
endif

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
