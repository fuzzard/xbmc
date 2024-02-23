#.rst:
# FindSmbClient
# -------------
# Finds the SMB Client library
#
# This will define the following target:
#
#   SmbClient::SmbClient   - The SmbClient library

if(NOT TARGET SmbClient::SmbClient)

  find_package(PkgConfig)
  if(PKG_CONFIG_FOUND)
    pkg_check_modules(PC_SMBCLIENT smbclient QUIET)
    set(SMBCLIENT_VERSION ${PC_SMBCLIENT_VERSION})
  endif()

  find_path(SMBCLIENT_INCLUDE_DIR NAMES libsmbclient.h
                                  HINTS ${DEPENDS_PATH}/include ${PC_SMBCLIENT_INCLUDEDIR}
                                  ${${CORE_PLATFORM_LC}_SEARCH_CONFIG}
                                  NO_CACHE)
  find_library(SMBCLIENT_LIBRARY NAMES smbclient
                                 HINTS ${DEPENDS_PATH}/lib ${PC_SMBCLIENT_LIBDIR}
                                 ${${CORE_PLATFORM_LC}_SEARCH_CONFIG}
                                 NO_CACHE)

  include(FindPackageHandleStandardArgs)
  find_package_handle_standard_args(SmbClient
                                    REQUIRED_VARS SMBCLIENT_LIBRARY SMBCLIENT_INCLUDE_DIR
                                    VERSION_VAR SMBCLIENT_VERSION)

  if(SMBCLIENT_FOUND)
    add_library(SmbClient::SmbClient UNKNOWN IMPORTED)
    set_target_properties(SmbClient::SmbClient PROPERTIES
                                   IMPORTED_LOCATION "${SMBCLIENT_LIBRARY}"
                                   INTERFACE_INCLUDE_DIRECTORIES "${SMBCLIENT_INCLUDE_DIR}"
                                   INTERFACE_COMPILE_DEFINITIONS HAS_FILESYSTEM_SMB=1)

    if(${SMBCLIENT_LIBRARY} MATCHES ".+\.a$" AND PC_SMBCLIENT_STATIC_LIBRARIES)
      list(APPEND SMBCLIENT_LIBRARIES ${PC_SMBCLIENT_STATIC_LIBRARIES})
      # We dont need the explicit lib in INTERFACE_LINK_LIBRARIES
      list(REMOVE_ITEM SMBCLIENT_LIBRARIES "smbclient")
      set_target_properties(SmbClient::SmbClient PROPERTIES
                                                 INTERFACE_LINK_LIBRARIES ${SMBCLIENT_LIBRARIES})
    endif()

    set_property(GLOBAL APPEND PROPERTY INTERNAL_DEPS_PROP SmbClient::SmbClient)
  endif()
endif()
