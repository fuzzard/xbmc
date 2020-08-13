include ../../Makefile.include
DEPS= ../../Makefile.include Makefile

VERSION.TXT := $(CMAKE_SOURCE_DIR)/version.txt
APP_NAME=$(shell awk '/APP_NAME/ {print tolower($$2)}' $(VERSION.TXT))

# lib name, version
LIBNAME=crossenv
VERSION=1.0
BASE_URL=https://github.com/benfogle/$(LIBNAME)/archive
ARCHIVE=v$(VERSION).tar.gz
TARGETENV=$(APP_NAME)targetenv

all: .installed-$(PLATFORM)

$(TARBALLS_LOCATION)/$(ARCHIVE):
	cd $(TARBALLS_LOCATION); $(RETRIEVE_TOOL) $(RETRIEVE_TOOL_FLAGS) $(BASE_URL)/$(ARCHIVE)

$(PLATFORM): $(TARBALLS_LOCATION)/$(ARCHIVE) $(DEPS)
	rm -rf $(PLATFORM)/*; mkdir -p $(PLATFORM)
	cd $(PLATFORM); $(ARCHIVE_TOOL) $(ARCHIVE_TOOL_FLAGS) $(TARBALLS_LOCATION)/$(ARCHIVE)

#				                                --sysconfigdata-file $(TARGET_PYTHON_SYSCONFIGDATA_NAME) \
#				                                --without-cross-pip \

.installed-$(PLATFORM): $(PLATFORM)
	cd $(PLATFORM); $(NATIVEPREFIX)/bin/python3 setup.py install --prefix=$(NATIVEPREFIX)
	cd $(PLATFORM); $(NATIVEPREFIX)/bin/python3 -m crossenv \
				                                --sysroot $(SDKROOT) \
				                                --clear-both \
				                                --without-cross-pip \
				                                --env CPATH:=$(PREFIX)/include \
				                                --env LIBRARY_PATH:=$(PREFIX)/lib \
				                                --env PATH:=$(PREFIX)/bin \
				                                --env CFLAGS="$(CFLAGS)" \
				                                --env CXXFLAGS="$(CXXFLAGS)" \
				                                --env LDFLAGS="$(LDFLAGS)" \
				                                --env PKG_CONFIG=${NATIVEPREFIX}/bin/pkg-config \
				                                --env PKG_CONFIG_PATH=${PREFIX}/lib/pkgconfig \
				                                --env PKG_CONFIG_LIBDIR=${PREFIX}/lib/pkgconfig \
				                                --env PKG_CONFIG_SYSROOT_DIR=${SDKROOT}} \
				                                --env PYTHONPATH=$(PYTHON_SITE_PKG) \
				                                --cc "$(CC) -arch arm64" \
				                                --cxx "$(CXX)  -arch arm64" \
				                                --ar "$(AR)" \
				                                $(PREFIX)/bin/python3 \
				                                $(NATIVEPREFIX)/bin/$(TARGETENV)
#	example execution and read from environment var
	cd $(PLATFORM); source $(NATIVEPREFIX)/bin/$(TARGETENV)/bin/cross-python -c 'import os; import struct; print(os.environ["CFLAGS"])'
#	cd $(PLATFORM); source $(NATIVEPREFIX)/bin/$(TARGETENV)/bin/build-python -c 'import os; print(os.environ["CFLAGS"])'
#	cd $(PLATFORM); source $(NATIVEPREFIX)/bin/$(TARGETENV)/bin/cross-python -c 'import sysconfig; print(sysconfig.get_config_vars())'
	touch $@

clean:
	$(MAKE) -C $(PLATFORM) clean
	rm -f .installed-$(PLATFORM)

distclean::
	rm -rf $(PLATFORM) .installed-$(PLATFORM) $(NATIVEPREFIX)/bin/$(TARGETENV)

