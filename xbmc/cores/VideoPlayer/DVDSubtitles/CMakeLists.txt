set(SOURCES DVDFactorySubtitle.cpp
            DVDSubtitleLineCollection.cpp
            DVDSubtitleParserMicroDVD.cpp
            DVDSubtitleParserMPL2.cpp
            DVDSubtitleParserSami.cpp
            DVDSubtitleParserSubrip.cpp
            DVDSubtitleParserVplayer.cpp
            DVDSubtitleParserWebVTT.cpp
            DVDSubtitleStream.cpp
            DVDSubtitlesLibass.cpp
            DVDSubtitleParserSSA.cpp
            DVDSubtitleTagMicroDVD.cpp
            DVDSubtitleTagSami.cpp
            DVDSubtitleTagWebVTT.cpp)

set(HEADERS DVDFactorySubtitle.h
            DVDSubtitleLineCollection.h
            DVDSubtitleParser.h
            DVDSubtitleParserMPL2.h
            DVDSubtitleParserMicroDVD.h
            DVDSubtitleParserSSA.h
            DVDSubtitleParserSami.h
            DVDSubtitleParserSubrip.h
            DVDSubtitleParserVplayer.h
            DVDSubtitleParserWebVTT.h
            DVDSubtitleStream.h
            DVDSubtitleTagMicroDVD.h
            DVDSubtitleTagSami.h
            DVDSubtitleTagWebVTT.h
            DVDSubtitlesLibass.h)

core_add_library(dvdsubtitles)
