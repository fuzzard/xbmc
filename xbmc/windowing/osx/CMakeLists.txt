set(SOURCES CocoaDPMSSupport.cpp
            OSScreenSaverOSX.cpp
            WinSystemOSX.mm
            VideoSyncOsx.mm)
set(HEADERS CocoaDPMSSupport.h
            OSScreenSaverOSX.h
            WinSystemOSX.h
            VideoSyncOsx.h)

if(SDL_FOUND)
  list(APPEND SOURCES WinEventsSDL.cpp)
  list(APPEND HEADERS WinEventsSDL.h)
else()
  list(APPEND SOURCES WinEventsOSX.mm
                      WinEventsOSXImpl.mm)
  list(APPEND HEADERS WinEventsOSX.h
                      WinEventsOSXImpl.h)
endif()

if(OPENGL_FOUND)
  list(APPEND SOURCES WinSystemOSXGL.mm)
  list(APPEND HEADERS WinSystemOSXGL.h)
endif()

core_add_library(windowing_osx)
