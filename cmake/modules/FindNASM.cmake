#.rst:
# FindNASM
# ----------
# Finds nasm executable
#
# This will define the following variables::
#
# NASM_EXECUTABLE - nasm executable
# NASM_BINDIR - directory containing executable

include(FindPackageHandleStandardArgs)

find_program(NASM_EXECUTABLE nasm)

if(NASM_EXECUTABLE)
  execute_process(COMMAND ${NASM_EXECUTABLE} -version
                  OUTPUT_VARIABLE nasm_version
                  ERROR_QUIET
                  OUTPUT_STRIP_TRAILING_WHITESPACE
                  )
  if(nasm_version MATCHES "^NASM version ([0-9\\.]*)")
    set(NASM_VERSION_STRING "${CMAKE_MATCH_1}")
  endif()
  string(REPLACE "/nasm" "" NASM_BINDIR ${NASM_EXECUTABLE})
endif()

# Provide standardized success/failure messages
find_package_handle_standard_args(NASM
                                  REQUIRED_VARS NASM_EXECUTABLE NASM_BINDIR
                                  VERSION_VAR NASM_VERSION_STRING)

mark_as_advanced(NASM_EXECUTABLE NASM_BINDIR)
