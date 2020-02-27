# OSX packaging

set(PACKAGE_OUTPUT_DIR ${CMAKE_BINARY_DIR}/build/${CORE_BUILD_CONFIG})

configure_file(${CMAKE_SOURCE_DIR}/xbmc/platform/darwin/osx/Info.plist.in
               ${CMAKE_BINARY_DIR}/xbmc/platform/darwin/osx/Info.plist @ONLY)
#execute_process(COMMAND perl -p -i -e "s/r####/${APP_SCMID}/" ${CMAKE_BINARY_DIR}/xbmc/platform/darwin/osx/Info.plist)

# entitlements
set(ENTITLEMENTS_OUT_PATH "${CMAKE_BINARY_DIR}/CMakeFiles/${APP_NAME_LC}.dir/Kodi.entitlements")
configure_file(${CMAKE_SOURCE_DIR}/xbmc/platform/darwin/osx/Kodi.entitlements.in ${ENTITLEMENTS_OUT_PATH} @ONLY)

set_target_properties(${APP_NAME_LC} PROPERTIES XCODE_ATTRIBUTE_CODE_SIGN_ENTITLEMENTS ${ENTITLEMENTS_OUT_PATH}
                                                MACOSX_BUNDLE_INFO_PLIST ${CMAKE_SOURCE_DIR}/xbmc/platform/darwin/osx/Info.plist.in)

# setup code signing
# dev team ID / identity (certificate)
set(DEVELOPMENT_TEAM "" CACHE STRING "Development Team")
set(CODE_SIGN_IDENTITY $<IF:$<BOOL:${DEVELOPMENT_TEAM}>,iPhone\ Developer,> CACHE STRING "Code Sign Identity")

# app provisioning profile
set(CODE_SIGN_STYLE_APP Automatic)
set(PROVISIONING_PROFILE_APP "" CACHE STRING "Provisioning profile name for the Kodi app")
if(CODE_SIGN_IDENTITY)
  set(CODE_SIGN_STYLE_APP Manual)
endif()

set_target_properties(${APP_NAME_LC} PROPERTIES XCODE_ATTRIBUTE_CODE_SIGN_IDENTITY "${CODE_SIGN_IDENTITY}"
                                                XCODE_ATTRIBUTE_CODE_SIGN_STYLE ${CODE_SIGN_STYLE_APP}
                                                XCODE_ATTRIBUTE_DEVELOPMENT_TEAM "${DEVELOPMENT_TEAM}"
                                                XCODE_ATTRIBUTE_PROVISIONING_PROFILE_SPECIFIER "${PROVISIONING_PROFILE_APP}"
                                                XCODE_ATTRIBUTE_ENABLE_HARDENED_RUNTIME YES
                                                XCODE_ATTRIBUTE_OTHER_CODE_SIGN_FLAGS "--timestamp --options=runtime")

add_custom_target(bundle
    COMMAND ${CMAKE_COMMAND} -E copy $<TARGET_FILE:${APP_NAME_LC}> ${PACKAGE_OUTPUT_DIR}/${APP_NAME}
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

add_custom_target(dmg
    COMMAND ${CMAKE_COMMAND} -E copy_directory ${CMAKE_SOURCE_DIR}/tools/darwin/packaging/osx/
                                               ${CMAKE_BINARY_DIR}/tools/darwin/packaging/osx/
    COMMAND ${CMAKE_COMMAND} -E copy_directory ${CMAKE_SOURCE_DIR}/tools/darwin/packaging/media/osx/
                                               ${CMAKE_BINARY_DIR}/tools/darwin/packaging/media/osx/
    COMMAND "XBMC_DEPENDS=${DEPENDS_PATH}"
            "NATIVEPREFIX=${NATIVEPREFIX}"
            "CODESIGNING_FOLDER_PATH=${PACKAGE_OUTPUT_DIR}/${APP_NAME}.app"
            "EXPANDED_CODE_SIGN_IDENTITY_NAME=${CODE_SIGN_IDENTITY}"
            "ENTITLEMENTS=${ENTITLEMENTS_OUT_PATH}"
            "APP_NAME=${APP_NAME}"
            ${CMAKE_SOURCE_DIR}/tools/darwin/Support/Codesign-osx.command
    COMMAND "CODESIGNING_FOLDER_PATH=${PACKAGE_OUTPUT_DIR}/${APP_NAME}.app"
            "EXPANDED_CODE_SIGN_IDENTITY_NAME=${CODE_SIGN_IDENTITY}"
            ./mkdmg-osx.sh ${CORE_BUILD_CONFIG}
    COMMAND "DEV_ACCOUNT=${DEV_ACCOUNT}"
            "DEV_ACCOUNT_PASSWORD=${DEV_ACCOUNT_PASSWORD}"
            "DEV_TEAM=${DEV_TEAM}"
            "CODE_SIGN_IDENTITY=${CODE_SIGN_IDENTITY}"
            ./notarize.sh ${PACKAGE_OUTPUT_DIR}/${APP_NAME}.app/Contents/Info.plist
    WORKING_DIRECTORY ${CMAKE_BINARY_DIR}/tools/darwin/packaging/osx)
set_target_properties(dmg PROPERTIES XCODE_ATTRIBUTE_CODE_SIGN_ENTITLEMENTS ${ENTITLEMENTS_OUT_PATH}
                                     FOLDER "Build Utilities")
add_dependencies(dmg bundle)
