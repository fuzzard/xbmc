-include ../../Makefile.include
include LIBDVDCSS-VERSION
DEPS = LIBDVDCSS-VERSION Makefile ../../download-files.include \
                          01-all-libcread.patch \
                          02-darwinembed-iosbuild.patch \
                          03-win-uwp.patch

ifeq ($(CROSS_COMPILING), yes)
  DEPS += ../../Makefile.include
  PYTHON = $(NATIVEPREFIX)/bin/python3
  MESON = $(NATIVEPREFIX)/bin/meson
  NINJA = $(NATIVEPREFIX)/bin/ninja
else
  ROOT_DIR := $(shell dirname $(realpath $(lastword $(MAKEFILE_LIST))))
  PREFIX ?= $(ROOT_DIR)/libdvdcss-install
  RETRIEVE_TOOL := curl
  RETRIEVE_TOOL_FLAGS := -LsS --create-dirs --retry 10 --retry-connrefused -o
  ARCHIVE_TOOL := tar
  ARCHIVE_TOOL_FLAGS := --strip-components=1 -xf

  ifeq ($(PLATFORM),)
    PLATFORM = native
    TARBALLS_LOCATION = $(ROOT_DIR)
    HASH_TOOL = sha512sum
    HASH_TOOL_FLAGS = -c --status
    DAV1D_INSTALL_PREFIX = --prefix $(PREFIX) --libdir $(PREFIX)/lib
    MESON = meson
    NINJA = ninja
  endif
endif

# configuration settings
config = --prefix=$(PREFIX) --disable-shared --enable-static --with-pic

MESON_BUILD_TYPE=release

ifeq ($(DEBUG_BUILD), yes)
  MESON_BUILD_TYPE=debug
endif

# configuration settings
CONFIGURE = $(PYTHON) $(MESON) setup $(DAV1D_INSTALL_PREFIX) \
	--buildtype=$(MESON_BUILD_TYPE) \
	--default-library=static \
	-Denable_examples=false \
	-Denable_docs=false

ifeq ($(CROSS_COMPILING), yes)
CONFIGURE += --cross-file $(PREFIX)/share/cross-file.meson
export CC=$(CC_FOR_BUILD)
export CXX=$(CXX_FOR_BUILD)
export CFLAGS=$(CFLAGS_FOR_BUILD)
export CXXFLAGS=$(CXXFLAGS_FOR_BUILD)
else
export CC CXX CFLAGS CXXFLAGS
endif
export PKG_CONFIG_LIBDIR=$(PREFIX)/lib/pkgconfig

LIBDYLIB=$(PLATFORM)/build/src/$(BYPRODUCT)

include ../../download-files.include
all: .installed-$(PLATFORM)

$(PLATFORM): $(DEPS) | $(TARBALLS_LOCATION)/$(ARCHIVE).$(HASH_TYPE)
	rm -rf $(PLATFORM); mkdir -p $(PLATFORM)
	cd $(PLATFORM); $(ARCHIVE_TOOL) $(ARCHIVE_TOOL_FLAGS) $(TARBALLS_LOCATION)/$(ARCHIVE)
	cd $(PLATFORM); patch -p1 -i ../01-all-libcread.patch
ifeq ($(OS),darwin_embedded)
	cd $(PLATFORM); patch -p1 -i ../02-darwinembed-iosbuild.patch
endif
ifeq ($(OS),windows)
	cd $(PLATFORM); patch -p1 -i ../03-win-uwp.patch
endif
	cd $(PLATFORM); $(CONFIGURE) . build

$(LIBDYLIB): $(PLATFORM)
	cd $(PLATFORM)/build; $(NINJA) -v

.installed-$(PLATFORM): $(LIBDYLIB)
	cd $(PLATFORM)/build; $(NINJA) -v install
	touch $@

clean:
	$(MAKE) -C $(PLATFORM) clean
	rm -f .installed-$(PLATFORM)

distclean::
	rm -rf $(PLATFORM) .installed-$(PLATFORM)

