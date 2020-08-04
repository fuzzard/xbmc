set(SOURCES CocoaInterface.mm
            CPUInfoOsx.cpp
            OSXGLView.mm
            OSXGLWindow.mm
            OSXTextInputResponder.mm
            smc.c
            XBMCApplication.mm
            XBMCHelper.cpp)

set(HEADERS CocoaInterface.h
            CPUInfoOsx.h
            OSXGLView.h
            OSXGLWindow.h
            OSXTextInputResponder.h
            smc.h
            XBMCApplication.h
            XBMCHelper.h)

core_add_library(platform_osx)
