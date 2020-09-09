set(SOURCES LibInputHandler.mm
            LibInputHandlerKeyboard.mm
            LibInputHandlerMouse.mm)

set(HEADERS LibInputHandler.h
            LibInputHandlerKeyboard.h
            LibInputHandlerMouse.h)

core_add_library(platform_osx_input)
