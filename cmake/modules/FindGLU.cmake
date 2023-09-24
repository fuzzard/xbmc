#.rst:
# FindGLU
# -----
# Finds the GLU library
#
# This will define the following target:
#
#   OpenGL::GLU   - The GLU library

if(NOT TARGET OpenGL::GLU)
  find_package(PkgConfig)
  # Do not use pkgconfig on windows
  if(PKG_CONFIG_FOUND AND NOT WIN32)
    pkg_check_modules(PC_GLU glu QUIET)
  endif()

  find_path(GLU_INCLUDE_DIR NAMES GL/glu.h
                            HINTS ${PC_GLU_INCLUDEDIR}
                            NO_CACHE)
  find_library(GLU_LIBRARY NAMES GLU
                           HINTS ${PC_GLU_LIBDIR}
                           NO_CACHE)

  include(FindPackageHandleStandardArgs)
  find_package_handle_standard_args(GLU
                                    REQUIRED_VARS GLU_LIBRARY GLU_INCLUDE_DIR)

  if(GLU_FOUND)
    if(TARGET PkgConfig::PC_GLU)
      add_library(OpenGL::GLU ALIAS PkgConfig::PC_GLU)
    else()
      add_library(OpenGL::GLU UNKNOWN IMPORTED)
      set_target_properties(OpenGL::GLU PROPERTIES
                                        IMPORTED_LOCATION "${GLU_LIBRARY}"
                                        INTERFACE_INCLUDE_DIRECTORIES "${GLU_INCLUDE_DIR}"
                                        INTERFACE_COMPILE_DEFINITIONS HAS_GLU=1)
    endif()

    set_property(GLOBAL APPEND PROPERTY INTERNAL_DEPS_PROP OpenGL::GLU)
  endif()
endif()
