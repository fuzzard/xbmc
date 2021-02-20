include ../../Makefile.include
DEPS= ../../Makefile.include Makefile

# lib name, version
LIBNAME=Cython
VERSION=0.29.21
BASE_URL=https://files.pythonhosted.org/packages/6c/9f/f501ba9d178aeb1f5bf7da1ad5619b207c90ac235d9859961c11829d0160
ARCHIVE=$(LIBNAME)-$(VERSION).tar.gz

all: .installed-$(PLATFORM)

$(TARBALLS_LOCATION)/$(ARCHIVE):
	cd $(TARBALLS_LOCATION); $(RETRIEVE_TOOL) $(RETRIEVE_TOOL_FLAGS) $(BASE_URL)/$(ARCHIVE)
	cd $(TARBALLS_LOCATION); chmod +x $(ARCHIVE)

$(PLATFORM): $(TARBALLS_LOCATION)/$(ARCHIVE) $(DEPS)
	-rm -rf $(PLATFORM)/*; mkdir -p $(PLATFORM)
	cd $(PLATFORM); $(ARCHIVE_TOOL) $(ARCHIVE_TOOL_FLAGS) $(TARBALLS_LOCATION)/$(ARCHIVE)

# manual build example
.installed-$(PLATFORM): $(PLATFORM)
	. $(NATIVEPREFIX)/bin/$(PYTHON_TARGETENV)/bin/activate \
	&& cd $(PLATFORM); build-python setup.py install --no-cython-compile \
	&& cross-expose cython
	cd $(NATIVEPREFIX)/bin/$(PYTHON_TARGETENV)/build/lib/python$(PYTHON_VERSION)/site-packages \
	&& cp -rf ./$(LIBNAME)-$(VERSION)-*.egg/* ./ && rm -rf ./$(LIBNAME)-$(VERSION-)*.egg
	touch $@

# pip example
#.installed-$(PLATFORM): $(PLATFORM)
#	. $(NATIVEPREFIX)/bin/$(PYTHON_TARGETENV)/bin/activate \
#	&& build-pip install cython \
#	&& cross-expose cython
#	touch $@

clean:
	rm -f .installed-$(PLATFORM)

distclean::
	. $(NATIVEPREFIX)/bin/$(PYTHON_TARGETENV)/bin/activate && build-pip uninstall cython -y
	rm -rf $(PLATFORM) .installed-$(PLATFORM)
