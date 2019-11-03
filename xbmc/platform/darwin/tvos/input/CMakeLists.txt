set(SOURCES LibInputGameController.mm
            LibInputHandler.mm
            LibInputRemote.mm
            LibInputSettings.mm
            LibInputTouch.mm)

set(HEADERS LibInputGameController.h
            LibInputHandler.h
            LibInputRemote.h
            LibInputSettings.h
            LibInputTouch.h)

core_add_library(platform_tvos_input)
