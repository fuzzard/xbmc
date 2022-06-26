#.rst:
# FindSmbClient
# -------------
# Finds the SMB Client library
#
# This will define the following variables::
#
# SMBCLIENT_FOUND - system has SmbClient
# SMBCLIENT_INCLUDE_DIRS - the SmbClient include directory
# SMBCLIENT_LIBRARIES - the SmbClient libraries
# SMBCLIENT_DEFINITIONS - the SmbClient definitions
#
# and the following imported targets::
#
#   SmbClient::SmbClient   - The SmbClient library

if(ENABLE_INTERNAL_SMBCLIENT)
  include(cmake/scripts/common/ModuleHelpers.cmake)

  # Deps
  # gnutls
  # ZLIB

  if(ENABLE_GPLV3)
    set(MODULE_LC samba-gplv3)
  else()
    set(MODULE_LC samba)
  endif()

  SETUP_BUILD_VARS()

  find_program(PKGCONFIG pkg-config REQUIRED
                                    HINTS ${NATIVE_PREFIX}/bin)

  find_package(PerlLibs REQUIRED)

  if(PKGCONFIG_FOUND)
    pkg_check_modules(PC_GNUTLS gnutls QUIET REQUIRED)
    if(NOT APPLE)
      pkg_check_modules(PC_ZLIB gnutls QUIET REQUIRED)
    endif()
  endif()

  if(ENABLE_GPLV3)

    set(patches "${CMAKE_SOURCE_DIR}/tools/depends/target/${MODULE_LC}/01-fix-dependencies.patch"
                "${CMAKE_SOURCE_DIR}/tools/depends/target/${MODULE_LC}/02-cross_compile.patch"
                "${CMAKE_SOURCE_DIR}/tools/depends/target/${MODULE_LC}/03-builtin-heimdal.patch"
                "${CMAKE_SOURCE_DIR}/tools/depends/target/${MODULE_LC}/04-built-static.patch")

    if(APPLE)
      if(CORE_SYSTEM_NAME STREQUAL "darwin_embedded")
        list(APPEND patches "${CMAKE_SOURCE_DIR}/tools/depends/target/${MODULE_LC}/no_fork_and_exec.patch"
                            "${CMAKE_SOURCE_DIR}/tools/depends/target/${MODULE_LC}/crt_extensions.patch")


        # build errors with _yp_get_default_domain NIS failure
        set(SAMBA_CFLAGS -Wno-error=implicit-function-declaration)
      endif()
      list(APPEND patches "${CMAKE_SOURCE_DIR}/tools/depends/target/${MODULE_LC}/05-apple-disable-zlib-pkgconfig.patch"
                          "${CMAKE_SOURCE_DIR}/tools/depends/target/${MODULE_LC}/06-apple-fix-st_atim.patch")
    endif()

    if(CORE_SYSTEM_NAME STREQUAL android)
      list(APPEND patches "${CMAKE_SOURCE_DIR}/tools/depends/target/${MODULE_LC}/samba_android.patch")
    endif

    generate_patchcommand("${patches}")

    set(CONFIGURE_COMMAND ./configure --prefix=$(PREFIX)
                                      --builtin-libraries=!smbclient,!smbd_base,!smbstatus,ALL
                                      --cross-compile
                                      --cross-answers=cross-answers.txt
                                      --disable-avahi
                                      --disable-cups
                                      --disable-iprint
                                      --disable-python
                                      --disable-symbol-versions
                                      --enable-fhs
                                      --nopyc
                                      --nopyo
                                      --with-shared-modules=!vfs_snapper
                                      --without-acl-support
                                      --without-ad-dc
                                      --without-ads
                                      --without-cluster-support
                                      --without-dnsupdate
                                      --without-gettext
                                      --without-json
                                      --without-ldap
                                      --without-libarchive
                                      --without-pam
                                      --without-regedit
                                      --without-utmp
                                      --without-winbind
                                      "CC=${CMAKE_C_COMPILER}"
                                      "CFLAGS=${CMAKE_C_FLAGS} ${SAMBA_CFLAGS}"
                                      "LDFLAGS=${CMAKE_EXE_LINKER_FLAGS}"
                                      "PERL5LIB=$ENV{PERL5LIB}")

    set(BUILD_COMMAND WAF_MAKE=1 ./buildtools/bin/waf --targets=smbclient)
    set(INSTALL_COMMAND WAF_MAKE=1 ./buildtools/bin/waf install --targets=smbclient)
    set(BUILD_IN_SOURCE 1)

    find_program(INSTALL_EXECUTABLE NAMES install)
    add_custom_command(TARGET ${MODULE_LC} POST_BUILD
                                           COMMAND ${INSTALL_EXECUTABLE} ${${MODULE}_BYPRODUCT} ${DEPENDS_PATH}/lib)

  else()

  endif()

  set(SMBCLIENT_LIBRARY ${${MODULE}_LIBRARY})
  set(SMBCLIENT_INCLUDE_DIR ${${MODULE}_INCLUDE_DIR})
  set(SMBCLIENT_VERSION ${${MODULE}_VER})
  set(SMBCLIENT_FOUND 1)

  BUILD_DEP_TARGET()
else()

  if(PKGCONFIG_FOUND)
    pkg_check_modules(PC_SMBCLIENT smbclient QUIET)
  endif()

  find_path(SMBCLIENT_INCLUDE_DIR NAMES libsmbclient.h
                                  PATHS ${PC_SMBCLIENT_INCLUDEDIR})
  find_library(SMBCLIENT_LIBRARY NAMES smbclient
                                 PATHS ${PC_SMBCLIENT_LIBDIR})

  set(SMBCLIENT_VERSION ${PC_SMBCLIENT_VERSION})
endif()

include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(SmbClient
                                  REQUIRED_VARS SMBCLIENT_LIBRARY SMBCLIENT_INCLUDE_DIR
                                  VERSION_VAR SMBCLIENT_VERSION)

if(SMBCLIENT_FOUND)
  set(SMBCLIENT_LIBRARIES ${SMBCLIENT_LIBRARY})
  if(${SMBCLIENT_LIBRARY} MATCHES ".+\.a$" AND PC_SMBCLIENT_STATIC_LIBRARIES)
    list(APPEND SMBCLIENT_LIBRARIES ${PC_SMBCLIENT_STATIC_LIBRARIES})
  endif()
  set(SMBCLIENT_INCLUDE_DIRS ${SMBCLIENT_INCLUDE_DIR})
  set(SMBCLIENT_DEFINITIONS -DHAS_FILESYSTEM_SMB=1)

  if(NOT TARGET SmbClient::SmbClient)
    add_library(SmbClient::SmbClient UNKNOWN IMPORTED)
    set_target_properties(SmbClient::SmbClient PROPERTIES
                                   IMPORTED_LOCATION "${SMBCLIENT_LIBRARY}"
                                   INTERFACE_INCLUDE_DIRECTORIES "${SMBCLIENT_INCLUDE_DIR}"
                                   INTERFACE_COMPILE_DEFINITIONS "${SMBCLIENT_DEFINITIONS}")
  endif()
endif()

mark_as_advanced(LIBSMBCLIENT_INCLUDE_DIR LIBSMBCLIENT_LIBRARY)
