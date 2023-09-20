#.rst:
# FindAtomic
# -----
# Finds the ATOMIC library
#
# This will define the following target:
#
#   ATOMIC::ATOMIC    - The ATOMIC library

if(NOT TARGET ATOMIC::ATOMIC)
  include(CheckCXXSourceCompiles)

  set(atomic_code
      "
       #include <atomic>
       #include <cstdint>
       std::atomic<uint8_t> n8 (0); // riscv64
       std::atomic<uint64_t> n64 (0); // armel, mipsel, powerpc
       int main() {
         ++n8;
         ++n64;
         return 0;
       }")

  check_cxx_source_compiles("${atomic_code}" ATOMIC_LOCK_FREE_INSTRUCTIONS)

  if(NOT ATOMIC_LOCK_FREE_INSTRUCTIONS)
    set(CMAKE_REQUIRED_LIBRARIES "-latomic")
    check_cxx_source_compiles("${atomic_code}" ATOMIC_IN_LIBRARY)
    set(CMAKE_REQUIRED_LIBRARIES)
    if(ATOMIC_IN_LIBRARY)
      set(ATOMIC_LIBRARY atomic)
      include(FindPackageHandleStandardArgs)
      find_package_handle_standard_args(Atomic DEFAULT_MSG ATOMIC_LIBRARY)

      add_library(ATOMIC::ATOMIC UNKNOWN IMPORTED)
      set_target_properties(ATOMIC::ATOMIC PROPERTIES
                                           IMPORTED_LOCATION "${ATOMIC_LIBRARY}")
      set_property(GLOBAL APPEND PROPERTY INTERNAL_DEPS_PROP ATOMIC::ATOMIC)
    else()
      if(Atomic_FIND_REQUIRED)
        message(FATAL_ERROR "Neither lock free instructions nor -latomic found.")
      endif()
    endif()
  endif()
  unset(atomic_code)
endif()
