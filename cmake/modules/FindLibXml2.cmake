#.rst:
# FindLibXml2
# --------
# Finds the libxml2 library
#
# This will define the following target:
#
#   LibXml2::LibXml2 - The LibXml2 Library
#   LIBRARY::LibXml2 - An ALIAS TARGET for the LibXml2 library

if(NOT TARGET LIBRARY::${CMAKE_FIND_PACKAGE_NAME})
  include(cmake/scripts/common/ModuleHelpers.cmake)

  set(${CMAKE_FIND_PACKAGE_NAME}_MODULE_LC libxml2)

  SETUP_FIND_SPECS()

  # Check for existing libxml2. If version >= LIBXML2-VERSION file version, dont build
  find_package(libxml2 ${CONFIG_${CMAKE_FIND_PACKAGE_NAME}_FIND_SPEC} CONFIG ${SEARCH_QUIET}
                       HINTS ${DEPENDS_PATH}/lib/cmake
                       ${${CORE_PLATFORM_NAME_LC}_SEARCH_CONFIG})

  # cmake config may not be available (eg Debian libxml2-dev package)
  # fallback to pkgconfig for non windows platforms
  if(NOT libxml2_FOUND)
    find_package(PkgConfig ${SEARCH_QUIET})
    if(PKG_CONFIG_FOUND AND NOT (WIN32 OR WINDOWS_STORE))
      pkg_check_modules(libxml2 libxml2${PC_${CMAKE_FIND_PACKAGE_NAME}_FIND_SPEC} ${SEARCH_QUIET} IMPORTED_TARGET)
    endif()
  endif()

  if(TARGET LibXml2::LibXml2 OR TARGET libxml2::libxml2)

    # Legacy target for our windows config
    if(TARGET libxml2::libxml2)
      set(_target libxml2::libxml2)
    else()
      set(_target LibXml2::LibXml2)
    endif()

    get_target_property(_LIBXML2_CONFIGURATIONS ${_target} IMPORTED_CONFIGURATIONS)
    foreach(_libxml2_config IN LISTS _LIBXML2_CONFIGURATIONS)
      # Just set to RELEASE var so select_library_configurations can continue to work its magic
      string(TOUPPER ${_libxml2_config} _libxml2_config_UPPER)
      if((NOT ${_libxml2_config_UPPER} STREQUAL "RELEASE") AND
         (NOT ${_libxml2_config_UPPER} STREQUAL "DEBUG"))
        get_target_property(LIBXML2_LIBRARY_RELEASE ${_target} IMPORTED_LOCATION_${_libxml2_config_UPPER})
      else()
        get_target_property(LIBXML2_LIBRARY_${_xslt_config_UPPER} ${_target} IMPORTED_LOCATION_${_libxml2_config_UPPER})
      endif()
    endforeach()

    get_target_property(LIBXML2_INCLUDE_DIR ${_target} INTERFACE_INCLUDE_DIRECTORIES)
    set(LIBXML2_VERSION ${LIBXML2_VERSION_STRING})
  elseif(TARGET PkgConfig::libxml2)
    # First item is the full path of the library file found
    # pkg_check_modules does not populate a variable of the found library explicitly
    list(GET libxml2_LINK_LIBRARIES 0 LIBXML2_LIBRARY_RELEASE)

    get_target_property(LIBXML2_INCLUDE_DIR PkgConfig::libxml2 INTERFACE_INCLUDE_DIRECTORIES)
    set(LIBXML2_VERSION ${libxml2_VERSION})
  endif()

  include(SelectLibraryConfigurations)
  select_library_configurations(LIBXML2)
  unset(LIBXML2_LIBRARIES)

  include(FindPackageHandleStandardArgs)
  find_package_handle_standard_args(LIBXML2
                                    REQUIRED_VARS LIBXML2_LIBRARY LIBXML2_INCLUDE_DIR
                                    VERSION_VAR LIBXML2_VERSION)

  if(LIBXML2_FOUND)
    if(TARGET PkgConfig::libxml2)
      add_library(LIBRARY::${CMAKE_FIND_PACKAGE_NAME} ALIAS PkgConfig::libxml2)
      add_library(LibXml2::LibXml2 ALIAS PkgConfig::libxml2)
    elseif(TARGET libxml2::libxml2)
      add_library(LIBRARY::${CMAKE_FIND_PACKAGE_NAME} ALIAS libxml2::libxml2)
      add_library(LibXml2::LibXml2 ALIAS libxml2::libxml2)
    else()
      add_library(LIBRARY::${CMAKE_FIND_PACKAGE_NAME} ALIAS LibXml2::LibXml2)
    endif()
  else()
    if(LibXml2_FIND_REQUIRED)
      message(FATAL_ERROR "LibXML2 library was not found.")
    endif()
  endif()
endif()
