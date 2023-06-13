include ../../Makefile.include
PREFIX=$(NATIVEPREFIX)
PLATFORM=$(NATIVEPLATFORM)
DEPS =../../Makefile.include Makefile

APP=$(PLATFORM)/build/TexturePacker

STATIC_BUILD=-DENABLE_STATIC=1

all: .installed-$(PLATFORM)

download:

$(PLATFORM): $(DEPS)
	-rm -rf $(PLATFORM)/*; mkdir -p $(PLATFORM)/build
	cd $(PLATFORM); cp -a ../src/* .
	cd $(PLATFORM)/build; $(CMAKE_FOR_BUILD) -DKODI_SOURCE_DIR=$(CMAKE_SOURCE_DIR) $(STATIC_BUILD) -DARCH_DEFINES="$(NATIVE_ARCH_DEFINES)" $(CMAKE_OPTIONS) ..

$(APP): $(PLATFORM)
	$(MAKE) -C $(PLATFORM)/build

.installed-$(PLATFORM): $(APP)
	$(MAKE) -C $(PLATFORM)/build install
	touch $@

clean:
	$(MAKE) -C $(PLATFORM)/build clean

distclean::
	rm -rf $(PLATFORM) .installed-$(PLATFORM)
	-rm -rf bin
