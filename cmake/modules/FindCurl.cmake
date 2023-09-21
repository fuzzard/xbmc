#.rst:
# FindCurl
# --------
# Finds the Curl library
#
# This will define the following target:
#
#   Curl::Curl   - The Curl library

if(NOT TARGET Curl::Curl)
  find_package(PkgConfig)
  # Do not use pkgconfig on windows
  if(PKG_CONFIG_FOUND AND NOT WIN32)
    pkg_check_modules(PC_CURL libcurl QUIET IMPORTED_TARGET)
  endif()

  find_path(CURL_INCLUDE_DIR NAMES curl/curl.h
                             HINTS ${DEPENDS_PATH}/include ${PC_CURL_INCLUDEDIR}
                             ${${CORE_PLATFORM_LC}_SEARCH_CONFIG}
                             NO_CACHE)
  find_library(CURL_LIBRARY NAMES curl libcurl libcurl_imp
                            HINTS ${DEPENDS_PATH}/lib ${PC_CURL_LIBDIR}
                            ${${CORE_PLATFORM_LC}_SEARCH_CONFIG}
                            NO_CACHE)

  set(CURL_VERSION ${PC_CURL_VERSION})

  include(FindPackageHandleStandardArgs)
  find_package_handle_standard_args(Curl
                                    REQUIRED_VARS CURL_LIBRARY CURL_INCLUDE_DIR
                                    VERSION_VAR CURL_VERSION)

  if(CURL_FOUND)
    if(TARGET PkgConfig::PC_CURL)
      add_library(Curl::Curl ALIAS PkgConfig::PC_CURL)
    else()
      add_library(Curl::Curl UNKNOWN IMPORTED)
      set_target_properties(Curl::Curl PROPERTIES
                                       IMPORTED_LOCATION "${CURL_LIBRARY}"
                                       INTERFACE_INCLUDE_DIRECTORIES "${CURL_INCLUDE_DIR}")
    endif()

    set_property(GLOBAL APPEND PROPERTY INTERNAL_DEPS_PROP Curl::Curl)
  endif()
endif()
