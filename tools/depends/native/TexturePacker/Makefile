include ../../Makefile.include TEXTUREPACKER-VERSION ../../download-files.include
PREFIX=$(NATIVEPREFIX)
PLATFORM=$(NATIVEPLATFORM)
DEPS =../../Makefile.include Makefile TEXTUREPACKER-VERSION ../../download-files.include

APP=$(PLATFORM)/build/TexturePacker

all: .installed-$(PLATFORM)

download:

$(PLATFORM): $(DEPS) | $(TARBALLS_LOCATION)/$(ARCHIVE).$(HASH_TYPE)
	-rm -rf $(PLATFORM)/*; mkdir -p $(PLATFORM)
	cd $(PLATFORM); $(ARCHIVE_TOOL) $(ARCHIVE_TOOL_FLAGS) $(TARBALLS_LOCATION)/$(ARCHIVE)
	mkdir -p $(PLATFORM)/build
	cd $(PLATFORM)/build; $(CMAKE_FOR_BUILD) -DKODI_SOURCE_DIR=${CMAKE_SOURCE_DIR} -DARCH_DEFINES="$(NATIVE_ARCH_DEFINES)" $(CMAKE_OPTIONS) ..

$(APP): $(PLATFORM)
	$(MAKE) -C $(PLATFORM)/build

.installed-$(PLATFORM): $(APP)
	$(MAKE) -C $(PLATFORM)/build install
	touch $@

clean:
	$(MAKE) -C $(PLATFORM)/build clean
	rm -f .installed-$(PLATFORM)

distclean::
	rm -rf $(PLATFORM) .installed-$(PLATFORM)
	-rm -rf bin
