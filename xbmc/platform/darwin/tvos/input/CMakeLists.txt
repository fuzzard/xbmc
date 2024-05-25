set(SOURCES LibInputHandler.mm
            LibInputRemote.mm
            LibInputSettings.mm
            LibInputTouch.mm)

set(HEADERS LibInputHandler.h
            LibInputRemote.h
            LibInputSettings.h
            LibInputTouch.h)

core_add_library(platform_tvos_input)

if(TARGET platform_tvos_input)
  set_target_properties(platform_tvos_input PROPERTIES DISABLE_PRECOMPILE_HEADERS ON)
endif()
