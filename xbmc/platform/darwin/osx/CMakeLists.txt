set(SOURCES CocoaInterface.mm
            CPUInfoOsx.cpp
            NSWindow+Fullscreen.m
            OSXTextInputResponder.mm
            smc.c
            XBMCHelper.cpp)

set(HEADERS CocoaInterface.h
            CPUInfoOsx.h
            NSWindow+Fullscreen.h
            OSXTextInputResponder.h
            smc.h
            XBMCHelper.h)

core_add_library(platform_osx)
