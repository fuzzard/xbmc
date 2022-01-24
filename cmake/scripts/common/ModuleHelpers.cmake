# This script provides helper functions for FindModules


set(PROJECT_TARGETENV "AS=${CMAKE_AS}"
                      "AR=${CMAKE_AR}"
                      "CC=${CMAKE_C_COMPILER}"
                      "CXX=${CMAKE_CXX_COMPILER}"
                      "NM=${CMAKE_NM}"
                      "LD=${CMAKE_LINKER}"
                      "STRIP=${CMAKE_STRIP}"
                      "RANLIB=${CMAKE_RANLIB}"
                      "OBJDUMP=${CMAKE_OBJDUMP}"
                      "CFLAGS=${CMAKE_C_FLAGS}"
                      "CPPFLAGS=${CMAKE_CPP_FLAGS}"
                      "LDFLAGS=${CMAKE_EXE_LINKER_FLAGS}"
                      "PKG_CONFIG_LIBDIR=${PKG_CONFIG_LIBDIR}"
                      "AUTOM4TE=${AUTOM4TE}"
                      "AUTOMAKE=${AUTOMAKE}"
                      "AUTOCONF=${AUTOCONF}"
                      "ACLOCAL=${ACLOCAL}"
                      "ACLOCAL_PATH=${ACLOCAL_PATH}"
                      "AUTOPOINT=${AUTOPOINT}"
                      "AUTOHEADER=${AUTOHEADER}"
                      "LIBTOOL=${LIBTOOL}"
                      "LIBTOOLIZE=${LIBTOOLIZE}"
                      )

set(SETBUILDENV ${CMAKE_COMMAND} -E env ${PROJECT_TARGETENV} ${PROJECT_BUILDENV})

set(PROJECT_BUILDENV CC_FOR_BUILD=${CC_FOR_BUILD}
                     CXX_FOR_BUILD=${CXX_FOR_BUILD}
                     LD_FOR_BUILD=${LD_FOR_BUILD}
                     CC_BINARY_FOR_BUILD=${CC_FOR_BUILD}
                     CXX_BINARY_FOR_BUILD=${CXX_FOR_BUILD}
                     AR_FOR_BUILD=${AR_FOR_BUILD}
                     RANLIB_FOR_BUILD=${RANLIB_FOR_BUILD}
                     AS_FOR_BUILD=${AS_FOR_BUILD}
                     NM_FOR_BUILD=${NM_FOR_BUILD}
                     STRIP_FOR_BUILD=${STRIP_FOR_BUILD}
                     READELF_FOR_BUILD=${READELF_FOR_BUILD}
                     OBJDUMP_FOR_BUILD=${OBJDUMP_FOR_BUILD}
                     CFLAGS_FOR_BUILD=${CFLAGS_FOR_BUILD}
                     LDFLAGS_FOR_BUILD=${LDFLAGS_FOR_BUILD}
                     )

# Parse and set variables from VERSION dependency file
# Arguments:
#   module_name name of the library (currently must match tools/depends/target/${module_name})
# On return:
#   ARCHIVE will be set to parent scope
#   MODULENAME_VER will be set to parent scope (eg FFMPEG_VER, DAV1D_VER)
#   MODULENAME_BASE_URL will be set to parent scope if exists in VERSION file (eg FFMPEG_BASE_URL)
function(get_archive_name module_name)
  string(TOUPPER ${module_name} UPPER_MODULE_NAME)

  # Dependency path
  set(MODULE_PATH "${CMAKE_SOURCE_DIR}/tools/depends/target/${module_name}")
  if(NOT EXISTS "${MODULE_PATH}/${UPPER_MODULE_NAME}-VERSION")
    MESSAGE(FATAL_ERROR "${UPPER_MODULE_NAME}-VERSION does not exist at ${MODULE_PATH}.")
  else()
    set(${UPPER_MODULE_NAME}_FILE "${MODULE_PATH}/${UPPER_MODULE_NAME}-VERSION")
  endif()

  # Tarball Hash
  file(STRINGS ${${UPPER_MODULE_NAME}_FILE} ${UPPER_MODULE_NAME}_HASH_SHA256 REGEX "^[ \t]*SHA256=")
  file(STRINGS ${${UPPER_MODULE_NAME}_FILE} ${UPPER_MODULE_NAME}_HASH_SHA256 REGEX "^[ \t]*SHA512=")

  file(STRINGS ${${UPPER_MODULE_NAME}_FILE} ${UPPER_MODULE_NAME}_LNAME REGEX "^[ \t]*LIBNAME=")
  file(STRINGS ${${UPPER_MODULE_NAME}_FILE} ${UPPER_MODULE_NAME}_VER REGEX "^[ \t]*VERSION=")
  file(STRINGS ${${UPPER_MODULE_NAME}_FILE} ${UPPER_MODULE_NAME}_ARCHIVE REGEX "^[ \t]*ARCHIVE=")
  file(STRINGS ${${UPPER_MODULE_NAME}_FILE} ${UPPER_MODULE_NAME}_BASE_URL REGEX "^[ \t]*BASE_URL=")

  string(REGEX REPLACE ".*LIBNAME=([^ \t]*).*" "\\1" ${UPPER_MODULE_NAME}_LNAME "${${UPPER_MODULE_NAME}_LNAME}")
  string(REGEX REPLACE ".*VERSION=([^ \t]*).*" "\\1" ${UPPER_MODULE_NAME}_VER "${${UPPER_MODULE_NAME}_VER}")
  string(REGEX REPLACE ".*ARCHIVE=([^ \t]*).*" "\\1" ${UPPER_MODULE_NAME}_ARCHIVE "${${UPPER_MODULE_NAME}_ARCHIVE}")
  string(REGEX REPLACE ".*BASE_URL=([^ \t]*).*" "\\1" ${UPPER_MODULE_NAME}_BASE_URL "${${UPPER_MODULE_NAME}_BASE_URL}")

  string(REGEX REPLACE "\\$\\(LIBNAME\\)" "${${UPPER_MODULE_NAME}_LNAME}" ${UPPER_MODULE_NAME}_ARCHIVE "${${UPPER_MODULE_NAME}_ARCHIVE}")
  string(REGEX REPLACE "\\$\\(VERSION\\)" "${${UPPER_MODULE_NAME}_VER}" ${UPPER_MODULE_NAME}_ARCHIVE "${${UPPER_MODULE_NAME}_ARCHIVE}")

  set(${UPPER_MODULE_NAME}_ARCHIVE ${${UPPER_MODULE_NAME}_ARCHIVE} PARENT_SCOPE)
  set(${UPPER_MODULE_NAME}_VER ${${UPPER_MODULE_NAME}_VER} PARENT_SCOPE)
  if (${UPPER_MODULE_NAME}_BASE_URL)
    set(${UPPER_MODULE_NAME}_BASE_URL ${${UPPER_MODULE_NAME}_BASE_URL} PARENT_SCOPE)
  else()
    set(${UPPER_MODULE_NAME}_BASE_URL "http://mirrors.kodi.tv/build-deps/sources" PARENT_SCOPE)
  endif()

  if (${UPPER_MODULE_NAME}_HASH_SHA256)
    set(${UPPER_MODULE_NAME}_HASH ${${UPPER_MODULE_NAME}_HASH_SHA256} PARENT_SCOPE)
  elseif(${UPPER_MODULE_NAME}_HASH_SHA512)
    set(${UPPER_MODULE_NAME}_HASH ${${UPPER_MODULE_NAME}_HASH_SHA512} PARENT_SCOPE)
  endif()
endfunction()

macro(SETUP_BUILD_VARS)
  get_archive_name(${MODULE_LC})
  string(TOUPPER ${MODULE_LC} MODULE)

  # allow user to override the download URL with a local tarball
  # needed for offline build envs
  if(${MODULE}_URL)
    get_filename_component(${MODULE}_URL "${${MODULE}_URL}" ABSOLUTE)
  else()
    set(${MODULE}_URL ${${MODULE}_BASE_URL}/${ARCHIVE})
  endif()
  if(VERBOSE)
    message(STATUS "${MODULE}_URL: ${${MODULE}_URL}")
  endif()
endmacro()

macro(TARGET_PROJECTADD)
externalproject_add(${MODULE_LC}
                    URL ${${MODULE}_URL}
                    URL_HASH ${${MODULE}_HASH}
                    DOWNLOAD_NAME ${${MODULE}_ARCHIVE}
                    DOWNLOAD_DIR ${TARBALL_DIR}
                    PREFIX ${CORE_BUILD_DIR}/${MODULE_LC}
                    ${CMD_PATCH}
                    ${CMD_CONFIGURE}
                    ${CMD_BUILD}
                    ${CMD_INSTALL}
                    ${BYPRODUCT}
                    BUILD_IN_SOURCE 1)
endmacro()
