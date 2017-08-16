set(SOURCES CocoaInterface.mm
            OSXTextInputResponder.mm
            smc.c
            XBMCHelper.cpp)

set(HEADERS CocoaInterface.h
            OSXTextInputResponder.h
            smc.h
            XBMCHelper.h)

core_add_library(platform_osx)
