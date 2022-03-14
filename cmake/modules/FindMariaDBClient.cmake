#.rst:
# FindMariaDBClient
# ---------------
# Finds the MariaDBClient library
#
# This will define the following variables::
#
# MARIADBCLIENT_FOUND - system has MariaDBClient
# MARIADBCLIENT_INCLUDE_DIRS - the MariaDBClient include directory
# MARIADBCLIENT_LIBRARIES - the MariaDBClient libraries
# MARIADBCLIENT_DEFINITIONS - the MariaDBClient compile definitions
#
# and the following imported targets::
#
#   MariaDBClient::MariaDBClient   - The MariaDBClient library

if(ENABLE_INTERNAL_MARIADBCLIENT)
  include(cmake/scripts/common/ModuleHelpers.cmake)

  set(MODULE_LC mariadb)

  SETUP_BUILD_VARS()

  if(APPLE)
    set(EXTRA_ARGS "-DCMAKE_OSX_ARCHITECTURES=${CMAKE_OSX_ARCHITECTURES}")
  endif()

  # Suppress mismatch warning, see https://cmake.org/cmake/help/latest/module/FindPackageHandleStandardArgs.html
  set(FPHSA_NAME_MISMATCHED 1)
  find_package(Zlib REQUIRED)
  find_package(OpenSSL REQUIRED)
  unset(FPHSA_NAME_MISMATCHED)

  # ToDo: Windows

  set(MARIADBCLIENT_LIBRARY ${${MODULE}_LIBRARY})
  set(MARIADBCLIENT_INCLUDE_DIR ${${MODULE}_INCLUDE_DIR})
  set(MARIADBCLIENT_VERSION_STRING ${${MODULE}_VER})

  if(CORE_PLATFORM_NAME STREQUAL tvos)
    list(APPEND EXTRA_ARGS -DHAVE_UCONTEXT_H= -DHAVE_FILE_UCONTEXT_H=)
  endif()

  find_program(PATCH_EXECUTABLE NAMES patch patch.exe REQUIRED)

  if(CORE_SYSTEM_NAME STREQUAL linux)
    set(PATCH_COMMAND ${PATCH_EXECUTABLE} -p1 -i ${CMAKE_SOURCE_DIR}/tools/depends/target/mariadb/04-pthread.patch)
  elseif(CORE_SYSTEM_NAME STREQUAL android)
    set(PATCH_COMMAND ${PATCH_EXECUTABLE} -p1 -i ${CMAKE_SOURCE_DIR}/tools/depends/target/mariadb/01-android.patch)
  endif()

  set(CMAKE_ARGS -DCMAKE_INSTALL_PREFIX=${CMAKE_BINARY_DIR}/${CORE_BUILD_DIR}
                 -DCMAKE_CXX_STANDARD=${CMAKE_CXX_STANDARD}
                 -DCMAKE_PREFIX_PATH=${CMAKE_BINARY_DIR}/${CORE_BUILD_DIR}
                 -DCLIENT_PLUGIN_DIALOG=STATIC
                 -DCLIENT_PLUGIN_SHA256_PASSWORD=STATIC
                 -DCLIENT_PLUGIN_CACHING_SHA2_PASSWORD=STATIC
                 -DCLIENT_PLUGIN_MYSQL_CLEAR_PASSWORD=STATIC
                 -DCLIENT_PLUGIN_MYSQL_OLD_PASSWORD=STATIC
                 -DCLIENT_PLUGIN_CLIENT_ED25519=STATIC
                 -DCLIENT_PLUGIN_AUTH_GSSAPI_CLIENT=STATIC
                 -DWITH_SSL=OPENSSL
                 -DWITH_UNIT_TESTS=OFF
                 -DWITH_EXTERNAL_ZLIB=ON
                 -DWITH_CURL=OFF
                 "${EXTRA_ARGS}")

  BUILD_DEP_TARGET()

else()
  # Don't find system wide installed version on Windows
  if(WIN32)
    set(EXTRA_FIND_ARGS NO_SYSTEM_ENVIRONMENT_PATH)
  else()
    set(EXTRA_FIND_ARGS)
  endif()

  if(PKG_CONFIG_FOUND)
    pkg_check_modules(PC_MARIADBCLIENT mariadb QUIET)
  endif()


  find_path(MARIADBCLIENT_INCLUDE_DIR NAMES mariadb/mysql.h mariadb/server/mysql.h
                                             PATHS ${PC_MARIADBCLIENT_INCLUDEDIR})
  find_library(MARIADBCLIENT_LIBRARY_RELEASE NAMES mariadbclient mariadb libmariadb
                                             PATHS ${PC_MARIADBCLIENT_LIBDIR}
                                             PATH_SUFFIXES mariadb
                                             ${EXTRA_FIND_ARGS})
  find_library(MARIADBCLIENT_LIBRARY_DEBUG NAMES mariadbclient mariadb libmariadbd
                                           PATHS ${PC_MARIADBCLIENT_LIBDIR}
                                           PATH_SUFFIXES mariadb
                                           ${EXTRA_FIND_ARGS})

  if(PC_MARIADBCLIENT_VERSION)
    set(MARIADBCLIENT_VERSION_STRING ${PC_MARIADBCLIENT_VERSION})
  elseif(MARIADBCLIENT_INCLUDE_DIR AND EXISTS "${MARIADBCLIENT_INCLUDE_DIR}/mariadb/mariadb_version.h")
    file(STRINGS "${MARIADBCLIENT_INCLUDE_DIR}/mariadb/mariadb_version.h" mariadb_version_str REGEX "^#define[\t ]+MARIADB_CLIENT_VERSION_STR[\t ]+\".*\".*")
    string(REGEX REPLACE "^#define[\t ]+MARIADB_CLIENT_VERSION_STR[\t ]+\"([^\"]+)\".*" "\\1" MARIADBCLIENT_VERSION_STRING "${mariadb_version_str}")
    unset(mariadb_version_str)
  endif()

  include(SelectLibraryConfigurations)
  select_library_configurations(MARIADBCLIENT)
endif()
include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(MariaDBClient
                                  REQUIRED_VARS MARIADBCLIENT_LIBRARY MARIADBCLIENT_INCLUDE_DIR
                                  VERSION_VAR MARIADBCLIENT_VERSION_STRING)

if(MARIADBCLIENT_FOUND)
  set(MARIADBCLIENT_LIBRARIES ${MARIADBCLIENT_LIBRARY})
  set(MARIADBCLIENT_INCLUDE_DIRS ${MARIADBCLIENT_INCLUDE_DIR})
  set(MARIADBCLIENT_DEFINITIONS -DHAS_MARIADB=1)

  if(CORE_SYSTEM_NAME STREQUAL osx)
    list(APPEND DEPLIBS "-lgssapi_krb5")
  endif()

  if(NOT TARGET MariaDBClient::MariaDBClient)
    add_library(MariaDBClient::MariaDBClient UNKNOWN IMPORTED)
    if(MARIADBCLIENT_LIBRARY_RELEASE)
      set_target_properties(MariaDBClient::MariaDBClient PROPERTIES
                                                         IMPORTED_CONFIGURATIONS RELEASE
                                                         IMPORTED_LOCATION "${MARIADBCLIENT_LIBRARY_RELEASE}")
    endif()
    if(MARIADBCLIENT_LIBRARY_DEBUG)
      set_target_properties(MariaDBClient::MariaDBClient PROPERTIES
                                                         IMPORTED_CONFIGURATIONS DEBUG
                                                         IMPORTED_LOCATION "${MARIADBCLIENT_LIBRARY_DEBUG}")
    endif()
    set_target_properties(MariaDBClient::MariaDBClient PROPERTIES
                                                       INTERFACE_INCLUDE_DIRECTORIES "${MARIADBCLIENT_INCLUDE_DIR}"
                                                       INTERFACE_COMPILE_DEFINITIONS HAS_MARIADB=1)
  endif()
endif()

mark_as_advanced(MARIADBCLIENT_INCLUDE_DIR MARIADBCLIENT_LIBRARY)
