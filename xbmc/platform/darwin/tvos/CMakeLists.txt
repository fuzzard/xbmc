set(SOURCES PreflightHandler.mm
            TVOSDisplayManager.mm
            TVOSEAGLView.mm
            TVOSKeyboardView.mm
            TVOSNSUserDefaults.mm
            TVOSSettingsHandler.mm
            tvosShared.mm
            TVOSTopShelf.mm
            XBMCController.mm)

set(HEADERS PreflightHandler.h
            TVOSDisplayManager.h
            TVOSEAGLView.h
            TVOSKeyboardView.h
            TVOSNSUserDefaults.h
            TVOSSettingsHandler.h
            tvosShared.h
            TVOSTopShelf.h
            XBMCApplication.h
            XBMCController.h)

core_add_library(platform_tvos)

if(TARGET platform_tvos)
  set_target_properties(platform_tvos PROPERTIES DISABLE_PRECOMPILE_HEADERS ON)
endif()
