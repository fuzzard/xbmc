#.rst:
# FindOpenGl
# ----------
# Finds the FindOpenGl library
#
# This will define the following target:
#
#   OpenGL::GL - The OpenGL library

if(NOT TARGET OpenGL::GL)
  find_package(PkgConfig)
  if(PKG_CONFIG_FOUND)
    pkg_check_modules(PC_OPENGL gl QUIET)
  endif()

  if(CORE_SYSTEM_NAME STREQUAL osx)
    set(SEARCH_CONDITIONS NO_DEFAULT_PATH)
  endif()

  find_library(OPENGL_gl_LIBRARY NAMES GL OpenGL
                                 HINTS ${PC_OPENGL_gl_LIBDIR} ${CMAKE_OSX_SYSROOT}/System/Library
                                 PATH_SUFFIXES Frameworks
                                 ${SEARCH_CONDITIONS}
                                 NO_CACHE)
  find_path(OPENGL_INCLUDE_DIR NAMES GL/gl.h gl.h
                               HINTS ${PC_OPENGL_gl_INCLUDEDIR} ${CMAKE_OSX_SYSROOT}/System/Library/Headers
                               ${SEARCH_CONDITIONS}
                               NO_CACHE)

  include(FindPackageHandleStandardArgs)
  find_package_handle_standard_args(OpenGl
                                    REQUIRED_VARS OPENGL_gl_LIBRARY OPENGL_INCLUDE_DIR)

  if(OPENGL_FOUND)
    add_library(OpenGL::GL UNKNOWN IMPORTED)
    set_target_properties(OpenGL::GL PROPERTIES
                                     IMPORTED_LOCATION "${OPENGL_gl_LIBRARY}"
                                     INTERFACE_INCLUDE_DIRECTORIES "${OPENGL_INCLUDE_DIR}"
                                     INTERFACE_COMPILE_DEFINITIONS HAS_GL=1)
    set_property(GLOBAL APPEND PROPERTY INTERNAL_DEPS_PROP OpenGL::GL)
  endif()
endif()
