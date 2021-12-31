include ../../Makefile.include
DEPS= ../../Makefile.include Makefile

# We use uuid from e2fsprogs since this easily cross-compiles on android, while util-linux does not.
# lib name, version
LIBNAME=libuuid
VERSION=2.37.2
SOURCE=util-linux-$(VERSION)
ARCHIVE=$(SOURCE).tar.xz

BASE_URL=https://mirrors.edge.kernel.org/pub/linux/utils/util-linux/v2.37

LIBDYLIB=$(PLATFORM)/lib/$(LIBNAME).a

all: .installed-$(PLATFORM)

$(TARBALLS_LOCATION)/$(ARCHIVE):
	cd $(TARBALLS_LOCATION); $(RETRIEVE_TOOL) $(RETRIEVE_TOOL_FLAGS) $(BASE_URL)/$(ARCHIVE)

$(PLATFORM): $(TARBALLS_LOCATION)/$(ARCHIVE) $(DEPS)
	rm -rf $(PLATFORM)/*; mkdir -p $(PLATFORM)
	cd $(PLATFORM); $(ARCHIVE_TOOL) $(ARCHIVE_TOOL_FLAGS) $(TARBALLS_LOCATION)/$(ARCHIVE)
	cd $(PLATFORM); ./configure --prefix=$(PREFIX) --disable-all-programs --enable-libuuid

$(LIBDYLIB): $(PLATFORM)
	cd $(PLATFORM); $(MAKE)

.installed-$(PLATFORM): $(LIBDYLIB)
	cd $(PLATFORM); $(MAKE) install
	touch $@

clean:
	$(MAKE) -C $(PLATFORM) clean
	rm -f .installed-$(PLATFORM)

distclean::
	rm -rf $(PLATFORM) .installed-$(PLATFORM)
