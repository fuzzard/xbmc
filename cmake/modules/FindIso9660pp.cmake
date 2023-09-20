#.rst:
# FindIso9660pp
# --------
# Finds the iso9660++ library
#
# This will define the following target:
#
# ISO9660::ISO9660 - the iso9660 libraries
# ISO9660::ISO9660PP - the iso9660++ library

if(NOT TARGET ISO9660::ISO9660PP)
  if(Iso9660pp_FIND_VERSION)
    if(Iso9660pp_FIND_VERSION_EXACT)
      set(Iso9660pp_FIND_SPEC "=${Iso9660pp_FIND_VERSION_COMPLETE}")
    else()
      set(Iso9660pp_FIND_SPEC ">=${Iso9660pp_FIND_VERSION_COMPLETE}")
    endif()
  endif()
  find_package(PkgConfig)
  if(PKG_CONFIG_FOUND)
    pkg_check_modules(PC_ISO9660PP libiso9660++${Iso9660pp_FIND_SPEC} QUIET)
    pkg_check_modules(PC_ISO9660 libiso9660${Iso9660pp_FIND_SPEC} QUIET)
  endif()

  find_package(Cdio REQUIRED)

  find_path(ISO9660_INCLUDE_DIR NAMES iso9660.h
                                PATH_SUFFIXES cdio
                                HINTS ${DEPENDS_PATH}/include ${PC_ISO9660_INCLUDEDIR}
                                NO_CACHE)

  find_library(ISO9660_LIBRARY NAMES libiso9660 iso9660
                               HINTS ${DEPENDS_PATH}/lib ${PC_ISO9660_LIBDIR}
                               NO_CACHE)

  find_path(ISO9660PP_INCLUDE_DIR NAMES iso9660.hpp
                                  PATH_SUFFIXES cdio++
                                  HINTS ${DEPENDS_PATH}/include ${PC_ISO9660PP_INCLUDEDIR}
                                  NO_CACHE)

  find_library(ISO9660PP_LIBRARY NAMES libiso9660++ iso9660++
                                 HINTS ${DEPENDS_PATH}/lib ${PC_ISO9660PP_LIBDIR}
                                 NO_CACHE)

  set(ISO9660PP_VERSION ${PC_ISO9660PP_VERSION})

  include(FindPackageHandleStandardArgs)
  find_package_handle_standard_args(Iso9660pp
                                    REQUIRED_VARS ISO9660PP_LIBRARY ISO9660PP_INCLUDE_DIR ISO9660_LIBRARY ISO9660_INCLUDE_DIR
                                    VERSION_VAR ISO9660PP_VERSION)

  if(ISO9660PP_FOUND)
    add_library(ISO9660::ISO9660 UNKNOWN IMPORTED)
    set_target_properties(ISO9660::ISO9660 PROPERTIES
                                           IMPORTED_LOCATION "${ISO9660_LIBRARY}"
                                           INTERFACE_INCLUDE_DIRECTORIES "${ISO9660_INCLUDE_DIR}")

    add_library(ISO9660::ISO9660PP UNKNOWN IMPORTED)
    set_target_properties(ISO9660::ISO9660PP PROPERTIES
                                             IMPORTED_LOCATION "${ISO9660PP_LIBRARY}"
                                             INTERFACE_INCLUDE_DIRECTORIES "${ISO9660PP_INCLUDE_DIR}"
                                             INTERFACE_COMPILE_DEFINITIONS HAS_ISO9660PP=1
                                             INTERFACE_LINK_LIBRARIES "ISO9660::ISO9660;CDIO::CDIO")

    set_property(GLOBAL APPEND PROPERTY INTERNAL_DEPS_PROP ISO9660::ISO9660PP)
  endif()
endif()
