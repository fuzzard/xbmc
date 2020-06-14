include ../../Makefile.include
DEPS= ../../Makefile.include Makefile numpy-crosscompile.patch site.cfg crosscompile-systeminfo.patch crosscompile-ccompiler.patch crosscompile-unixcompiler.patch

# lib name, version
LIBNAME=numpy
VERSION=1.18.5
BASE_URL=https://files.pythonhosted.org/packages/01/1b/d3ddcabd5817be02df0e6ee20d64f77ff6d0d97f83b77f65e98c8a651981
SOURCE=$(LIBNAME)-$(VERSION)
ARCHIVE=$(SOURCE).zip

#CROSSFLAGS=PYTHONXCPREFIX="$(PREFIX)" CC="$(CC) $(CFLAGS)" LDSHARED="$(CC) -shared" LDFLAGS="$(LDFLAGS)" PYTHONPATH="$(PREFIX)/lib/python3.7/site-packages/"

#NUMPYCONFIG=BLAS=None LAPACK=None ATLAS=None

ifeq ($(OS),darwin_embedded)
PILPATH=$(PREFIX)/share/$(APP_NAME)/addons/script.module.numpy
#endif
#ensure that only our target ldflags are passed to the python build
LDSHARED:=$(CC) -bundle -undefined dynamic_lookup $(LDFLAGS)
#CROSSFLAGS=_PYTHON_HOST_PLATFORM= PYTHONXCPREFIX="$(PREFIX)" BLAS=None LAPACK=None ATLAS=None CC="$(CC) $(CFLAGS)" OPT="$(CFLAGS)" CCSHARED="$(CC) $(CFLAGS)" LDFLAGS="$(LDFLAGS)" PYTHONPATH="$(PILPATH):$(PREFIX)/lib/python3.7/site-packages/" LDSHARED="$(LDSHARED)"
CROSSFLAGS=_PYTHON_HOST_PLATFORM= BLAS=None LAPACK=None ATLAS=None CC="$(CC)" CFLAGS="$(CFLAGS) -march=armv8-a" OPT="$(LDFLAGS) -march=armv8-a" LDFLAGS="$(LDFLAGS) -march=armv8-a" PYTHONXCPREFIX="$(PREFIX)"
endif


#ifeq (darwin, $(findstring darwin, $(HOST)))
LIBDYLIB=$(PILPATH)/libnumpy.a
#endif

all: .installed-$(PLATFORM)

$(TARBALLS_LOCATION)/$(ARCHIVE):
	cd $(TARBALLS_LOCATION); $(RETRIEVE_TOOL) $(RETRIEVE_TOOL_FLAGS) $(BASE_URL)/$(ARCHIVE)

$(PLATFORM): $(TARBALLS_LOCATION)/$(ARCHIVE) $(DEPS)
	rm -rf $(PLATFORM)/*; mkdir -p $(PLATFORM)
	cd $(PLATFORM); $(ARCHIVE_TOOL) $(ARCHIVE_TOOL_FLAGS) $(TARBALLS_LOCATION)/$(ARCHIVE)
#	cd $(PLATFORM); patch -p1 -i ../numpy-crosscompile.patch
	cd $(PLATFORM); patch -p1 -i ../crosscompile-systeminfo.patch
	cd $(PLATFORM); patch -p1 -i ../crosscompile-ccompiler.patch
	cd $(PLATFORM); patch -p1 -i ../crosscompile-unixcompiler.patch
	cd $(PLATFORM); cp ../site.cfg ./

$(LIBDYLIB): $(PLATFORM)
	mkdir -p $(PLATFORM)/output
	cd $(PLATFORM); $(CROSSFLAGS) $(NATIVEPREFIX)/bin/python3 setup.py -v build_src --verbose-cfg
#	cd $(PLATFORM); $(CROSSFLAGS) $(NATIVEPREFIX)/bin/python3 setup.py --help-commands

.installed-$(PLATFORM): $(LIBDYLIB)
#ifeq ($(TARGET_PLATFORM),appletvos)
#	mkdir -p $(PILPATH)/lib
#	cd $(PLATFORM); $(CROSSFLAGS) $(NATIVEPREFIX)/bin/python3 setup.py install --install-lib  $(PILPATH)
#	cd $(PILPATH)/lib && unzip -o ../Pillow-*.egg
#	cd $(PILPATH) && rm -rf Pillow-*.egg
#else
#	cd $(PLATFORM); $(CROSSFLAGS) $(NATIVEPREFIX)/bin/python3 setup.py install --prefix=$(PREFIX)
#endif
	touch $@

clean:
	$(MAKE) -C $(PLATFORM) clean
	rm -f .installed-$(PLATFORM)

distclean::
	rm -rf $(PLATFORM) .installed-$(PLATFORM)
