#.rst:
# FindCCache
# ----------
# Finds ccache and sets it up as compiler wrapper.
# This should ideally be called before the call to project().
#
# See: https://crascit.com/2016/04/09/using-ccache-with-cmake/

find_program(CCACHE_PROGRAM ccache)

if(CCACHE_PROGRAM)
  execute_process(COMMAND "${CCACHE_PROGRAM}" --version
                  OUTPUT_VARIABLE CCACHE_VERSION
                  OUTPUT_STRIP_TRAILING_WHITESPACE)
  string(REGEX MATCH "[^\n]* version [^\n]*" CCACHE_VERSION "${CCACHE_VERSION}")
  string(REGEX REPLACE ".* version (.*)" "\\1" CCACHE_VERSION "${CCACHE_VERSION}")
endif()

include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(CCache REQUIRED_VARS CCACHE_PROGRAM
                                  VERSION_VAR CCACHE_VERSION)

if(CCACHE_FOUND)
  # Supports Unix Makefiles, Ninja and Xcode
  file(WRITE "${CMAKE_BINARY_DIR}/launch" "#!/bin/sh\nCCACHE_SLOPPINESS=\"pch_defines,time_macros\" exec ${CCACHE_PROGRAM} \"$@\"\n")
  execute_process(COMMAND chmod +x "${CMAKE_BINARY_DIR}/launch")
  set(CMAKE_CXX_COMPILER_LAUNCHER "${CMAKE_BINARY_DIR}/launch" PARENT_SCOPE)
  set(CMAKE_C_COMPILER_LAUNCHER "${CMAKE_BINARY_DIR}/launch" PARENT_SCOPE)

  file(WRITE "${CMAKE_BINARY_DIR}/launch-c" "#!/bin/sh\nCCACHE_SLOPPINESS=\"pch_defines,time_macros\" exec \"${CCACHE_PROGRAM}\" \"${CMAKE_C_COMPILER}\" \"$@\" -Xclang -fno-validate-pch\n")
  file(WRITE "${CMAKE_BINARY_DIR}/launch-cxx" "#!/bin/sh\nCCACHE_SLOPPINESS=\"pch_defines,time_macros\" exec \"${CCACHE_PROGRAM}\" \"${CMAKE_CXX_COMPILER}\" \"$@\" -Xclang -fno-validate-pch\n")
  execute_process(COMMAND chmod +x "${CMAKE_BINARY_DIR}/launch-c" "${CMAKE_BINARY_DIR}/launch-cxx")
  set(CMAKE_XCODE_ATTRIBUTE_CC "${CMAKE_BINARY_DIR}/launch-c" PARENT_SCOPE)
  set(CMAKE_XCODE_ATTRIBUTE_CXX "${CMAKE_BINARY_DIR}/launch-cxx" PARENT_SCOPE)
  set(CMAKE_XCODE_ATTRIBUTE_LD "${CMAKE_BINARY_DIR}/launch-c" PARENT_SCOPE)
  set(CMAKE_XCODE_ATTRIBUTE_LDPLUSPLUS "${CMAKE_BINARY_DIR}/launch-cxx" PARENT_SCOPE)
endif()

mark_as_advanced(CCACHE_PROGRAM)
