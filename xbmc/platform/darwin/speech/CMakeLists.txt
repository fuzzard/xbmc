set(SOURCES SpeechRecognitionDarwin.mm)

set(HEADERS SpeechRecognitionDarwin.h)

core_add_library(platform_darwin_speech)

if(TARGET platform_darwin_speech)
  set_target_properties(platform_darwin_speech PROPERTIES DISABLE_PRECOMPILE_HEADERS ON)
endif()
