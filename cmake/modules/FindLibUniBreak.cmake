#.rst:
# FindLibUniBreak
# -------
# Finds the Libunibreak library
#
# This will define the following variables::
#
# LIBUNIBREAK_FOUND - system has Libunibreak
# LIBUNIBREAK_INCLUDE_DIRS - the Libunibreak include directory
# LIBUNIBREAK_LIBRARIES - the Libunibreak libraries
#
# and the following imported targets::
#
#   UNIBREAK::UNIBREAK   - The Libunibreak library

if(PKG_CONFIG_FOUND)
  pkg_check_modules(PC_LIBUNIBREAK libunibreak QUIET)
endif()

find_path(LIBUNIBREAK_INCLUDE_DIR NAMES linebreak.h
                                  PATHS ${PC_LIBUNIBREAK_INCLUDEDIR})
find_library(LIBUNIBREAK_LIBRARY NAMES libunibreak.a libunibreak unibreak 
                                 PATHS ${PC_LIBUNIBREAK_LIBDIR})

set(LIBUNIBREAK_VERSION ${PC_LIBUNIBREAK_VERSION})

include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(LibUniBreak
                                  REQUIRED_VARS LIBUNIBREAK_LIBRARY LIBUNIBREAK_INCLUDE_DIR
                                  VERSION_VAR LIBUNIBREAK_VERSION)

if(LIBUNIBREAK_FOUND)
  if(NOT TARGET UNIBREAK::UNIBREAK)
    add_library(UNIBREAK::UNIBREAK UNKNOWN IMPORTED)
    set_target_properties(UNIBREAK::UNIBREAK PROPERTIES
                                             IMPORTED_LOCATION "${LIBUNIBREAK_LIBRARY}"
                                             INTERFACE_LINK_LIBRARIES "${LIBUNIBREAK_LIBRARY}"
                                             INTERFACE_INCLUDE_DIRECTORIES "${LIBUNIBREAK_INCLUDE_DIRS}")

    set(LIBUNIBREAK_LIBRARIES UNIBREAK::UNIBREAK)
    set(LIBUNIBREAK_INCLUDE_DIRS UNIBREAK::UNIBREAK)
  endif()
endif()

mark_as_advanced(LIBUNIBREAK_INCLUDE_DIR LIBUNIBREAK_LIBRARY)
