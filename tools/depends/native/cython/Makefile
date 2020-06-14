include ../../Makefile.include
PREFIX=$(NATIVEPREFIX)
PLATFORM=$(NATIVEPLATFORM)
DEPS= ../../Makefile.include Makefile

# lib name, version
LIBNAME=Cython
VERSION=0.29.20
BASE_URL=https://files.pythonhosted.org/packages/3f/61/16a435de52fcda15246597a602aab6132cea50bedeb0919cb8874a068a20
ARCHIVE=$(LIBNAME)-$(VERSION).tar.gz

all: .installed-$(PLATFORM)

$(TARBALLS_LOCATION)/$(ARCHIVE):
	cd $(TARBALLS_LOCATION); $(RETRIEVE_TOOL) $(RETRIEVE_TOOL_FLAGS) $(BASE_URL)/$(ARCHIVE)
	cd $(TARBALLS_LOCATION); chmod +x $(ARCHIVE)

$(PLATFORM): $(TARBALLS_LOCATION)/$(ARCHIVE) $(DEPS)
	-rm -rf $(PLATFORM)/*; mkdir -p $(PLATFORM)
	cd $(PLATFORM); $(ARCHIVE_TOOL) $(ARCHIVE_TOOL_FLAGS) $(TARBALLS_LOCATION)/$(ARCHIVE)

.installed-$(PLATFORM): $(PLATFORM)
	cd $(PLATFORM); $(PREFIX)/bin/python3 setup.py install --prefix=$(PREFIX) --no-cython-compile
	touch $@

clean:
	rm -f .installed-$(PLATFORM)

distclean::
	rm -rf $(PLATFORM) .installed-$(PLATFORM)
