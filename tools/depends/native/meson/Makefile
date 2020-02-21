include ../../Makefile.include
PLATFORM=$(NATIVEPLATFORM)
DEPS=../../Makefile.include Makefile cross-file-setup.sh

# lib name, version
LIBNAME=meson
VERSION=0.51.0
SOURCE=$(LIBNAME)-$(VERSION)
ARCHIVE=$(SOURCE).tar.gz

LIBDYLIB=$(PLATFORM)/build

all: .installed-$(PLATFORM)

$(TARBALLS_LOCATION)/$(ARCHIVE):
	cd $(TARBALLS_LOCATION); $(RETRIEVE_TOOL) $(RETRIEVE_TOOL_FLAGS) $(BASE_URL)/$(ARCHIVE)

$(PLATFORM): $(TARBALLS_LOCATION)/$(ARCHIVE) $(DEPS)
	rm -rf $(PLATFORM)/*; mkdir -p $(PLATFORM)
	cd $(PLATFORM); $(ARCHIVE_TOOL) $(ARCHIVE_TOOL_FLAGS) $(TARBALLS_LOCATION)/$(ARCHIVE)
	cd $(PLATFORM); $(NATIVEPREFIX)/bin/python3 setup.py config

$(LIBDYLIB): $(PLATFORM)
	cd $(PLATFORM); $(NATIVEPREFIX)/bin/python3 setup.py build

.installed-$(PLATFORM): $(LIBDYLIB) cross-file
	cd $(PLATFORM); $(NATIVEPREFIX)/bin/python3 setup.py install --prefix="$(NATIVEPREFIX)"
	touch $@

clean:
	$(MAKE) -C $(PLATFORM) clean
	rm -f .installed-$(PLATFORM)

distclean::
	rm -rf $(PLATFORM) .installed-$(PLATFORM)

cross-file:
	PREFIX="$(PREFIX)" \
	NATIVEPREFIX="$(NATIVEPREFIX)" \
	CC="$(CC)" \
	CXX="$(CXX)" \
	AR="$(AR)" \
	STRIP="$(STRIP)" \
	MESON_SYSTEM="$(MESON_SYSTEM)" \
	MESON_CPU="$(MESON_CPU)" \
	CPU="$(CPU)" \
	CFLAGS="$(CFLAGS)" \
	CXXFLAGS="$(CXXFLAGS)" \
	LDFLAGS="$(LDFLAGS)" \
	./cross-file-setup.sh
