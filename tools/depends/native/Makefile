include ../Makefile.include

ifneq ($(shell test -f $(NATIVEPREFIX)/share/config.site && echo 1),1)
  $(error Error: $(NATIVEPREFIX)/share/config.site  is missing. Please reconfigure depends to generate it)
endif

# Keep in alphabetical order
NATIVE= \
  autoconf \
  autoconf-archive \
  automake \
  cmake \
  bison \
  gas-preprocessor \
  gettext \
  giflib \
  heimdal \
  libiconv \
  libjpeg-turbo \
  liblzo2 \
  libpng \
  libtool \
  m4 \
  meson \
  nasm \
  ninja \
  openssl \
  pcre2 \
  perlmodule-parseyapp \
  pkgconf \
  pythonmodule-setuptools \
  python3 \
  swig \
  TexturePacker \
  zlib

LIBICONV = libiconv

ifneq ($(NATIVE_OS),osx)
  NATIVE += libffi
  LIBFFI = libffi
endif

ifeq ($(OS),darwin_embedded)
  NATIVE += dpkg xz tar ldid
endif

ifeq ($(OS),linux)
  NATIVE += expat wayland-scanner pugixml waylandpp-scanner
  EXPAT = expat

  ifeq ($(RENDER_SYSTEM),gles)
    NATIVE += MarkupSafe Mako
  endif

  ifeq ($(TARGET_PLATFORM),webos)
    NATIVE += rustup cargo-c

    # glibc in toolchain provides iconv
    EXCLUDED_NATIVE += libiconv
    LIBICONV=
  endif
endif

ifeq ($(OS),android)
  NATIVE += rustup cargo-c
endif

NATIVE := $(filter-out $(EXCLUDED_NATIVE),$(NATIVE))

.PHONY: $(NATIVE) native download $(DOWNLOAD_TARGETS)

all: native
	@echo "Dependencies built successfully."

DOWNLOAD_TARGETS := $(addprefix download/, $(NATIVE))

$(DOWNLOAD_TARGETS):
	$(MAKE) -C $(notdir $@) download

download: $(DOWNLOAD_TARGETS)

# Dependency layout for parallel builds
autoconf-archive: autoconf
autoconf: m4
automake: autoconf
bison: gettext
cargo-c: pkgconf openssl rustup
dpkg: automake gettext libtool pkgconf tar
gettext: $(LIBICONV)
heimdal: libtool
JsonSchemaBuilder: cmake
libjpeg-turbo: cmake nasm
libpng: zlib automake
libtool: automake
Mako: MarkupSafe
meson: python3 pythonmodule-setuptools
ninja: meson
openssl: zlib
pcre2: cmake
pkgconf: meson ninja
pugixml: cmake
python3: $(EXPAT) $(LIBFFI) zlib openssl
pythonmodule-setuptools: python3
swig: bison cmake pcre2
tar: xz automake
TexturePacker: cmake libpng liblzo2 giflib libjpeg-turbo
wayland-scanner: expat ninja pkgconf
waylandpp-scanner: cmake pugixml

# python installs are not thread safe when using easy_install method.
# MarkupSafe doesn't really depend on ninja but we need to make the
# build sequential
MarkupSafe: ninja

#liblzo2 has stale packaged automake files that cause borked host/build detection
liblzo2: automake

native: $(NATIVE)
$(NATIVE):
	$(MAKE) -C $@
clean:
	for d in $(NATIVE); do $(MAKE) -C $$d clean; done

# Debug target, this will DELETE all data in staging!
test-dependencies:
	( for d in $(NATIVE); do \
	rm -rf $(NATIVEPREFIX); \
        mkdir -p $(NATIVEPREFIX)/include $(NATIVEPREFIX)/share $(NATIVEPREFIX)/bin; \
	cp -f config.site $(NATIVEPREFIX)/share/; \
	$(MAKE) distclean; \
	$(MAKE) $$d; done ) && echo "$@ built successfully"

distclean::
	for d in $(NATIVE); do $(MAKE) -C $$d distclean; done

