# FindEpollShim
# -------------
# Finds the epoll-shim library
#
# This will define the following target:
#
#   EpollShim::EpollShim   - The epoll-shim library

if(NOT TARGET EpollShim::EpollShim)
  find_package(PkgConfig)
  if(PKG_CONFIG_FOUND)
    pkg_check_modules(PC_EPOLLSHIM epoll-shim QUIET)
  endif()

  find_path(EPOLLSHIM_INCLUDE_DIR NAMES sys/epoll.h
                                  HINTS ${PC_EPOLLSHIM_INCLUDE_DIRS})
  find_library(EPOLLSHIM_LIBRARY NAMES epoll-shim
                                 HINTS ${PC_EPOLLSHIM_LIBDIR})

  include(FindPackageHandleStandardArgs)
  find_package_handle_standard_args(EpollShim
                                    REQUIRED_VARS EPOLLSHIM_LIBRARY EPOLLSHIM_INCLUDE_DIR)

  if(EPOLLSHIM_FOUND)
    add_library(EpollShim::EpollShim UNKNOWN IMPORTED)
    set_target_properties(EpollShim::EpollShim PROPERTIES
                                   IMPORTED_LOCATION "${EPOLLSHIM_LIBRARY}"
                                   INTERFACE_INCLUDE_DIRECTORIES "${EPOLLSHIM_INCLUDE_DIR}")

    set_property(GLOBAL APPEND PROPERTY INTERNAL_DEPS_PROP EpollShim::EpollShim)
  endif()
endif()
