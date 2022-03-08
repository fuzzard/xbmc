#.rst:
# FindNinja
# ----------
# Finds ninja executable
#
# This will define the following variables::
#
# NINJA_EXECUTABLE - ninja executable
# NINJA_BINDIR - directory containing executable

include(FindPackageHandleStandardArgs)

find_program(NINJA_EXECUTABLE ninja)

if(NINJA_EXECUTABLE)
  execute_process(COMMAND ${NINJA_EXECUTABLE} --version
                  OUTPUT_VARIABLE ninja_version
                  ERROR_QUIET
                  OUTPUT_STRIP_TRAILING_WHITESPACE
                  )
  if(ninja_version MATCHES "^([0-9\\.]*)")
    set(NINJA_VERSION_STRING "${CMAKE_MATCH_1}")
  endif()
  string(REPLACE "/ninja" "" NINJA_BINDIR ${NINJA_EXECUTABLE})
endif()

# Provide standardized success/failure messages
find_package_handle_standard_args(Ninja
                                  REQUIRED_VARS NINJA_EXECUTABLE NINJA_BINDIR
                                  VERSION_VAR NINJA_VERSION_STRING)

mark_as_advanced(NINJA_EXECUTABLE NINJA_BINDIR)
