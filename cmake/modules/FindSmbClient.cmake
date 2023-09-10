#.rst:
# FindSmbClient
# -------------
# Finds the SMB Client library
#
# This will define the following target:
#
#   SmbClient::SmbClient   - The SmbClient library

if(NOT TARGET SmbClient::SmbClient)
  if(WIN32 OR WINDOWS_STORE)
    set(SMBCLIENT_FOUND TRUE)
  else()
    find_package(PkgConfig)
    if(PKG_CONFIG_FOUND)
      pkg_check_modules(SMBCLIENT smbclient QUIET)
    endif()

    find_path(SMBCLIENT_INCLUDE_DIR NAMES libsmbclient.h
                                    PATHS ${SMBCLIENT_INCLUDEDIR}
                                    NO_CACHE)
    find_library(SMBCLIENT_LIBRARY NAMES smbclient
                                   PATHS ${SMBCLIENT_LIBDIR}
                                   NO_CACHE)

    include(FindPackageHandleStandardArgs)
    find_package_handle_standard_args(SmbClient
                                      REQUIRED_VARS SMBCLIENT_LIBRARY SMBCLIENT_INCLUDE_DIR
                                      VERSION_VAR SMBCLIENT_VERSION)
  endif()

  if(SMBCLIENT_FOUND)
    add_library(SmbClient::SmbClient UNKNOWN IMPORTED)
    set_target_properties(SmbClient::SmbClient PROPERTIES
                                               INTERFACE_COMPILE_DEFINITIONS HAS_FILESYSTEM_SMB=1)

    if(SMBCLIENT_LIBRARY)
      set_target_properties(SmbClient::SmbClient PROPERTIES
                                                 IMPORTED_LOCATION "${SMBCLIENT_LIBRARY}"
                                                 INTERFACE_INCLUDE_DIRECTORIES "${SMBCLIENT_INCLUDE_DIR}")
    endif()

    # if pkg-config returns link libs add to TARGET.
    if(${SMBCLIENT_LIBRARY} MATCHES ".+\.a$" AND SMBCLIENT_STATIC_LIBRARIES)
        set_target_properties(SmbClient::SmbClient PROPERTIES
                                                   INTERFACE_LINK_LIBRARIES "${SMBCLIENT_STATIC_LIBRARIES}")
    endif()

    set_property(GLOBAL APPEND PROPERTY INTERNAL_DEPS_PROP SmbClient::SmbClient)
  endif()
endif()
