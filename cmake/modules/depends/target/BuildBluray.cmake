include(ExternalProject)
include(cmake/scripts/common/ModuleHelpers.cmake)

set(MODULE_LC libbluray)

SETUP_BUILD_VARS()

find_package(Fontconfig REQUIRED)
find_package(FreeType REQUIRED)
find_package(LibXml2 REQUIRED)
find_package(Iconv REQUIRED)

set(BLURAY_LIBRARY ${DEPENDS_PATH}/lib/libass.a CACHE INTERNAL "" FORCE)
set(BLURAY_INCLUDE_DIR ${DEPENDS_PATH}/include CACHE INTERNAL "" FORCE)
set(BLURAY_VERSION ${${MODULE}_VERSION} CACHE INTERNAL "" FORCE)

if(CORE_SYSTEM_NAME STREQUAL darwin_embedded)
  set(CMD_PATCH PATCH_COMMAND patch -p1 -i ${CMAKE_SOURCE_DIR}/tools/depends/target/${MODULE_LC}/001-darwinembed_DiskArbitration-revert.patch)
  if(CORE_PLATFORM_NAME STREQUAL tvos)
    list(APPEND CMD_PATCH COMMAND patch -p1 -i ${CMAKE_SOURCE_DIR}/tools/depends/target/${MODULE_LC}/tvos.patch)
  endif()
endif()

# Set Target Configure command
set(CMD_CONFIGURE CONFIGURE_COMMAND set "PATH=${ENVPATH}"
                            COMMAND ${SETBUILDENV} ./bootstrap
                            COMMAND ${SETBUILDENV}
                                    ./configure
                                    --host=${HOST}
                                    --prefix=${DEPENDS_PATH}
                                    --disable-shared
                                    --exec-prefix=$(PREFIX)
                                    --disable-examples
                                    --disable-doxygen-doc
                                    --disable-bdjava-jar
                  )

# Set Target Build command
set(CMD_BUILD BUILD_COMMAND $(MAKE))

# Set Target Install command
set(CMD_INSTALL INSTALL_COMMAND $(MAKE) install)

# Set Target Byproduct
set(BYPRODUCT BUILD_BYPRODUCTS ${BLURAY_LIBRARY})

# Execute externalproject_add for dependency
TARGET_PROJECTADD()

set(BLURAY_FOUND TRUE)

#add_dependencies(${MODULE_LC} fontconfig freetype2 libxml2 ICONV::ICONV)
