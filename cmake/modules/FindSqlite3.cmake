#.rst:
# FindSqlite3
# -----------
# Finds the SQLite3 library
#
# This will define the following variables::
#
# SQLITE3_FOUND - system has SQLite3
# SQLITE3_INCLUDE_DIRS - the SQLite3 include directory
# SQLITE3_LIBRARIES - the SQLite3 libraries
#
# and the following imported targets::
#
#   SQLite3::SQLite3 - The SQLite3 library

if(NOT SQLite3::SQLite3)

  include(cmake/scripts/common/ModuleHelpers.cmake)

  set(MODULE_LC sqlite3)

  SETUP_BUILD_VARS()

  if(CORE_SYSTEM_NAME MATCHES windows)
    find_package(SQLITE3 CONFIG QUIET)
  else()
    find_package(PkgConfig REQUIRED QUITE)
    if(PKG_CONFIG_FOUND)
      pkg_check_modules(PC_SQLITE3 sqlite3 QUIET)
    endif()
  endif()

  if(PC_SQLITE3_FOUND)
    find_path(SQLITE3_INCLUDE_DIR NAMES sqlite3.h
                                  PATHS ${PC_SQLITE3_INCLUDEDIR})
    find_library(SQLITE3_LIBRARY NAMES sqlite3
                                 PATHS ${PC_SQLITE3_LIBDIR})

    set(SQLITE3_VERSION ${PC_SQLITE3_VERSION})
  else(SQLITE3_FOUND)

    # Found windows cmake config
    # ToDo: 

  else()
    if(ENABLE_INTERNAL_SQLITE3)
      if(CORE_SYSTEM_NAME MATCHES windows)

        set(patches "${CMAKE_SOURCE_DIR}/tools/depends/target/${MODULE_LC}/002-win-cmake.patch")
        generate_patchcommand("${patches}")

        set(CMAKE_ARGS -DBUILD_SHARED_LIBS=OFF)
      else()
        find_program(AUTORECONF autoreconf REQUIRED)
        find_program(MAKE_EXECUTABLE make REQUIRED)

        set(SQLITE3_CFLAGS "-DSQLITE_TEMP_STORE=3 -DSQLITE_DEFAULT_MMAP_SIZE=0x10000000")
        set(SQLITE3_CXXFLAGS -DSQLITE_ENABLE_COLUMN_METADATA=1)

        set(patches "${CMAKE_SOURCE_DIR}/tools/depends/target/${MODULE_LC}/001-all-disableprogram.patch")

        if(CORE_SYSTEM_NAME STREQUAL android)
          list(APPEND patches "${CMAKE_SOURCE_DIR}/tools/depends/target/${MODULE_LC}/sqlite3.c.patch")
        endif()

        generate_patchcommand("${patches}")

        set(CONFIGURE_COMMAND ${AUTORECONF} -vif
                      COMMAND ./configure --prefix=${DEPENDS_PATH}
                                          --disable-shared
                                          --enable-threadsafe
                                          --disable-readline
                                          "CC=${CMAKE_C_COMPILER}"
                                          "CFLAGS=${CMAKE_C_FLAGS} ${SQLITE3_CFLAGS}"
                                          "CXXFLAGS=${CMAKE_CXX_FLAGS} ${SQLITE3_CXXFLAGS}")
        set(BUILD_COMMAND ${MAKE_EXECUTABLE})
        set(INSTALL_COMMAND ${MAKE_EXECUTABLE} install)
        set(BUILD_IN_SOURCE 1)
      endif()

      BUILD_DEP_TARGET()
    endif()
  endif()

  include(FindPackageHandleStandardArgs)
  find_package_handle_standard_args(Sqlite3
                                    REQUIRED_VARS SQLITE3_LIBRARY SQLITE3_INCLUDE_DIR
                                    VERSION_VAR SQLITE3_VERSION)

  if(SQLITE3_FOUND)
    set(SQLITE3_INCLUDE_DIRS ${SQLITE3_INCLUDE_DIR})
    set(SQLITE3_LIBRARIES ${SQLITE3_LIBRARY})

    if(NOT TARGET SQLite3::SQLite3)
      add_library(SQLite3::SQLite3 UNKNOWN IMPORTED)
      set_target_properties(SQLite3::SQLite3 PROPERTIES
                                             IMPORTED_LOCATION "${SQLITE3_LIBRARY}"
                                             INTERFACE_INCLUDE_DIRECTORIES "${SQLITE3_INCLUDE_DIR}")

      if(TARGET sqlite3)
        add_dependencies(SQLite3::SQLite3 sqlite3)
      endif()
    endif()
  endif()

  mark_as_advanced(SQLITE3_INCLUDE_DIR SQLITE3_LIBRARY)
endif()