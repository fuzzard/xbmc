set(SOURCES CocoaDPMSSupport.cpp
            OSScreenSaverOSX.cpp
            OSXGLView.mm
            OSXGLWindow.mm
            OSXScreenManager.mm
            WinEventsOSX.mm
            WinSystemOSX.mm
            WinSystemOSXGL.mm
            VideoSyncOsx.mm)
set(HEADERS CocoaDPMSSupport.h
            OSScreenSaverOSX.h
            OSXGLView.h
            OSXGLWindow.h
            OSXScreenManager.h
            WinEventsOSX.h
            WinSystemOSX.h
            WinSystemOSXGL.h
            VideoSyncOsx.h)

core_add_library(windowing_osx)
