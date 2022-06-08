include ../../Makefile.include GETTEXT-VERSION ../../download-files.include
PREFIX=$(NATIVEPREFIX)
PLATFORM=$(NATIVEPLATFORM)
DEPS = ../../Makefile.include Makefile GETTEXT-VERSION ../../download-files.include \
                                02-disable-test-doc.patch

# configuration settings
CONFIGURE=./configure --prefix=$(PREFIX) --disable-shared \
    --disable-csharp \
    --disable-c++ \
    --disable-native-java \
    --disable-java \
    --disable-libasprintf \
    --disable-openmp \
    --disable-curses \
    --disable-acl \
    --disable-nls \
    --with-included-gettext \
    --with-included-glib \
    --with-included-libcroco \
    --with-included-libxml \
    --without-emacs \
    --without-git \
    --without-cvs \
    --without-bzip2 \
    --without-xz

LIBDYLIB=$(PLATFORM)/gettext-tools/src/.libs/libgettextsrc.a

all: .installed-$(PLATFORM)

$(PLATFORM): $(TARBALLS_LOCATION)/$(ARCHIVE).$(HASH_TYPE) $(DEPS)
	rm -rf $(PLATFORM)/*; mkdir -p $(PLATFORM)
	cd $(PLATFORM); $(ARCHIVE_TOOL) $(ARCHIVE_TOOL_FLAGS) $(TARBALLS_LOCATION)/$(ARCHIVE)
	cd $(PLATFORM); patch -p1 -i ../02-disable-test-doc.patch
	cd $(PLATFORM); $(CONFIGURE)

$(LIBDYLIB): $(PLATFORM)
	$(MAKE) -C $(PLATFORM)/libtextstyle
	$(MAKE) -C $(PLATFORM)/gettext-tools

.installed-$(PLATFORM): $(LIBDYLIB)
	$(MAKE) -j1 -C $(PLATFORM)/gettext-tools install
	touch $@

clean:
	$(MAKE) -C $(PLATFORM) clean
	rm -f .installed-$(PLATFORM)

distclean::
	rm -rf $(PLATFORM) .installed-$(PLATFORM)
