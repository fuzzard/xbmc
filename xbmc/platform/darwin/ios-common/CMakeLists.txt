set(SOURCES AnnounceReceiver.mm
            DarwinNSUserDefaults.mm
            IOSKeyboard.mm
            IOSKeyboardView.mm)

set(HEADERS AnnounceReceiver.h
            DarwinNSUserDefaults.h
            IOSKeyboard.h
            IOSKeyboardView.h)

core_add_library(platform_ios-common)
