#.rst:
# FindLzo2
# --------
# Finds the Lzo2 library
#
# This will define the following target:
#
#   Lzo2::Lzo2   - The Lzo2 library

if(NOT TARGET Lzo2::Lzo2)
  find_path(LZO2_INCLUDE_DIR NAMES lzo1x.h
                             PATH_SUFFIXES lzo
                             HINTS ${DEPENDS_PATH}/lib
                             ${${CORE_PLATFORM_NAME_LC}_SEARCH_CONFIG})

  find_library(LZO2_LIBRARY NAMES lzo2 liblzo2
                            HINTS ${DEPENDS_PATH}/lib
                            ${${CORE_PLATFORM_NAME_LC}_SEARCH_CONFIG})

  include(FindPackageHandleStandardArgs)
  find_package_handle_standard_args(Lzo2
                                    REQUIRED_VARS LZO2_LIBRARY LZO2_INCLUDE_DIR)

  if(LZO2_FOUND)
    add_library(Lzo2::Lzo2 UNKNOWN IMPORTED)
    set_target_properties(Lzo2::Lzo2 PROPERTIES
                                     IMPORTED_LOCATION "${LZO2_LIBRARY}"
                                     INTERFACE_INCLUDE_DIRECTORIES "${LZO2_INCLUDE_DIR}")

    set_property(GLOBAL APPEND PROPERTY INTERNAL_DEPS_PROP Lzo2::Lzo2)
  else()
    if(Lzo2_FIND_REQUIRED)
      message(FATAL_ERROR "LZO2 not found.")
    endif()
  endif()
endif()
