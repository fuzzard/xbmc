include ../../Makefile.include SQLITE3-VERSION ../../download-files.include
DEPS = ../../Makefile.include SQLITE3-VERSION Makefile ../../download-files.include \
                                001-Disable-sqlite3bin.patch \
                                sqlite3.c.patch

# configuration settings
export CXXFLAGS+=-DSQLITE_ENABLE_COLUMN_METADATA=1
export CFLAGS+=-DSQLITE_TEMP_STORE=3 -DSQLITE_DEFAULT_MMAP_SIZE=0x10000000 \
               -DSQLITE_ENABLE_MATH_FUNCTIONS \
               -DSQLITE_ENABLE_FTS4 \
               -DSQLITE_ENABLE_FTS5

CONFIGURE=cp -f $(CONFIG_SUB) $(CONFIG_GUESS) .; \
          ./configure --prefix=$(PREFIX) --disable-shared --enable-threadsafe --disable-readline

LIBDYLIB=$(PLATFORM)/.libs/lib$(LIBNAME)3.a

all: .installed-$(PLATFORM)

$(PLATFORM): $(DEPS) | $(TARBALLS_LOCATION)/$(ARCHIVE).$(HASH_TYPE)
	rm -rf $(PLATFORM)/*; mkdir -p $(PLATFORM)
	cd $(PLATFORM); $(ARCHIVE_TOOL) $(ARCHIVE_TOOL_FLAGS) $(TARBALLS_LOCATION)/$(ARCHIVE)
	# do not build the program sqlite3
	cd $(PLATFORM); patch -p1 -i ../001-Disable-sqlite3bin.patch
# seems MAP_POPULATE is broken on aarch64
	cd $(PLATFORM); rm -rf build; mkdir -p build
ifneq ($(OS),android)
	cd $(PLATFORM); patch -p1 -i ../sqlite3.c.patch
endif
	cd $(PLATFORM); patch -p1 -i ../001-sqlite-cmake.patch
	cd $(PLATFORM)/build; $(CMAKE) -DCMAKE_BUILD_TYPE=Debug ..
#	cd $(PLATFORM); $(AUTORECONF) -vif
#	cd $(PLATFORM); $(CONFIGURE)

$(LIBDYLIB): $(PLATFORM)
#	$(MAKE) -C $(PLATFORM)
	$(MAKE) -C $(PLATFORM)/build VERBOSE=1

.installed-$(PLATFORM): $(LIBDYLIB)
#	$(MAKE) -C $(PLATFORM)/build install
	touch $@

clean:
	$(MAKE) -C $(PLATFORM)/build clean
	rm -f .installed-$(PLATFORM)

distclean::
	rm -rf $(PLATFORM) .installed-$(PLATFORM)
