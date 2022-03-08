#.rst:
# FindMeson
# ----------
# Finds meson executable
#
# This will define the following variables::
#
# MESON_EXECUTABLE - meson executable
# MESON_BINDIR - directory containing executable

include(FindPackageHandleStandardArgs)

find_program(MESON_EXECUTABLE meson)

if(MESON_EXECUTABLE)
  execute_process(COMMAND ${MESON_EXECUTABLE} --version
                  OUTPUT_VARIABLE meson_version
                  ERROR_QUIET
                  OUTPUT_STRIP_TRAILING_WHITESPACE
                  )
  if(meson_version MATCHES "^([0-9\\.]*)")
    set(MESON_VERSION_STRING "${CMAKE_MATCH_1}")
  endif()
  string(REPLACE "/meson" "" MESON_BINDIR ${MESON_EXECUTABLE})
endif()

# Provide standardized success/failure messages
find_package_handle_standard_args(Meson
                                  REQUIRED_VARS MESON_EXECUTABLE MESON_BINDIR)
                                  VERSION_VAR MESON_VERSION_STRING)

mark_as_advanced(MESON_EXECUTABLE MESON_BINDIR)
