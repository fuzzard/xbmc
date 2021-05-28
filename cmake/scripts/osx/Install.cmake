# OSX packaging

set(PACKAGE_OUTPUT_DIR ${CMAKE_BINARY_DIR}/build/${CORE_BUILD_CONFIG})

set(PLATFORM_BUNDLE_INFO_PLIST ${CMAKE_SOURCE_DIR}/xbmc/platform/darwin/${CORE_PLATFORM_NAME_LC}/Info.plist.in)

# Create xcode target that allows to build binary-addons.
if(CMAKE_GENERATOR MATCHES "Xcode")
  if(ADDONS_TO_BUILD)
    set(_addons "ADDONS=${ADDONS_TO_BUILD}")
  endif()
  add_custom_target(binary-addons
    COMMAND $(MAKE) -C ${CMAKE_SOURCE_DIR}/tools/depends/target/binary-addons clean
    COMMAND $(MAKE) -C ${CMAKE_SOURCE_DIR}/tools/depends/target/binary-addons VERBOSE=1 V=99
          INSTALL_PREFIX="${CMAKE_BINARY_DIR}/addons" CROSS_COMPILING=yes ${_addons})
  if(ENABLE_XCODE_ADDONBUILD)
    add_dependencies(${APP_NAME_LC} binary-addons)
  endif()
  unset(_addons)
endif()

# Generate and install App bundle icon
add_custom_command(TARGET ${APP_NAME_LC} POST_BUILD
    COMMAND ${CMAKE_COMMAND} -E make_directory "${CMAKE_BINARY_DIR}/${CMAKE_CFG_INTDIR}/${APP_NAME}.app/Contents/Resources"
    COMMAND iconutil -c icns --output "${CMAKE_BINARY_DIR}/${CMAKE_CFG_INTDIR}/${APP_NAME}.app/Contents/Resources/kodi.icns" "${CMAKE_BINARY_DIR}/tools/darwin/packaging/media/osx/icon.iconset"
    COMMAND "XBMC_DEPENDS=${DEPENDS_PATH}"
            "TARGET_CONTENTS_DIR=${CMAKE_BINARY_DIR}/${CMAKE_CFG_INTDIR}/${APP_NAME}.app/Contents"
            "APP_NAME=${APP_NAME}"
            "PYTHON_VERSION=${PYTHON_VERSION}"
            ${CMAKE_SOURCE_DIR}/tools/darwin/Support/copylibraries-osx.command)

add_custom_target(bundle
    COMMAND ${CMAKE_COMMAND} -E make_directory "${PACKAGE_OUTPUT_DIR}/${APP_NAME}.app"
    COMMAND ${CMAKE_COMMAND} -E copy_directory ${CMAKE_BINARY_DIR}/${CMAKE_CFG_INTDIR}/${APP_NAME}.app ${PACKAGE_OUTPUT_DIR}/${APP_NAME}.app/
    COMMAND ${CMAKE_COMMAND} -E copy ${CMAKE_BINARY_DIR}/${CORE_BUILD_DIR}/DllPaths_generated.h
                                     ${CMAKE_BINARY_DIR}/xbmc/DllPaths_generated.h
    COMMAND "ACTION=build"
            "TARGET_BUILD_DIR=${PACKAGE_OUTPUT_DIR}"
            "TARGET_NAME=${APP_NAME}.app"
            "APP_NAME=${APP_NAME}"
            "SRCROOT=${CMAKE_BINARY_DIR}"
            ${CMAKE_SOURCE_DIR}/tools/darwin/Support/CopyRootFiles-osx.command
    COMMAND "XBMC_DEPENDS=${DEPENDS_PATH}"
            "TARGET_BUILD_DIR=${PACKAGE_OUTPUT_DIR}"
            "TARGET_NAME=${APP_NAME}.app"
            "APP_NAME=${APP_NAME}"
            "FULL_PRODUCT_NAME=${APP_NAME}.app"
            "SRCROOT=${CMAKE_BINARY_DIR}"
            "PYTHON_VERSION=${PYTHON_VERSION}"
            ${CMAKE_SOURCE_DIR}/tools/darwin/Support/copyframeworks-osx.command)
set_target_properties(bundle PROPERTIES FOLDER "Build Utilities")
add_dependencies(bundle ${APP_NAME_LC})

configure_file(${CMAKE_SOURCE_DIR}/tools/darwin/packaging/osx/mkdmg-osx.sh.in
               ${CMAKE_BINARY_DIR}/tools/darwin/packaging/osx/mkdmg-osx.sh @ONLY)

string(TOLOWER ${CORE_BUILD_CONFIG} CORE_BUILD_CONFIG_LOWERCASED)
if(${CORE_BUILD_CONFIG_LOWERCASED} STREQUAL "release")
  set(ALLOW_DEBUGGER "false")
else()
  set(ALLOW_DEBUGGER "true")
endif()
configure_file(${CMAKE_SOURCE_DIR}/tools/darwin/packaging/osx/Kodi.entitlements.in
               ${CMAKE_BINARY_DIR}/tools/darwin/packaging/osx/Kodi.entitlements @ONLY)

add_custom_target(dmg
    COMMAND ${CMAKE_COMMAND} -E copy_directory ${CMAKE_SOURCE_DIR}/tools/darwin/packaging/osx/
                                               ${CMAKE_BINARY_DIR}/tools/darwin/packaging/osx/
    COMMAND ${CMAKE_COMMAND} -E copy_directory ${CMAKE_SOURCE_DIR}/tools/darwin/packaging/media/osx/
                                               ${CMAKE_BINARY_DIR}/tools/darwin/packaging/media/osx/
    COMMAND ${CMAKE_COMMAND} -E copy ${CMAKE_SOURCE_DIR}/tools/darwin/Support/Codesign.command
                                     ${CMAKE_BINARY_DIR}/tools/darwin/packaging/osx/Codesign.command
    COMMAND "CODESIGNING_FOLDER_PATH=${PACKAGE_OUTPUT_DIR}/${APP_NAME}.app"
            "DEV_ACCOUNT=${DEV_ACCOUNT}"
            "DEV_ACCOUNT_PASSWORD=${DEV_ACCOUNT_PASSWORD}"
            "DEV_TEAM=${DEV_TEAM}"
            "EXPANDED_CODE_SIGN_IDENTITY_NAME=${CODE_SIGN_IDENTITY}"
            "PLATFORM_NAME=${PLATFORM}"
            "XCODE_BUILDTYPE=${CMAKE_CFG_INTDIR}"
            "APP=${PACKAGE_OUTPUT_DIR}/${APP_NAME}.app"
            ./mkdmg-osx.sh ${CORE_BUILD_CONFIG_LOWERCASED}
    WORKING_DIRECTORY ${CMAKE_BINARY_DIR}/tools/darwin/packaging/osx)
set_target_properties(dmg PROPERTIES FOLDER "Build Utilities")
add_dependencies(dmg bundle)
