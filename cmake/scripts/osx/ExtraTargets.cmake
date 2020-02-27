# XBMCHelper
add_subdirectory(${CMAKE_SOURCE_DIR}/tools/EventClients/Clients/OSXRemote build/XBMCHelper)

set(CODE_SIGN_STYLE_EXTRATARGET Automatic)
if(CODE_SIGN_IDENTITY)
  set(CODE_SIGN_STYLE_EXTRATARGET Manual)
endif()

add_dependencies(${APP_NAME_LC} XBMCHelper)
set(ENTITLEMENTS_OUT_PATH "${CMAKE_BINARY_DIR}/CMakeFiles/${APP_NAME_LC}.dir/Kodi.entitlements")
set_target_properties(XBMCHelper PROPERTIES XCODE_ATTRIBUTE_CODE_SIGN_IDENTITY "${CODE_SIGN_IDENTITY}"
                                            XCODE_ATTRIBUTE_CODE_SIGN_STYLE ${CODE_SIGN_STYLE_EXTRATARGET}
                                            XCODE_ATTRIBUTE_DEVELOPMENT_TEAM "${DEVELOPMENT_TEAM}"
                                            XCODE_ATTRIBUTE_ENABLE_HARDENED_RUNTIME YES
                                            XCODE_ATTRIBUTE_OTHER_CODE_SIGN_FLAGS "--timestamp --options=runtime"
                                            XCODE_ATTRIBUTE_CODE_SIGN_ENTITLEMENTS "${ENTITLEMENTS_OUT_PATH}")
