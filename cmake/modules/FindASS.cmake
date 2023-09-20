#.rst:
# FindASS
# -------
# Finds the ASS library
#
# This will define the following target:
#
#   ASS::ASS   - The ASS library
#

if(NOT TARGET ASS::ASS)
  find_package(PkgConfig)
  # Do not use pkgconfig on windows
  if(PKG_CONFIG_FOUND AND NOT WIN32)
    pkg_check_modules(PC_ASS libass QUIET IMPORTED_TARGET)
  endif()

  find_path(ASS_INCLUDE_DIR NAMES ass/ass.h
                            HINTS ${DEPENDS_PATH}/include ${PC_ASS_INCLUDEDIR}
                            ${${CORE_PLATFORM_LC}_SEARCH_CONFIG}
                            NO_CACHE)
  find_library(ASS_LIBRARY NAMES ass libass
                           HINTS ${DEPENDS_PATH}/lib ${PC_ASS_LIBDIR}
                           ${${CORE_PLATFORM_LC}_SEARCH_CONFIG}
                           NO_CACHE)

  set(ASS_VERSION ${PC_ASS_VERSION})

  include(FindPackageHandleStandardArgs)
  find_package_handle_standard_args(ASS
                                    REQUIRED_VARS ASS_LIBRARY ASS_INCLUDE_DIR
                                    VERSION_VAR ASS_VERSION)

  if(ASS_FOUND)
    if(TARGET PkgConfig::PC_ASS)
      add_library(ASS::ASS ALIAS PkgConfig::PC_ASS)
    else()
      add_library(ASS::ASS UNKNOWN IMPORTED)
      set_target_properties(ASS::ASS PROPERTIES
                                     IMPORTED_LOCATION "${ASS_LIBRARY}"
                                     INTERFACE_INCLUDE_DIRECTORIES "${ASS_INCLUDE_DIR}")
    endif()
    set_property(GLOBAL APPEND PROPERTY INTERNAL_DEPS_PROP ASS::ASS)
  endif()
endif()
