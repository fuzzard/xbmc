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
  find_package(Python3 ${VERSION} ${EXACT_VER} COMPONENTS Interpreter)
endif()

if(KODI_DEPENDSBUILD OR ENABLE_INTERNAL_PYTHON)

  # Python uses ax_c_float_words_bigendian.m4 to find autoconf-archive
  # Make sure we can find it as a requirement as well
  find_file(AUTOCONF-ARCHIVE "ax_c_float_words_bigendian.m4" PATHS "${NATIVEPREFIX}/share/aclocal" NO_CMAKE_FIND_ROOT_PATH REQUIRED)
  string(REGEX REPLACE "/ax_c_float_words_bigendian.m4" "" AUTOCONF-ARCHIVE ${AUTOCONF-ARCHIVE})
  set(ACLOCAL_PATH_VAR "ACLOCAL_PATH=${AUTOCONF-ARCHIVE}")

  find_library(FFI_LIBRARY ffi REQUIRED)
  find_library(EXPAT_LIBRARY expat REQUIRED)
  find_library(INTL_LIBRARY intl REQUIRED)
  find_library(GMP_LIBRARY gmp REQUIRED)
  find_library(LZMA_LIBRARY lzma REQUIRED)
  find_package(OpenSSL REQUIRED)

  if(NOT CORE_SYSTEM_NAME STREQUAL android)
    set(PYTHON_DEP_LIBRARIES pthread dl util)
    if(CORE_SYSTEM_NAME STREQUAL linux)
      # python archive built via depends requires librt for _posixshmem library
      list(APPEND PYTHON_DEP_LIBRARIES rt)
    endif()
  endif()

  include(ExternalProject)
  include(cmake/scripts/common/ModuleHelpers.cmake)

  get_archive_name(python3)

  # allow user to override the download URL with a local tarball
  # needed for offline build envs
  if(PYTHON3_URL)
    get_filename_component(PYTHON3_URL "${PYTHON3_URL}" ABSOLUTE)
  else()
    # fixup BASE_URL to replace $(VERSION) with actual version number
    string(REPLACE "\$\(VERSION\)" ${PYTHON3_VER} PYTHON3_BASE_URL ${PYTHON3_BASE_URL})
    set(PYTHON3_URL ${PYTHON3_BASE_URL}/${ARCHIVE})
  endif()
  if(VERBOSE)
    message(STATUS "PYTHON3_URL: ${PYTHON3_URL}")
  endif()

  # Set version major/minor
  string(REGEX MATCH "^([0-9]?)\.([0-9]+)\." Python3_VERSION ${PYTHON3_VER})
  set(Python3_VERSION_MAJOR ${CMAKE_MATCH_1})
  set(Python3_VERSION_MINOR ${CMAKE_MATCH_2})

  set(Python3_LIBRARIES ${CMAKE_BINARY_DIR}/${CORE_BUILD_DIR}/libpython${Python3_VERSION_MAJOR}.${Python3_VERSION_MINOR}.a)
  set(Python3_INCLUDE_DIRS ${CMAKE_BINARY_DIR}/${CORE_BUILD_DIR}/Include)

  if(CMAKE_SYSTEM_NAME STREQUAL Darwin)
    set(HOSTPLATFORM "_PYTHON_HOST_PLATFORM=\"darwin\"")
  endif()

  if(CORE_SYSTEM_NAME STREQUAL linux)
    set(EXTRA_CONFIGURE ac_cv_pthread=yes)
  elseif(CORE_SYSTEM_NAME STREQUAL darwin_embedded)
    set(EXTRA_CONFIGURE ac_cv_func_wait3=no ac_cv_func_wait4=no ac_cv_func_waitpid=no)
    list(APPEND EXTRA_CONFIGURE ac_cv_func_execv=no ac_cv_func_fexecv=no ac_cv_func_getentropy=no)
    list(APPEND EXTRA_CONFIGURE ac_cv_func_setpriority=no ac_cv_func_sendfile=no ac_cv_header_sched_h=no)
    list(APPEND EXTRA_CONFIGURE ac_cv_func_posix_spawn=no ac_cv_func_posix_spawnp=no)
    list(APPEND EXTRA_CONFIGURE ac_cv_func_forkpty=no ac_cv_lib_util_forkpty=no)
    list(APPEND EXTRA_CONFIGURE ac_cv_func_getgroups=no)
  endif()

  if(EXISTS "${CMAKE_SOURCE_DIR}/tools/depends/target/python3/01-${CORE_SYSTEM_NAME}-modules.patch")
      set(PLATFORM_PATCH patch -p1 -i "${CMAKE_SOURCE_DIR}/tools/depends/target/python3/01-${CORE_SYSTEM_NAME}-modules.patch")
  endif()

 # MESSAGE(FATAL_ERROR "PLATFORM_PATCH: ${PLATFORM_PATCH}")

  externalproject_add(python3
                      URL ${PYTHON3_URL}
                      URL_HASH SHA256=0a8fbfb5287ebc3a13e9baf3d54e08fa06778ffeccf6311aef821bb3a6586cc8
                      DOWNLOAD_NAME ${ARCHIVE}
                      DOWNLOAD_DIR ${TARBALL_DIR}
                      PREFIX ${CORE_BUILD_DIR}/python3
                      PATCH_COMMAND ${CMAKE_COMMAND} -E copy
                                    ${CMAKE_SOURCE_DIR}/tools/depends/target/python3/modules.setup
                                    <SOURCE_DIR>/Modules/Setup
                            COMMAND patch -p1 -i ${CMAKE_SOURCE_DIR}/tools/depends/target/python3/crosscompile.patch
                            COMMAND patch -p1 -i ${CMAKE_SOURCE_DIR}/tools/depends/target/python3/android.patch
                            COMMAND patch -p1 -i ${CMAKE_SOURCE_DIR}/tools/depends/target/python3/apple.patch
                            COMMAND ${PLATFORM_PATCH}
                      CONFIGURE_COMMAND ${ACLOCAL_PATH_VAR} autoreconf -vif
                                COMMAND ${CMAKE_COMMAND} -E env CFLAGS=${CMAKE_C_FLAGS} CPPFLAGS=${CMAKE_CPP_FLAGS} LDFLAGS=${CMAKE_EXE_LINKER_FLAGS}
                                        ./configure
                                        --disable-shared
                                        --without-ensurepip
                                        --disable-framework
                                        --without-pymalloc
                                        --enable-ipv6
                                        --prefix=${CMAKE_BINARY_DIR}/${CORE_BUILD_DIR}/depends/target
                                        ${EXTRA_CONFIGURE}
                      BUILD_COMMAND $(MAKE) ${HOSTPLATFORM} prefix=${DEPENDS_PATH} PYTHON_FOR_BUILD=${NATIVEPREFIX}/bin/python3 CROSS_COMPILE_TARGET=yes libpython${Python3_VERSION_MAJOR}.${Python3_VERSION_MINOR}.a
                      INSTALL_COMMAND $(MAKE) install
                      BUILD_BYPRODUCTS ${Python3_LIBRARIES}
                      BUILD_IN_SOURCE 1)

  list(APPEND Python3_LIBRARIES ${LZMA_LIBRARY} ${FFI_LIBRARY} ${EXPAT_LIBRARY} ${INTL_LIBRARY} ${GMP_LIBRARY} ${PYTHON_DEP_LIBRARIES})

  set(Python3_FOUND TRUE)

  # ToDo: build pythonmodules if KODI_DEPENDSBUILD

  set_target_properties(python3 PROPERTIES FOLDER "External Projects")
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
endif()

mark_as_advanced(PYTHON_EXECUTABLE PYTHON_VERSION PYTHON_INCLUDE_DIRS PYTHON_LDFLAGS LZMA_LIBRARY FFI_LIBRARY EXPAT_LIBRARY INTL_LIBRARY GMP_LIBRARY)
