set(SOURCES IOSStorageProvider.mm)

set(HEADERS IOSStorageProvider.h)

core_add_library(platform_ios_storage)

if(TARGET platform_ios_storage)
  set_target_properties(platform_ios_storage PROPERTIES DISABLE_PRECOMPILE_HEADERS ON)
endif()
