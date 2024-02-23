#.rst:
# FindLzo2
# --------
# Finds the Lzo2 library
#
# This will define the following target:
#
#   lzo2::lzo2   - The Lzo2 library

if(NOT TARGET lzo2::lzo2)

  find_package(PkgConfig)
  if(PKG_CONFIG_FOUND AND NOT WIN32)
    pkg_check_modules(PC_LZO2 lzo2 QUIET)
  elseif(WIN32)
    find_package(lzo2 CONFIG QUIET REQUIRED
                             HINTS ${DEPENDS_PATH}/lib/cmake
                             ${${CORE_PLATFORM_NAME_LC}_SEARCH_CONFIG})
  endif()

  find_path(LZO2_INCLUDE_DIR NAMES lzo1x.h
                             PATH_SUFFIXES lzo
                             HINTS ${DEPENDS_PATH}/lib ${PC_LZO2_LIBDIR}
                             ${${CORE_PLATFORM_NAME_LC}_SEARCH_CONFIG}
                             NO_CACHE)

  find_library(LZO2_LIBRARY NAMES lzo2 liblzo2
                            HINTS ${DEPENDS_PATH}/lib ${PC_LZO2_INCLUDEDIR}
                            ${${CORE_PLATFORM_NAME_LC}_SEARCH_CONFIG}
                            NO_CACHE)

  include(FindPackageHandleStandardArgs)
  find_package_handle_standard_args(Lzo2
                                    REQUIRED_VARS LZO2_LIBRARY LZO2_INCLUDE_DIR)

  if(LZO2_FOUND)
    if(TARGET PkgConfig::PC_LZO2)
      add_library(lzo2::lzo2 ALIAS PkgConfig::PC_LZO2)
    elseif(TARGET lzo2::lzo2)
      # Kodi custom lzo2 target used for windows platforms. Do nothing
    else()
      add_library(lzo2::lzo2 UNKNOWN IMPORTED)
      set_target_properties(lzo2::lzo2 PROPERTIES
                                       IMPORTED_LOCATION "${LZO2_LIBRARY}"
                                       INTERFACE_INCLUDE_DIRECTORIES "${LZO2_INCLUDE_DIR}")
    endif()

    set_property(GLOBAL APPEND PROPERTY INTERNAL_DEPS_PROP lzo2::lzo2)
  else()
    if(Lzo2_FIND_REQUIRED)
      message(FATAL_ERROR "LZO2 not found.")
    endif()
  endif()
endif()
