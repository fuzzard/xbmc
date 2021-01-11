include ../../Makefile.include
DEPS= ../../Makefile.include Makefile modules.setup \
    disable_tests.patch android.patch \
    darwinembed_posixmodule.patch \
    darwinembed_config_sub.patch \
    darwinembed_configure_ac.patch \
    darwinembed_apple.patch \
    darwinembed_subprocess.patch

# lib name, version
LIBNAME=Python
VERSION=3.8.5
SOURCE=$(LIBNAME)-$(VERSION)
ARCHIVE=$(SOURCE).tar.xz
BASE_URL=https://www.python.org/ftp/python/$(VERSION)

ifeq ($(findstring apple-darwin, $(HOST)), apple-darwin)
  pyplatform=darwin
  LINK_ICONV=-framework CoreFoundation -liconv
  LDFLAGS+= -framework Foundation
endif

LDFLAGS+= -lintl -liconv -lssl -lcrypto -lz -lbz2 -lsqlite3 -lffi
LD=
export LDFLAGS LD
export LDSHARED=$(CC)

ifeq ($(OS), darwin_embedded)
  machdep=MACHDEP=arm64-apple-ios
  pyplatform=ios-aarch64
  EXTRA_CONFIGURE=ac_cv_func_wait3=no ac_cv_func_wait4=no ac_cv_func_waitpid=no \
                  ac_cv_func_execv=no ac_cv_func_fexecv=no ac_cv_func_getentropy=no \
                  ac_cv_func_setpriority=no ac_cv_func_sendfile=no ac_cv_header_sched_h=no \
                  ac_cv_func_posix_spawn=no ac_cv_func_posix_spawnp=no \
                  ac_cv_func_forkpty=no ac_cv_lib_util_forkpty=no \
                  ac_cv_func_getgroups=no
endif

CONFIG_OPT=--host="$(HOST)" \
           --build="$(BUILD)" \
           PYTHON_FOR_BUILD='_PYTHON_PROJECT_BASE=$(CURDIR)/$(PLATFORM) _PYTHON_HOST_PLATFORM=$(pyplatform) PYTHONPATH=$(CURDIR)/$(PLATFORM)/build/lib.$(pyplatform)-$(PYTHON_VERSION):$(CURDIR)/$(PLATFORM)/Lib _PYTHON_SYSCONFIGDATA_NAME=$(TARGET_PYTHON_SYSCONFIGDATA_NAME) '$(NATIVEPREFIX)/bin/python3 \
           $(machdep)

# configuration settings
CONFIGURE=./configure $(CONFIG_OPT) --prefix=$(PREFIX) \
           --disable-shared \
           --enable-static \
           --without-ensurepip \
           --disable-framework \
           --with-system-expat \
           --with-system-ffi \
           --without-pymalloc \
           --enable-ipv6 \
           $(EXTRA_CONFIGURE)

all: .installed-$(PLATFORM)

$(TARBALLS_LOCATION)/$(ARCHIVE):
	cd $(TARBALLS_LOCATION); $(RETRIEVE_TOOL) $(RETRIEVE_TOOL_FLAGS) $(BASE_URL)/$(ARCHIVE)

$(PLATFORM): $(TARBALLS_LOCATION)/$(ARCHIVE) $(DEPS)
	rm -rf $(PLATFORM)/*; mkdir -p $(PLATFORM)
	cd $(PLATFORM); $(ARCHIVE_TOOL) $(ARCHIVE_TOOL_FLAGS) $(TARBALLS_LOCATION)/$(ARCHIVE)
	cp modules.setup $(PLATFORM)/Modules/Setup.local
	cd $(PLATFORM); patch -p1 -i ../disable_tests.patch
	cd $(PLATFORM); patch -p1 -i ../android.patch
ifeq ($(OS), darwin_embedded)
	cd $(PLATFORM); patch -p1 -i ../darwinembed_posixmodule.patch
	cd $(PLATFORM); patch -p1 -i ../darwinembed_config_sub.patch
	cd $(PLATFORM); patch -p1 -i ../darwinembed_configure_ac.patch
	cd $(PLATFORM); patch -p1 -i ../darwinembed_subprocess.patch
	cd $(PLATFORM); patch -p1 -i ../darwinembed_apple.patch
endif
# disable locale altogether for Android
ifeq ($(OS),android)
	cd $(PLATFORM); sed -ie 's|_locale -DPy_BUILD_CORE_BUILTIN _localemodule.c   -lintl $(LINK_ICONV)|#_locale -DPy_BUILD_CORE_BUILTIN _localemodule.c  # -lintl|' Modules/Setup
endif
# Add the _scproxy module for darwin
ifeq ($(OS),osx)
	echo "_scproxy \$$(srcdir)/Modules/_scproxy.c -framework SystemConfiguration -framework CoreFoundation" >> $(PLATFORM)/Modules/Setup
endif
	cd $(PLATFORM); $(AUTORECONF)
	cd $(PLATFORM); $(CONFIGURE)

.installed-$(PLATFORM): $(PLATFORM)
	$(MAKE) -C $(PLATFORM) install prefix=$(PREFIX)
	cd $(PLATFORM); cp ./build/lib.$(pyplatform)-$(PYTHON_VERSION)/$(TARGET_PYTHON_SYSCONFIGDATA_NAME).py $(NATIVEPREFIX)/lib/python$(PYTHON_VERSION)/
	touch $@

clean:
	rm -rf $(PLATFORM) .installed-$(PLATFORM)

distclean::
	rm -rf $(PLATFORM) .installed-$(PLATFORM) $(NATIVEPREFIX)/lib/python$(PYTHON_VERSION)/$(TARGET_PYTHON_SYSCONFIGDATA_NAME).py
