set(SOURCES LibInputHandler.mm
            LibInputMPRemoteCommand.mm
            LibInputRemote.mm
            LibInputSettings.mm
            LibInputTouch.mm)

set(HEADERS LibInputHandler.h
            LibInputMPRemoteCommand.h
            LibInputRemote.h
            LibInputSettings.h
            LibInputTouch.h)

core_add_library(platform_tvos_input)
