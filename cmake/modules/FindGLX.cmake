#.rst:
# FindGLX
# -----
# Finds the GLX library
#
# This will define the following target:
#
#   GLX::GLX    - The GLX library

if(NOT TARGET GLX::GLX)
  find_package(PkgConfig)
  # Do not use pkgconfig on windows
  if(PKG_CONFIG_FOUND AND NOT WIN32)
    pkg_check_modules(PC_GLX glx QUIET)
  endif()

  find_path(GLX_INCLUDE_DIR NAMES GL/glx.h
                            HINTS ${PC_GLX_INCLUDEDIR}
                            NO_CACHE)
  find_library(GLX_LIBRARY NAMES GL
                           HINTS ${PC_GLX_LIBDIR}
                           NO_CACHE)

  include(FindPackageHandleStandardArgs)
  find_package_handle_standard_args(GLX
                                    REQUIRED_VARS GLX_LIBRARY GLX_INCLUDE_DIR)

  if(GLX_FOUND)
    add_library(GLX::GLX UNKNOWN IMPORTED)
    set_target_properties(GLX::GLX PROPERTIES
                                   IMPORTED_LOCATION "${GLX_LIBRARY}"
                                   INTERFACE_INCLUDE_DIRECTORIES "${GLX_INCLUDE_DIR}"
                                   INTERFACE_COMPILE_DEFINITIONS HAS_GLX=1)

    set_property(GLOBAL APPEND PROPERTY INTERNAL_DEPS_PROP GLX::GLX)
  endif()
endif()
