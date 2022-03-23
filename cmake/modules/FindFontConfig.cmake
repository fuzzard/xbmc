#.rst:
# FindFontConfig
# ------------
# Finds the FontConfig library
#
# This will define the following variables::
#
# FONTCONFIG_FOUND - system has FontConfig
# FONTCONFIG_INCLUDE_DIRS - the FontConfig include directory
# FONTCONFIG_LIBRARIES - the FontConfig libraries
#
# and the following imported targets::
#
#   FontConfig::FontConfig   - The FontConfig library

if(PKG_CONFIG_FOUND)
  pkg_check_modules(PC_FONTCONFIG fontconfig QUIET)
endif()

find_path(FONTCONFIG_INCLUDE_DIR NAMES fontconfig/fontconfig.h fontconfig.h
                               PATHS ${PC_FONTCONFIG_INCLUDEDIR}
                                     ${PC_FONTCONFIG_INCLUDE_DIRS}
                               PATH_SUFFIXES fontconfig)
find_library(FONTCONFIG_LIBRARY NAMES fontconfig
                              PATHS ${PC_FONTCONFIG_LIBDIR})

set(FONTCONFIG_VERSION ${PC_FONTCONFIG_VERSION})

include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(FontConfig
                                  REQUIRED_VARS FONTCONFIG_LIBRARY FONTCONFIG_INCLUDE_DIR
                                  VERSION_VAR FONTCONFIG_VERSION)

if(FONTCONFIG_FOUND)
  set(FONTCONFIG_LIBRARIES ${FONTCONFIG_LIBRARY})
  set(FONTCONFIG_INCLUDE_DIRS ${FONTCONFIG_INCLUDE_DIR})

  if(NOT TARGET FontConfig::FontConfig)
    add_library(FontConfig::FontConfig UNKNOWN IMPORTED)
    set_target_properties(FontConfig::FontConfig PROPERTIES
                                                 IMPORTED_LOCATION "${FONTCONFIG_LIBRARY}"
                                                 INTERFACE_INCLUDE_DIRECTORIES "${FONTCONFIG_INCLUDE_DIR}")
  endif()
endif()

mark_as_advanced(FONTCONFIG_INCLUDE_DIR FONTCONFIG_LIBRARY)
