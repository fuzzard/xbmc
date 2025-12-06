#.rst:
# FindSmbClient
# -------------
# Finds the SMB Client library
#
# This following imported target will be defined::
#
#   ${APP_NAME_LC}::SmbClient   - The SmbClient library

if(NOT TARGET ${APP_NAME_LC}::${CMAKE_FIND_PACKAGE_NAME})

  if(WIN32 OR WINDOWS_STORE)
    # UWP doesnt have native smb support. It receives it from an addon.
    if(NOT CMAKE_SYSTEM_NAME STREQUAL "WindowsStore")
      add_library(${APP_NAME_LC}::${CMAKE_FIND_PACKAGE_NAME} INTERFACE IMPORTED)
      set_target_properties(${APP_NAME_LC}::${CMAKE_FIND_PACKAGE_NAME} PROPERTIES
                                                                       INTERFACE_COMPILE_DEFINITIONS HAS_FILESYSTEM_SMB)
    endif()
  else()

    find_package(PkgConfig ${SEARCH_QUIET})

    if(PKG_CONFIG_FOUND)
      pkg_check_modules(SMBCLIENT smbclient ${SEARCH_QUIET} IMPORTED_TARGET)
    endif()

    if(SMBCLIENT_FOUND)
      add_library(${APP_NAME_LC}::${CMAKE_FIND_PACKAGE_NAME} ALIAS PkgConfig::SMBCLIENT)
      set_target_properties(PkgConfig::SMBCLIENT PROPERTIES
                                                 INTERFACE_COMPILE_DEFINITIONS HAS_FILESYSTEM_SMB)
    endif()
  endif()
endif()
