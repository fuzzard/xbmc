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
# This will define the following targets:
#
#   ${APP_NAME_LC}::Python - The Python library

if(NOT TARGET ${APP_NAME_LC}::${CMAKE_FIND_PACKAGE_NAME})

  macro(buildPython3)

    string(REGEX MATCH "^([0-9]?)\.([0-9]+)\." python3_VERSION ${${MODULE}_VER})
    set(Python3_VERSION_MAJOR ${CMAKE_MATCH_1} CACHE INTERNAL "" FORCE)
    set(Python3_VERSION_MINOR ${CMAKE_MATCH_2} CACHE INTERNAL "" FORCE)

    set(patches "${CMAKE_SOURCE_DIR}/tools/depends/target/python3/01-py312-cpython118618-1.patch"
                "${CMAKE_SOURCE_DIR}/tools/depends/target/python3/01-py312-cpython118618-2.patch")

    if(WIN32 OR WINDOWS_STORE)
      list(APPEND patches "${CMAKE_SOURCE_DIR}/tools/depends/target/python3/01-win-cmake.patch"
                          "${CMAKE_SOURCE_DIR}/tools/depends/target/python3/02-win-modules.patch"
                          "${CMAKE_SOURCE_DIR}/tools/depends/target/python3/03-win-PC.patch"
                          "${CMAKE_SOURCE_DIR}/tools/depends/target/python3/04-win-Python.patch"
                          "${CMAKE_SOURCE_DIR}/tools/depends/target/python3/05-win-winregistryfinder.patch")
    else()
      if(CMAKE_SYSTEM_NAME STREQUAL Darwin)
        list(APPEND patches "${CMAKE_SOURCE_DIR}/tools/depends/target/python3/apple.patch")

        if(CORE_SYSTEM_NAME STREQUAL darwin_embedded)
          list(APPEND patches "${CMAKE_SOURCE_DIR}/tools/depends/target/python3/darwin_embedded.patch")
        endif()
      elseif( CORE_SYSTEM_NAME STREQUAL android)
        list(APPEND patches "${CMAKE_SOURCE_DIR}/tools/depends/target/python3/02-android-cpython114875.patch"
                            "${CMAKE_SOURCE_DIR}/tools/depends/target/python3/10-android-modules.patch")
      endif()
    endif()

    generate_patchcommand("${patches}")

    if(CORE_SYSTEM_NAME MATCHES windows)
      # Windows is built as a dll, only require linking to zlib
      find_package(zlib CONFIG REQUIRED)

      # These packages are all required by cpython modules, therefore do checks now.
      find_package(expat CONFIG REQUIRED)
      find_package(openssl CONFIG REQUIRED)
      find_package(bzip2 CONFIG REQUIRED)
      find_package(libffi CONFIG REQUIRED)
      find_package(xz CONFIG REQUIRED)
      find_package(sqlite3 CONFIG REQUIRED)

      list(APPEND Py_LINK_LIBRARIES zlib::zlibstatic)

      set(CMAKE_ARGS -DCMAKE_MODULE_PATH=${CMAKE_MODULE_PATH}
                     -DDEPENDS_PATH=${DEPENDS_PATH}
                     -DNATIVEPREFIX=${NATIVEPREFIX}
                     -DENABLE_MODULES=ON
                     -DCMAKE_INSTALL_PREFIX=${DEPENDS_PATH}
                     -DCMAKE_BUILD_TYPE=RelWithDebInfo
                     -DARCH=${ARCH}
                     ${ADDITIONAL_ARGS})
    else()

      # pkg-config packages
      find_library(EXPAT_LIBRARY expat REQUIRED)
      find_library(FFI_LIBRARY ffi REQUIRED)
      find_library(GMP_LIBRARY gmp REQUIRED)
      find_library(INTL_LIBRARY intl REQUIRED)
      find_library(LZMA_LIBRARY lzma REQUIRED)

      # cmake config ready packages
      find_package(BZip2 REQUIRED)
      find_package(Iconv REQUIRED)
      find_package(LibXml2 REQUIRED)
      find_package(OpenSSL REQUIRED)
      find_package(Sqlite3 REQUIRED)

      # Build tools
      find_program(AUTORECONF autoreconf REQUIRED)
      find_program(MAKE_EXECUTABLE make REQUIRED)
      find_package(PythonInterpreter REQUIRED)

      # Python uses ax_c_float_words_bigendian.m4 to find autoconf-archive
      # Make sure we can find it as a requirement as well
      find_file(AUTOCONF-ARCHIVE ax_c_float_words_bigendian.m4 REQUIRED
                                 HINTS "${NATIVEPREFIX}/share/aclocal"
                                 NO_CMAKE_FIND_ROOT_PATH)
      string(REGEX REPLACE "/ax_c_float_words_bigendian.m4" "" AUTOCONF-ARCHIVE ${AUTOCONF-ARCHIVE})
      set(ACLOCAL_PATH_VAR "ACLOCAL_PATH=${AUTOCONF-ARCHIVE}")

      # ToDo existing build reqs not handled
      #python3:  gettext

      # ToDo: change bzip/libxml to TARGET
      list(APPEND Py_LINK_LIBRARIES ${EXPAT_LIBRARY}
                                    ${FFI_LIBRARY}
                                    ${GMP_LIBRARY}
                                    ${INTL_LIBRARY}
                                    ${LZMA_LIBRARY}
                                    BZip2::BZip2
                                    ${APP_NAME_LC}::Iconv
                                    LibXml2::LibXml2
                                    ${APP_NAME_LC}::OpenSSL
                                    ${APP_NAME_LC}::Sqlite3)

      if(CORE_SYSTEM_NAME STREQUAL linux)
        set(EXTRA_CONFIGURE ac_cv_pthread=yes)
        if("webos" IN_LIST CORE_PLATFORM_NAME_LC)
          list(APPEND EXTRA_CONFIGURE ac_cv_lib_intl_textdomain=yes)
        endif()
      elseif(CMAKE_SYSTEM_NAME STREQUAL Darwin)
        set(HOSTPLATFORM "_PYTHON_HOST_PLATFORM=\"darwin\"")
        set(EXTRA_CONFIGURE ac_cv_lib_intl_textdomain=yes)

        if(CORE_SYSTEM_NAME STREQUAL darwin_embedded)
          list(APPEND EXTRA_CONFIGURE ac_cv_func_execv=no
                                      ac_cv_func_fexecv=no
                                      ac_cv_func_forkpty=no
                                      ac_cv_func_getentropy=no
                                      ac_cv_func_getgroups=no
                                      ac_cv_func_posix_spawn=no
                                      ac_cv_func_posix_spawnp=no
                                      ac_cv_func_sendfile=no
                                      ac_cv_func_setpriority=no
                                      ac_cv_func_system=no
                                      ac_cv_func_wait3=no
                                      ac_cv_func_wait4=no
                                      ac_cv_func_waitpid=no
                                      ac_cv_header_sched_h=no
                                      ac_cv_header_sched_h=no
                                      ac_cv_lib_util_forkpty=no)
        else()
          # required for _scproxy module for macos
          list(APPEND Py_LINK_LIBRARIES "-framework SystemConfiguration"
                                        "-framework CoreFoundation")
        endif()
      endif()

      set(PYTHON_TARGETENV ${PROJECT_TARGETENV})
      if("webos" IN_LIST CORE_PLATFORM_NAME_LC)
        # Prepare buildenv - we need custom CFLAGS/LDFLAGS not in Toolchain.cmake
        set(PYTHON_TARGETENV "AS=${CMAKE_AS}"
                             "AR=${CMAKE_AR}"
                             "CC=${CMAKE_C_COMPILER}"
                             "CXX=${CMAKE_CXX_COMPILER}"
                             "NM=${CMAKE_NM}"
                             "LD=${CMAKE_LINKER}"
                             "STRIP=${CMAKE_STRIP}"
                             "RANLIB=${CMAKE_RANLIB}"
                             "OBJDUMP=${CMAKE_OBJDUMP}"
                             "CFLAGS=${CFLAGS}"
                             "CPPFLAGS=${CMAKE_CPP_FLAGS}"
                             # These are additional/changed compared to PROJECT_TARGETENV
                             "LDFLAGS=${LDFLAGS} -liconv"
                             "PKG_CONFIG_LIBDIR=${PKG_CONFIG_LIBDIR}"
                             "PKG_CONFIG_PATH="
                             "PKG_CONFIG_SYSROOT_DIR=${SDKROOT}"
                             "AUTOM4TE=${AUTOM4TE}"
                             "AUTOMAKE=${AUTOMAKE}"
                             "AUTOCONF=${AUTOCONF}"
                             "ACLOCAL=${ACLOCAL}"
                             "AUTOPOINT=${AUTOPOINT}"
                             "AUTOHEADER=${AUTOHEADER}"
                             "LIBTOOL=${LIBTOOL}"
                             "LIBTOOLIZE=${LIBTOOLIZE}"
                             )

        set(BYPASS_DEP_BUILDENV ON)
      endif()

      # Disabled c extension modules for all platforms
      set(PY_MODULES py_cv_module_audioop=n/a
                     py_cv_module_grp=n/a
                     py_cv_module_ossaudiodev=n/a
                     py_cv_module_spwd=n/a
                     py_cv_module_syslog=n/a
                     py_cv_module__crypt=n/a
                     py_cv_module_nis=n/a
                     py_cv_module__dbm=n/a
                     py_cv_module__gdbm=n/a
                     py_cv_module__uuid=n/a
                     py_cv_module_readline=n/a
                     py_cv_module__curses=n/a
                     py_cv_module__curses_panel=n/a
                     py_cv_module_xx=n/a
                     py_cv_module_xxlimited=n/a
                     py_cv_module_xxlimited_35=n/a
                     py_cv_module_xxsubtype=n/a
                     py_cv_module__xxsubinterpreters=n/a
                     py_cv_module__tkinter=n/a
                     py_cv_module__curses=n/a
                     py_cv_module__codecs_jp=n/a
                     py_cv_module__codecs_kr=n/a
                     py_cv_module__codecs_tw=n/a)

      # These modules use "internal" libs for building. The required static archives
      # are not installed outside of the cpython build tree, and cause failure in kodi linking
      # If we wish to support them in the future, we should create "system libs" for them
      list(APPEND PY_MODULES py_cv_module__decimal=n/a
                             py_cv_module__sha2=n/a)

      if(CORE_SYSTEM_NAME STREQUAL darwin_embedded)
        list(APPEND PY_MODULES py_cv_module__posixsubprocess=n/a
                               py_cv_module__scproxy=n/a)
      endif()

      set(CONFIGURE_COMMAND ${ACLOCAL_PATH_VAR} ${AUTORECONF} -vif
                    COMMAND ${CMAKE_COMMAND} -E env ${PYTHON_TARGETENV}
                            ./configure
                              --prefix=${DEPENDS_PATH}
                              --disable-shared
                              --without-ensurepip
                              --disable-framework
                              --without-pymalloc
                              --enable-ipv6
                              --with-build-python=${PYTHON_EXECUTABLE}
                              --with-system-expat=yes
                              --disable-test-modules
                              ${PY_MODULES}
                              MODULE_BUILDTYPE=static
                              ${EXTRA_CONFIGURE})

      set(BUILD_COMMAND ${CMAKE_COMMAND} -E env ${PYTHON_TARGETENV}
                        ${MAKE_EXECUTABLE} ${HOSTPLATFORM} libpython${Python3_VERSION_MAJOR}.${Python3_VERSION_MINOR}.a)

      set(INSTALL_COMMAND ${CMAKE_COMMAND} -E env ${PYTHON_TARGETENV}
                          ${MAKE_EXECUTABLE} ${HOSTPLATFORM} install -j1)
      set(BUILD_IN_SOURCE 1)
    endif()

    BUILD_DEP_TARGET()

    # Cleanup installed python data not required
    # Todo: windows?
    #       unix cleanup further data - config-3.12?
    if(NOT CORE_SYSTEM_NAME MATCHES windows)
      add_custom_command(TARGET ${MODULE_LC} POST_BUILD
                         COMMAND find ${DEPENDS_PATH}/lib/python${Python3_VERSION_MAJOR}.${Python3_VERSION_MINOR} -type f -name \"*.pyc\" -exec rm -f \{\} \\;)

      add_dependencies(python3 BZip2::BZip2
                              ${APP_NAME_LC}::Iconv
                              LibXml2::LibXml2
                              ${APP_NAME_LC}::OpenSSL
                              ${APP_NAME_LC}::Sqlite3)
    endif()

    set(Python3_INCLUDE_DIRS "${PYTHON3_INCLUDE_DIR}/python${Python3_VERSION_MAJOR}.${Python3_VERSION_MINOR}")
    # We must create the directory, otherwise we get non-existant path errors
    file(MAKE_DIRECTORY ${Python3_INCLUDE_DIRS})

  endmacro()

  include(cmake/scripts/common/ModuleHelpers.cmake)

  set(MODULE_LC python3)

  SETUP_BUILD_VARS()

  # for Depends/Windows builds, set search root dir to libdir path
  if(KODI_DEPENDSBUILD
     OR CMAKE_SYSTEM_NAME MATCHES Windows)
    set(Python3_USE_STATIC_LIBS TRUE)
    set(Python3_ROOT_DIR ${libdir})
  endif()

  # Provide root dir to search for Python is provided
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

  find_package(Python3 ${VERSION} ${EXACT_VER} COMPONENTS Development)

  if(Python3_FOUND)
    set(PY3_VER "${Python3_VERSION_MAJOR}.${Python3_VERSION_MINOR}.${Python3_VERSION_PATCH}")
  endif()

  if((PY3_VER VERSION_LESS ${${MODULE}_VER} AND ENABLE_INTERNAL_PYTHON) OR
     ((CORE_SYSTEM_NAME STREQUAL linux OR CORE_SYSTEM_NAME STREQUAL freebsd) AND ENABLE_INTERNAL_PYTHON))

    buildPython3()
  else()
    if(TARGET Python3::Python)
      # we only do this because we use find_package_handle_standard_args for config time output
      # and it isnt capable of handling TARGETS, so we have to extract the info
      get_target_property(_PYTHON_CONFIGURATIONS Python3::Python IMPORTED_CONFIGURATIONS)
      foreach(_python_config IN LISTS _PYTHON_CONFIGURATIONS)
        # Some non standard config (eg None on Debian)
        # Just set to RELEASE var so select_library_configurations can continue to work its magic
        string(TOUPPER ${_python_config} _python_config_UPPER)
        if((NOT ${_python_config_UPPER} STREQUAL "RELEASE") AND
           (NOT ${_python_config_UPPER} STREQUAL "DEBUG"))
          get_target_property(PYTHON3_LIBRARY_RELEASE Python3::Python IMPORTED_LOCATION_${_python_config_UPPER})
        else()
          get_target_property(PYTHON3_LIBRARY_${_python_config_UPPER} Python3::Python IMPORTED_LOCATION_${_python_config_UPPER})
        endif()
      endforeach()

      get_target_property(PYTHON3_INCLUDE_DIR Python3::Python INTERFACE_INCLUDE_DIRECTORIES)
      set(PYTHON3_VERSION ${Python3_VERSION})
    endif()
  endif()

  include(SelectLibraryConfigurations)
  select_library_configurations(PYTHON3)
  unset(PYTHON3_LIBRARIES)

  include(FindPackageHandleStandardArgs)
  find_package_handle_standard_args(Python
                                    REQUIRED_VARS PYTHON3_LIBRARY PYTHON3_INCLUDE_DIR
                                    VERSION_VAR PYTHON3_VERSION)

  if(Python_FOUND)
    # We use this all over the place. Maybe it would be nice to keep it as a TARGET property
    # but for now a cached variable will do
    set(PYTHON_VERSION "${Python3_VERSION_MAJOR}.${Python3_VERSION_MINOR}" CACHE INTERNAL "" FORCE)

    if(WIN32)
      set(PYTHON_SITE_PKG "${DEPENDS_PATH}/bin/python/Lib/site-packages" CACHE INTERNAL "" FORCE)
    else()
      # Todo
      # depends only - linux will need to use pkgconfig sitelib?
      set(PYTHON_SITE_PKG "${DEPENDS_PATH}/lib/python${Python3_VERSION_MAJOR}.${Python3_VERSION_MINOR}/site-packages" CACHE INTERNAL "" FORCE)
    endif()

    # cmake created target from find_package(Python3)
    if(TARGET Python3::Python AND NOT TARGET python3)
      add_library(${APP_NAME_LC}::${CMAKE_FIND_PACKAGE_NAME} ALIAS Python3::Python)
    else()
      add_library(${APP_NAME_LC}::${CMAKE_FIND_PACKAGE_NAME} UNKNOWN IMPORTED)
      set_target_properties(${APP_NAME_LC}::${CMAKE_FIND_PACKAGE_NAME} PROPERTIES
                                                                       INTERFACE_INCLUDE_DIRECTORIES "${Python3_INCLUDE_DIRS}"
                                                                       INTERFACE_LINK_OPTIONS "${Python3_LINK_OPTIONS}"
                                                                       INTERFACE_COMPILE_DEFINITIONS HAS_PYTHON)
  
      if(PYTHON3_LIBRARY_RELEASE)
        if(CORE_SYSTEM_NAME MATCHES windows)
          string(REGEX MATCH "^.*/lib/(.*)\.lib" Python3_DLL ${PYTHON3_LIBRARY_RELEASE})
          set(Python3_DLL "${DEPENDS_PATH}/bin/${CMAKE_MATCH_1}${CMAKE_SHARED_LIBRARY_SUFFIX}")

          set_target_properties(${APP_NAME_LC}::${CMAKE_FIND_PACKAGE_NAME} PROPERTIES
                                                                           IMPORTED_LOCATION_RELEASE "${Python3_DLL}"
                                                                           IMPORTED_IMPLIB_RELEASE "${PYTHON3_LIBRARY_RELEASE}")
        else()
          set_target_properties(${APP_NAME_LC}::${CMAKE_FIND_PACKAGE_NAME} PROPERTIES
                                                                           IMPORTED_LOCATION_RELEASE "${PYTHON3_LIBRARY_RELEASE}")
        endif()
        set_property(TARGET ${APP_NAME_LC}::${CMAKE_FIND_PACKAGE_NAME} APPEND PROPERTY
                                                                              IMPORTED_CONFIGURATIONS RELEASE)
      endif()
      if(PYTHON3_LIBRARY_DEBUG)
        if(CORE_SYSTEM_NAME MATCHES windows)
          string(REGEX MATCH "^.*/lib/(.*)\.lib" Python3_DLL ${PYTHON3_LIBRARY_DEBUG})
          set(Python3_DLL "${DEPENDS_PATH}/bin/${CMAKE_MATCH_1}${CMAKE_SHARED_LIBRARY_SUFFIX}")

          set_target_properties(${APP_NAME_LC}::${CMAKE_FIND_PACKAGE_NAME} PROPERTIES
                                                                           IMPORTED_LOCATION_DEBUG "${Python3_DLL}"
                                                                           IMPORTED_IMPLIB_DEBUG "${PYTHON3_LIBRARY_DEBUG}")
        else()
          set_target_properties(${APP_NAME_LC}::${CMAKE_FIND_PACKAGE_NAME} PROPERTIES
                                                                           IMPORTED_LOCATION_DEBUG "${PYTHON3_LIBRARY_DEBUG}")
        endif()
        set_property(TARGET ${APP_NAME_LC}::${CMAKE_FIND_PACKAGE_NAME} APPEND PROPERTY
                                                                              IMPORTED_CONFIGURATIONS DEBUG)
      endif()

      if(Py_LINK_LIBRARIES)
        set_target_properties(${APP_NAME_LC}::${CMAKE_FIND_PACKAGE_NAME} PROPERTIES
                                                                         INTERFACE_LINK_LIBRARIES "${Py_LINK_LIBRARIES}")
      endif()
    endif()

    if(TARGET python3)
      add_dependencies(${APP_NAME_LC}::${CMAKE_FIND_PACKAGE_NAME} python3)
    endif()

    # Add internal build target when a Multi Config Generator is used
    # We cant add a dependency based off a generator expression for targeted build types,
    # https://gitlab.kitware.com/cmake/cmake/-/issues/19467
    # therefore if the find heuristics only find the library, we add the internal build
    # target to the project to allow user to manually trigger for any build type they need
    # in case only a specific build type is actually available (eg Release found, Debug Required)
    # This is mainly targeted for windows who required different runtime libs for different
    # types, and they arent compatible
    if(_multiconfig_generator)
      if(NOT TARGET python3)
        buildPython3()
        set_target_properties(python3 PROPERTIES EXCLUDE_FROM_ALL TRUE)
      endif()
      add_dependencies(build_internal_depends python3)
    endif()
  else()
    if(Python_FIND_REQUIRED)
      message(FATAL_ERROR "Python3 libraries were not found. Try -DENABLE_INTERNAL_PYTHON to build python")
    endif()
  endif()
endif()
