include(ExternalProject)
include(cmake/scripts/common/ModuleHelpers.cmake)

set(MODULE_LC crossguid)

SETUP_BUILD_VARS()

if(APPLE)
  set(EXTRA_ARGS "-DCMAKE_OSX_ARCHITECTURES=${CMAKE_OSX_ARCHITECTURES}")
endif()

set(CROSSGUID_LIBRARY ${CMAKE_BINARY_DIR}/${CORE_BUILD_DIR}/lib/libcrossguid.a CACHE INTERNAL "" FORCE)
set(CROSSGUID_INCLUDE_DIR ${CMAKE_BINARY_DIR}/${CORE_BUILD_DIR}/include CACHE INTERNAL "" FORCE)

externalproject_add(${MODULE_LC}
                    URL ${${MODULE}_URL}
                    URL_HASH ${${MODULE}_HASH}
                    DOWNLOAD_NAME ${${MODULE}_ARCHIVE}
                    DOWNLOAD_DIR ${TARBALL_DIR}
                    PREFIX ${CORE_BUILD_DIR}/${MODULE_LC}
                    CMAKE_ARGS -DCMAKE_INSTALL_PREFIX=${CMAKE_BINARY_DIR}/${CORE_BUILD_DIR}
                               -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TOOLCHAIN_FILE}
                               "${EXTRA_ARGS}"
                    PATCH_COMMAND ${CMAKE_COMMAND} -E copy
                                  ${CMAKE_SOURCE_DIR}/tools/depends/target/crossguid/CMakeLists.txt
                                  <SOURCE_DIR> &&
                                  ${CMAKE_COMMAND} -E copy
                                  ${CMAKE_SOURCE_DIR}/tools/depends/target/crossguid/FindUUID.cmake
                                  <SOURCE_DIR>
                    BUILD_BYPRODUCTS ${CROSSGUID_LIBRARY})
