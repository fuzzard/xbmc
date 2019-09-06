set(SOURCES AnnounceReceiver.mm
            CPUInfoDarwinEmbed.cpp
            DarwinEmbedNowPlayingInfoManager.mm
            DarwinNSUserDefaults.mm
            IOSKeyboard.mm
            IOSKeyboardView.mm
            NSData+GZIP.m)

set(HEADERS AnnounceReceiver.h
            CPUInfoDarwinEmbed.h
            DarwinEmbedNowPlayingInfoManager.h
            DarwinNSUserDefaults.h
            IOSKeyboard.h
            IOSKeyboardView.h
            NSData+GZIP.h)

core_add_library(platform_ios-common)
