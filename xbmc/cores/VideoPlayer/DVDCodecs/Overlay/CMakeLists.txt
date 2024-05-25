set(SOURCES DVDOverlayCodec.cpp
            DVDOverlayCodecFFmpeg.cpp
            DVDOverlayCodecSSA.cpp
            DVDOverlayCodecText.cpp
            DVDOverlayCodecCCText.cpp
            DVDOverlayCodecTX3G.cpp
            OverlayCodecWebVTT.cpp
            contrib/cc_decoder.c
            contrib/cc_decoder708.cpp)

set(HEADERS DVDOverlay.h
            DVDOverlayCodec.h
            DVDOverlayCodecFFmpeg.h
            DVDOverlayCodecSSA.h
            DVDOverlayCodecTX3G.h
            DVDOverlayCodecText.h
            DVDOverlayCodecCCText.h
            DVDOverlayImage.h
            DVDOverlayLibass.h
            DVDOverlaySSA.h
            DVDOverlaySpu.h
            DVDOverlayText.h
            OverlayCodecWebVTT.h
            contrib/cc_decoder.h
            contrib/cc_decoder708.h)

set_source_files_properties(contrib/cc_decoder.c PROPERTIES SKIP_PRECOMPILE_HEADERS ON)
set_source_files_properties(contrib/cc_decoder708.c PROPERTIES SKIP_PRECOMPILE_HEADERS ON)
set_source_files_properties(contrib/cc_decoder.h PROPERTIES SKIP_PRECOMPILE_HEADERS ON)
set_source_files_properties(contrib/cc_decoder708.h PROPERTIES SKIP_PRECOMPILE_HEADERS ON)

core_add_library(dvdoverlaycodecs)
