# Python uses ax_c_float_words_bigendian.m4 to find autoconf-archive
# Make sure we can find it as a requirement as well
find_file(AUTOCONF-ARCHIVE "ax_c_float_words_bigendian.m4" PATHS "${NATIVEPREFIX}/share/aclocal" NO_CMAKE_FIND_ROOT_PATH REQUIRED)
string(REGEX REPLACE "/ax_c_float_words_bigendian.m4" "" AUTOCONF-ARCHIVE ${AUTOCONF-ARCHIVE})
set(ACLOCAL_PATH_VAR "ACLOCAL_PATH=${AUTOCONF-ARCHIVE}")

# ToDo: if not found, recursively build
find_library(FFI_LIBRARY ffi REQUIRED)
find_library(EXPAT_LIBRARY expat REQUIRED)
find_library(INTL_LIBRARY intl REQUIRED)
find_library(GMP_LIBRARY gmp REQUIRED)
find_library(LZMA_LIBRARY lzma REQUIRED)

find_package(OpenSSL REQUIRED)
find_package(Sqlite3 REQUIRED)
find_package(BZip2 REQUIRED)
find_package(LibXml2 REQUIRED)

if(NOT CORE_SYSTEM_NAME STREQUAL android)
  set(PYTHON_DEP_LIBRARIES pthread dl util)
  if(CORE_SYSTEM_NAME STREQUAL linux)
    # python archive built via depends requires librt for _posixshmem library
    list(APPEND PYTHON_DEP_LIBRARIES rt)
  else(CORE_SYSTEM_NAME STREQUAL osx)
    list(APPEND PYTHON_DEP_LIBRARIES "-framework SystemConfiguration" "-framework CoreFoundation")
  endif()
endif()

include(ExternalProject)
include(cmake/scripts/common/ModuleHelpers.cmake)

set(MODULE_LC python3)

# Cant use SETUP_BUILD_VARS() macro due to fixup BASE_URL
get_archive_name(${MODULE_LC})
string(TOUPPER ${MODULE_LC} MODULE)

# allow user to override the download URL with a local tarball
# needed for offline build envs
if(${MODULE}_URL)
  get_filename_component(${MODULE}_URL "${${MODULE}_URL}" ABSOLUTE)
else()
  # fixup BASE_URL to replace $(VERSION) with actual version number
  string(REPLACE "\$\(VERSION\)" ${${MODULE}_VER} ${MODULE}_BASE_URL ${${MODULE}_BASE_URL})
  set(${MODULE}_URL ${${MODULE}_BASE_URL}/${${MODULE}_ARCHIVE})
endif()

if(VERBOSE)
  message(STATUS "${MODULE}_URL: ${${MODULE}_URL}")
endif()

# Set version major/minor
string(REGEX MATCH "^([0-9]?)\.([0-9]+)\." Python3_VERSION ${${MODULE}_VER})
set(Python3_VERSION_MAJOR ${CMAKE_MATCH_1} CACHE INTERNAL "" FORCE)
set(Python3_VERSION_MINOR ${CMAKE_MATCH_2} CACHE INTERNAL "" FORCE)

# ignore target bin location. we need host executable
# default search paths will look in both host and target build dirs
set(CMAKE_IGNORE_PATH ${DEPENDS_PATH}/bin)
find_package(Python3 EXACT ${Python3_VERSION_MAJOR}.${Python3_VERSION_MINOR}
                     COMPONENTS Interpreter
                     REQUIRED)
unset(CMAKE_IGNORE_PATH)

set(Python3_LIBRARIES ${DEPENDS_PATH}/lib/libpython${Python3_VERSION_MAJOR}.${Python3_VERSION_MINOR}.a CACHE INTERNAL "" FORCE)
set(Python3_INCLUDE_DIRS ${DEPENDS_PATH}/include CACHE INTERNAL "" FORCE)

if(CMAKE_SYSTEM_NAME STREQUAL Darwin)
  set(HOSTPLATFORM "_PYTHON_HOST_PLATFORM=\"darwin\"")
endif()

# set defalt to handle platform without a patch
set(PLATFORM_PATCH COMMAND "")

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
  set(PLATFORM_PATCH COMMAND patch -p1 -i "${CMAKE_SOURCE_DIR}/tools/depends/target/python3/01-${CORE_SYSTEM_NAME}-modules.patch")
endif()

set(CMD_PATCH PATCH_COMMAND ${CMAKE_COMMAND} -E copy
                                  ${CMAKE_SOURCE_DIR}/tools/depends/target/python3/modules.setup
                                  <SOURCE_DIR>/Modules/Setup
                          COMMAND patch -p1 -i ${CMAKE_SOURCE_DIR}/tools/depends/target/python3/crosscompile.patch
                          COMMAND patch -p1 -i ${CMAKE_SOURCE_DIR}/tools/depends/target/python3/android.patch
                          COMMAND patch -p1 -i ${CMAKE_SOURCE_DIR}/tools/depends/target/python3/apple.patch
                          ${PLATFORM_PATCH}
              )

# Set Target Configure command
set(CMD_CONFIGURE CONFIGURE_COMMAND set "PATH=${ENVPATH}"
                            COMMAND ${SETBUILDENV} autoreconf -vif
                            COMMAND ${SETBUILDENV}
                                    ./configure
                                    --disable-shared
                                    --without-ensurepip
                                    --disable-framework
                                    --without-pymalloc
                                    --enable-ipv6
                                    --prefix=${DEPENDS_PATH}
                                    ${EXTRA_CONFIGURE}
                  )

# Set Target Build command
set(CMD_BUILD BUILD_COMMAND BUILD_COMMAND $(MAKE) ${HOSTPLATFORM} prefix=${DEPENDS_PATH} PYTHON_FOR_BUILD=${Python3_EXECUTABLE} CROSS_COMPILE_TARGET=yes libpython${Python3_VERSION_MAJOR}.${Python3_VERSION_MINOR}.a)

# Set Target Install command
set(CMD_INSTALL INSTALL_COMMAND $(MAKE) install)

# Set Target Byproduct
set(BYPRODUCT BUILD_BYPRODUCTS ${Python3_LIBRARIES})

# Execute externalproject_add for dependency
TARGET_PROJECTADD()

list(APPEND Python3_LIBRARIES ${LZMA_LIBRARY} ${FFI_LIBRARY} ${EXPAT_LIBRARY} ${INTL_LIBRARY} ${GMP_LIBRARY} ${LIBXML2_LIBRARY} ${OPENSSL_LIBRARIES} ${SQLITE3_LIBRARY} ${BZIP2_LIBRARIES} ${PYTHON_DEP_LIBRARIES})

# PYTHONPATH var required for pythonmodules
set(PYTHON_SITE_PKG "${DEPENDS_PATH}/lib/python${Python3_VERSION_MAJOR}.${Python3_VERSION_MINOR}/site-packages" CACHE INTERNAL "" FORCE)
set(PYTHONPATH PYTHONPATH=${PYTHON_SITE_PKG} CACHE INTERNAL "" FORCE)

set(Python3_FOUND TRUE CACHE INTERNAL "" FORCE)

set_target_properties(python3 PROPERTIES FOLDER "External Projects")