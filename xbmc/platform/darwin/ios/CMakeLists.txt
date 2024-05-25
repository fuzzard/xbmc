set(SOURCES IOSEAGLView.mm
            IOSExternalTouchController.mm
            IOSKeyboardView.mm
            IOSScreenManager.mm
            XBMCController.mm)

set(HEADERS IOSEAGLView.h
            IOSExternalTouchController.h
            IOSKeyboardView.h
            IOSScreenManager.h
            XBMCApplication.h
            XBMCController.h)

core_add_library(platform_ios)

if(TARGET platform_ios)
  set_target_properties(platform_ios PROPERTIES DISABLE_PRECOMPILE_HEADERS ON)
endif()
