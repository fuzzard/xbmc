# FindPython
# --------
# Finds Python3 libraries
#
# This module will search for the required python libraries on the system
# If multiple versions are found, the highest version will be used.
#
# --------
#
# the following variables influence behaviour:
#
# PYTHON_PATH - use external python not found in system paths
#               usage: -DPYTHON_PATH=/path/to/python/lib
# PYTHON_VER - use exact python version, fail if not found
#               usage: -DPYTHON_VER=3.8
#
# --------
#
# This module will define the following variables:
#
# PYTHON_FOUND - system has PYTHON
# PYTHON_VERSION - Python version number (Major.Minor)
# PYTHON_EXECUTABLE - Python interpreter binary
# PYTHON_INCLUDE_DIRS - the python include directory
# PYTHON_LIBRARIES - The python libraries
# PYTHON_LDFLAGS - Python provided link options
#
# --------
#

# for Depends/Windows builds, set search root dir to libdir path
if(KODI_DEPENDSBUILD
   OR CMAKE_SYSTEM_NAME STREQUAL WINDOWS
   OR CMAKE_SYSTEM_NAME STREQUAL WindowsStore)
  set(Python3_USE_STATIC_LIBS TRUE)
  set(Python3_ROOT_DIR ${libdir})

  include(cmake/scripts/common/ModuleHelpers.cmake)

  if(KODI_DEPENDSBUILD OR ENABLE_INTERNAL_PYTHON)

    # Check for dependencies - Must be done before SETUP_BUILD_VARS
    get_libversion_data("python3" "target")

    # Force set to tools/depends python version
    set(PYTHON_VER ${LIB_PYTHON3_VER})
  endif()
endif()

# Provide root dir to search for Python if provided
if(PYTHON_PATH)
  set(Python3_ROOT_DIR ${PYTHON_PATH})

  # unset cache var so we can generate again with a different dir (or none) if desired
  unset(PYTHON_PATH CACHE)
endif()

# Set specific version of Python to find if provided
if(PYTHON_VER)
  set(VERSION ${PYTHON_VER})
  set(EXACT_VER "EXACT")

  # unset cache var so we can generate again with a different ver (or none) if desired
  unset(PYTHON_VER CACHE)
endif()

if(NOT ENABLE_INTERNAL_PYTHON)
  find_package(Python3 ${VERSION} ${EXACT_VER} COMPONENTS Development)
endif()

if(CORE_SYSTEM_NAME STREQUAL linux)
  if(HOST_CAN_EXECUTE_TARGET)
    find_package(Python3 ${VERSION} ${EXACT_VER} COMPONENTS Interpreter)
  else()
    find_package(Python3 COMPONENTS Interpreter)
  endif()
endif()

if(KODI_DEPENDSBUILD OR ENABLE_INTERNAL_PYTHON)

  if(WIN32 OR WINDOWS_STORE)
    # ToDo: add zlib to dep link list
    # Windows is built as a dll, only require linking to zlib
    find_package(zlib CONFIG REQUIRED)
  else()
    find_library(FFI_LIBRARY ffi REQUIRED)
    find_library(EXPAT_LIBRARY expat REQUIRED)
    find_library(LZMA_LIBRARY lzma REQUIRED)
    find_library(INTL_LIBRARY intl REQUIRED)
    find_library(GMP_LIBRARY gmp REQUIRED)

    find_package(OpenSSL REQUIRED)
    find_package(Sqlite3 REQUIRED)
    find_package(BZip2 REQUIRED)
    find_package(LibXml2 REQUIRED)
  endif()

  # ToDo existing build reqs not handled
  #python3:  gettext $(ICONV)

  # Set version major/minor from earlier get_libversion_data call
  get_libversion_data("python3" "target")
  string(REGEX MATCH "^([0-9]?)\.([0-9]+)\." Python3_VERSION ${LIB_PYTHON3_VER})
  set(Python3_VERSION_MAJOR ${CMAKE_MATCH_1} CACHE INTERNAL "" FORCE)
  set(Python3_VERSION_MINOR ${CMAKE_MATCH_2} CACHE INTERNAL "" FORCE)

  set(MODULE_LC python3)
  SETUP_BUILD_VARS()

  if(CMAKE_SYSTEM_NAME STREQUAL Darwin)
    set(HOSTPLATFORM "_PYTHON_HOST_PLATFORM=\"darwin\"")
  elseif(CMAKE_SYSTEM_NAME STREQUAL Linux)
    set(HOSTPLATFORM "_PYTHON_HOST_PLATFORM=\"linux\"")
  endif()

  if(CORE_SYSTEM_NAME STREQUAL linux)
    set(EXTRA_CONFIGURE ac_cv_pthread=yes)
  elseif(CMAKE_SYSTEM_NAME STREQUAL Darwin)
    set(EXTRA_CONFIGURE ac_cv_lib_intl_textdomain=yes)

    set(CONFIG_OPTS "--with-system-ffi")

    if(CORE_SYSTEM_NAME STREQUAL darwin_embedded)
      list(APPEND EXTRA_CONFIGURE ac_cv_func_execv=no)
      list(APPEND EXTRA_CONFIGURE ac_cv_func_fexecv=no)
      list(APPEND EXTRA_CONFIGURE ac_cv_func_forkpty=no)
      list(APPEND EXTRA_CONFIGURE ac_cv_func_getentropy=no)
      list(APPEND EXTRA_CONFIGURE ac_cv_func_getgroups=no)
      list(APPEND EXTRA_CONFIGURE ac_cv_func_posix_spawn=no)
      list(APPEND EXTRA_CONFIGURE ac_cv_func_posix_spawnp=no)
      list(APPEND EXTRA_CONFIGURE ac_cv_func_sendfile=no)
      list(APPEND EXTRA_CONFIGURE ac_cv_func_setpriority=no)
      list(APPEND EXTRA_CONFIGURE ac_cv_func_system=no)
      list(APPEND EXTRA_CONFIGURE ac_cv_func_wait3=no)
      list(APPEND EXTRA_CONFIGURE ac_cv_func_wait4=no)
      list(APPEND EXTRA_CONFIGURE ac_cv_func_waitpid=no)

      list(APPEND EXTRA_CONFIGURE ac_cv_header_sched_h=no)
      list(APPEND EXTRA_CONFIGURE ac_cv_header_sched_h=no)

      list(APPEND EXTRA_CONFIGURE ac_cv_lib_util_forkpty=no)
    endif()
  endif()

  if(WIN32 OR WINDOWS_STORE)
	    set(patches "${CMAKE_SOURCE_DIR}/tools/depends/target/python3/01-win-cmake.patch"
                  "${CMAKE_SOURCE_DIR}/tools/depends/target/python3/02-win-modules.patch"
                  "${CMAKE_SOURCE_DIR}/tools/depends/target/python3/03-win-PC.patch"
                  "${CMAKE_SOURCE_DIR}/tools/depends/target/python3/04-win-Python.patch"
                  "${CMAKE_SOURCE_DIR}/tools/depends/target/python3/05-win-winregistryfinder.patch"
          )
  else()
    set(patches "${CMAKE_SOURCE_DIR}/tools/depends/target/python3/crosscompile.patch")

    if(CMAKE_SYSTEM_NAME STREQUAL Darwin)
      list(APPEND patches "${CMAKE_SOURCE_DIR}/tools/depends/target/python3/apple.patch")

      if(CORE_SYSTEM_NAME STREQUAL darwin_embedded)
        list(APPEND patches "${CMAKE_SOURCE_DIR}/tools/depends/target/python3/darwin_embedded.patch")
      endif()
    endif()
  endif()

  if(EXISTS "${CMAKE_SOURCE_DIR}/tools/depends/target/python3/10-${CORE_SYSTEM_NAME}-modules.patch")
      list(APPEND patches "${CMAKE_SOURCE_DIR}/tools/depends/target/python3/10-${CORE_SYSTEM_NAME}-modules.patch")
  endif()

  generate_patchcommand("${patches}")

  # We prepend this after generate_patchcommand as we dont want to run this through that function
  list(PREPEND PATCH_COMMAND ${CMAKE_COMMAND} -E copy
                             ${CMAKE_SOURCE_DIR}/tools/depends/target/python3/modules.setup
                             <SOURCE_DIR>/Modules/Setup
                             COMMAND)

  if(CORE_SYSTEM_NAME MATCHES windows)
    if(CMAKE_SYSTEM_NAME STREQUAL WindowsStore)
        set(ADDITIONAL_ARGS "-DCMAKE_SYSTEM_NAME=${CMAKE_SYSTEM_NAME}" "-DCMAKE_SYSTEM_VERSION=${CMAKE_SYSTEM_VERSION}")
    endif()

    set(CMAKE_ARGS -DCMAKE_MODULE_PATH=${CMAKE_MODULE_PATH}
                   -DDEPENDS_PATH=${DEPENDS_PATH}
                   -DCMAKE_INSTALL_PREFIX=${DEPENDS_PATH}
                   -DCMAKE_BUILD_TYPE=RelWithDebInfo
                   ${ADDITIONAL_ARGS})
  else()

    if(NOT CORE_SYSTEM_NAME STREQUAL android)
      set(PYTHON_DEP_LIBRARIES pthread dl util)
      if(CORE_SYSTEM_NAME STREQUAL linux)
        # python archive built via depends requires librt for _posixshmem library
        list(APPEND PYTHON_DEP_LIBRARIES rt)
      else(CORE_SYSTEM_NAME STREQUAL osx)
        list(APPEND PYTHON_DEP_LIBRARIES "-framework SystemConfiguration" "-framework CoreFoundation")
      endif()
    endif()

    find_program(AUTORECONF autoreconf REQUIRED)
    find_program(MAKE_EXECUTABLE make REQUIRED)

    # Python uses ax_c_float_words_bigendian.m4 to find autoconf-archive
    # Make sure we can find it as a requirement as well
    find_file(AUTOCONF-ARCHIVE "ax_c_float_words_bigendian.m4" PATHS "${NATIVEPREFIX}/share/aclocal" NO_CMAKE_FIND_ROOT_PATH REQUIRED)
    string(REGEX REPLACE "/ax_c_float_words_bigendian.m4" "" AUTOCONF-ARCHIVE ${AUTOCONF-ARCHIVE})
    set(ACLOCAL_PATH_VAR "ACLOCAL_PATH=${AUTOCONF-ARCHIVE}")

    set(CONFIGURE_COMMAND ${ACLOCAL_PATH_VAR} ${AUTORECONF} -vif
                  COMMAND ${CMAKE_COMMAND} -E env ${PROJECT_TARGETENV}
                          ./configure
                            --prefix=${DEPENDS_PATH}
                            --disable-shared
                            --without-ensurepip
                            --disable-framework
                            --without-pymalloc
                            --enable-ipv6
                            --with-build-python=${NATIVEPREFIX}/bin/python3
                            --with-system-expat=yes
                            --disable-test-modules
                            ${CONFIG_OPTS}
                            MODULE_BUILDTYPE=static
                            ${EXTRA_CONFIGURE})

    set(BUILD_COMMAND ${CMAKE_COMMAND} -E env ${PROJECT_TARGETENV}
                      ${MAKE_EXECUTABLE} ${HOSTPLATFORM} CROSS_COMPILE_TARGET=yes libpython${Python3_VERSION_MAJOR}.${Python3_VERSION_MINOR}.a)

    set(INSTALL_COMMAND ${CMAKE_COMMAND} -E env ${PROJECT_TARGETENV}
                        ${MAKE_EXECUTABLE} ${HOSTPLATFORM} CROSS_COMPILE_TARGET=yes install)
    set(BUILD_IN_SOURCE 1)

  endif()

  BUILD_DEP_TARGET()

  set(PYTHON_SITE_PKG "${DEPENDS_PATH}/lib/python${Python3_VERSION_MAJOR}.${Python3_VERSION_MINOR}/site-packages" CACHE INTERNAL "" FORCE)

  # Todo: If dependencies are built internally, add here
  #  add_dependencies(${MODULE_LC} fmt::fmt)

  include(SelectLibraryConfigurations)
  select_library_configurations(PYTHON3)

  include(FindPackageHandleStandardArgs)
  find_package_handle_standard_args(Python
                                    REQUIRED_VARS PYTHON3_LIBRARY PYTHON3_INCLUDE_DIR
                                    VERSION_VAR PYTHON3_VERSION)

  set(Python3_LIBRARIES ${PYTHON3_LIBRARY})
  set(Python3_INCLUDE_DIRS "${PYTHON3_INCLUDE_DIR}/python${Python3_VERSION_MAJOR}.${Python3_VERSION_MINOR}")
  set(Python3_FOUND ON)

  list(APPEND Python3_LIBRARIES ${LZMA_LIBRARY} ${FFI_LIBRARY} ${EXPAT_LIBRARY} ${INTL_LIBRARY} ${GMP_LIBRARY} ${LIBXML2_LIBRARY} ${OPENSSL_LIBRARIES} ${SQLITE3_LIBRARY} ${BZIP2_LIBRARIES} ${PYTHON_DEP_LIBRARIES})
endif()

if(Python3_FOUND)
  list(APPEND PYTHON_DEFINITIONS -DHAS_PYTHON=1)
  # These are all set for easy integration with the rest of our build system
  set(PYTHON_FOUND ${Python3_FOUND})
  if(NOT PYTHON_EXECUTABLE)
    set(PYTHON_EXECUTABLE ${Python3_EXECUTABLE} CACHE FILEPATH "Python interpreter" FORCE)
  endif()
  set(PYTHON_INCLUDE_DIRS ${Python3_INCLUDE_DIRS})
  set(PYTHON_LIBRARIES ${Python3_LIBRARIES})
  set(PYTHON_VERSION "${Python3_VERSION_MAJOR}.${Python3_VERSION_MINOR}" CACHE INTERNAL "" FORCE)
  set(PYTHON_LDFLAGS ${Python3_LINK_OPTIONS})

  if(NOT TARGET Python3::Python)
    add_library(Python3::Python UNKNOWN IMPORTED)
    if(PYTHON3_LIBRARY_RELEASE)
      set_target_properties(Python3::Python PROPERTIES
                                            IMPORTED_CONFIGURATIONS RELEASE
                                            IMPORTED_LOCATION "${PYTHON3_LIBRARY_RELEASE}")
    endif()
    if(PYTHON3_LIBRARY_DEBUG)
      set_target_properties(Python3::Python PROPERTIES
                                            IMPORTED_CONFIGURATIONS DEBUG
                                            IMPORTED_LOCATION "${PYTHON3_LIBRARY_DEBUG}")
    endif()
    set_target_properties(Python3::Python PROPERTIES
                                          INTERFACE_INCLUDE_DIRECTORIES "${PYTHON_INCLUDE_DIRS}"
                                          INTERFACE_LINK_LIBRARIES "${Python3_LIBRARIES}")
  endif()

  if(TARGET python3)
    add_dependencies(Python3::Python python3)
  endif()
  set_property(GLOBAL APPEND PROPERTY INTERNAL_DEPS_PROP Python3::Python)
endif()

mark_as_advanced(PYTHON_EXECUTABLE PYTHON_VERSION PYTHON_INCLUDE_DIRS PYTHON_LDFLAGS LZMA_LIBRARY FFI_LIBRARY EXPAT_LIBRARY INTL_LIBRARY GMP_LIBRARY)
