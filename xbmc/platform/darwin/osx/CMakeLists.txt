set(SOURCES CocoaInterface.mm
            CPUInfoOsx.cpp
            OSXGLView.mm
            OSXGLWindow.mm
            OSXTextInputResponder.mm
            PlatformDarwinOSX.cpp
            smc.c
            XBMCApplication.mm
            XBMCHelper.cpp)

set(HEADERS CocoaInterface.h
            CPUInfoOsx.h
            OSXGLView.h
            OSXGLWindow.h
            OSXTextInputResponder.h
            PlatformDarwinOSX.h
            smc.h
            XBMCApplication.h
            XBMCHelper.h)

core_add_library(platform_osx)
