#.rst:
# FindGnuTLS
# -----
# Finds the GnuTLS library
#
# This will define the following target:
#
#   GnuTLS::GnuTLS - The GnuTLS library

if(NOT TARGET GnuTLS::GnuTLS)
  find_package(PkgConfig)
  # Do not use pkgconfig on windows
  if(PKG_CONFIG_FOUND AND NOT WIN32)
    pkg_check_modules(PC_GNUTLS gnutls QUIET)
  endif()

  find_path(GNUTLS_INCLUDE_DIR NAMES gnutls/gnutls.h
                               HINTS ${DEPENDS_PATH}/include ${PC_GNUTLS_INCLUDEDIR}
                               ${${CORE_PLATFORM_LC}_SEARCH_CONFIG}
                               NO_CACHE)
  find_library(GNUTLS_LIBRARY NAMES gnutls
                              HINTS ${DEPENDS_PATH}/lib ${PC_GNUTLS_LIBDIR}
                              ${${CORE_PLATFORM_LC}_SEARCH_CONFIG}
                              NO_CACHE)

  include(FindPackageHandleStandardArgs)
  find_package_handle_standard_args(GnuTLS DEFAULT_MSG GNUTLS_LIBRARY GNUTLS_INCLUDE_DIR)

  if(GNUTLS_FOUND)
    add_library(GnuTLS::GnuTLS UNKNOWN IMPORTED)
    set_target_properties(GnuTLS::GnuTLS PROPERTIES
                                         IMPORTED_LOCATION "${GNUTLS_LIBRARY}"
                                         INTERFACE_INCLUDE_DIRECTORIES "${GNUTLS_INCLUDE_DIR}"
                                         INTERFACE_COMPILE_DEFINITIONS HAVE_GNUTLS=1)
  else()
    if(GNUTLS_FIND_REQUIRED)
      message(FATAL_ERROR "GNUTLS Not Found.")
    endif()
  endif()
endif()
