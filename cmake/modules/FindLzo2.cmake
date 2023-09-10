#.rst:
# FindLzo2
# --------
# Finds the Lzo2 library
#
# This will define the following target:
#
#   Lzo2::Lzo2 - The Lzo2 library

if(NOT TARGET Lzo2::Lzo2)
  find_path(LZO2_INCLUDE_DIR NAMES lzo1x.h
                             PATH_SUFFIXES lzo
                             NO_CACHE)

  find_library(LZO2_LIBRARY_RELEASE NAMES lzo2 liblzo2
                                    NO_CACHE)
  find_library(LZO2_LIBRARY_DEBUG NAMES lzo2d liblzo2d
                                  NO_CACHE)

  include(SelectLibraryConfigurations)
  select_library_configurations(LZO2)

  include(FindPackageHandleStandardArgs)
  find_package_handle_standard_args(Lzo2
                                    REQUIRED_VARS LZO2_LIBRARY LZO2_INCLUDE_DIR)

  if(LZO2_FOUND)
    add_library(Lzo2::Lzo2 UNKNOWN IMPORTED)
    set_target_properties(Lzo2::Lzo2 PROPERTIES
                                     INTERFACE_INCLUDE_DIRECTORIES "${LZO2_INCLUDE_DIR}")
    if(LZO2_LIBRARY_RELEASE)
      set_target_properties(Lzo2::Lzo2 PROPERTIES
                                       IMPORTED_LOCATION_RELEASE "${LZO2_LIBRARY_RELEASE}")
    if(LZO2_LIBRARY_DEBUG)
      set_target_properties(Lzo2::Lzo2 PROPERTIES
                                       IMPORTED_LOCATION_DEBUG "${LZO2_LIBRARY_DEBUG}")
    endif()
    set_property(GLOBAL APPEND PROPERTY INTERNAL_DEPS_PROP Lzo2::Lzo2)
  endif()
endif()
