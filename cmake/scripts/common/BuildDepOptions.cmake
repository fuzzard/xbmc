
# Dep Options available for all platforms
option(ENABLE_INTERNAL_FMT "Enable internal fmt?" OFF)
option(ENABLE_INTERNAL_SPDLOG "Enable internal spdlog?" OFF)
option(ENABLE_INTERNAL_LIBNFS "Enable internal libnfs?" OFF)

# prefer kissfft from xbmc/contrib but let use system one on unices
cmake_dependent_option(ENABLE_INTERNAL_KISSFFT "Enable internal kissfft?" ON "UNIX" ON)

# use ffmpeg from depends or system
option(ENABLE_INTERNAL_FFMPEG "Enable internal ffmpeg?" OFF)

if(UNIX)
  option(FFMPEG_PATH "Path to external ffmpeg?" "")
  option(ENABLE_INTERNAL_CROSSGUID "Enable internal crossguid?" ON)
  option(ENABLE_INTERNAL_DAV1D "Enable internal dav1d?" OFF)
  option(ENABLE_INTERNAL_FLATBUFFERS "Enable internal flatbuffers?" OFF)
  option(ENABLE_INTERNAL_FSTRCMP "Enable internal fstrcmp?" OFF)
  option(ENABLE_INTERNAL_GTEST "Enable internal gtest?" OFF)
  option(ENABLE_INTERNAL_LIBXML2 "Enable internal libxml2?" OFF)
  option(ENABLE_INTERNAL_MARIADBCLIENT "Enable internal mariadb-c-connector?" OFF)
  option(ENABLE_INTERNAL_PCRE "Enable internal pcre?" OFF)
  option(ENABLE_INTERNAL_RapidJSON "Enable internal rapidjson?" OFF)
  option(ENABLE_INTERNAL_TAGLIB "Enable internal taglib?" OFF)
  option(ENABLE_INTERNAL_UDFREAD "Enable internal udfread?" OFF)
endif()

# Convenience to enable all available internal deps for platform
option(ENABLE_INTERNAL_LIBS "Enable build of all available internal libs?" OFF)

if(ENABLE_INTERNAL_LIBS)

  set(ENABLE_INTERNAL_FMT ON)
  set(ENABLE_INTERNAL_LIBNFS ON)
  set(ENABLE_INTERNAL_SPDLOG ON)
  if(UNIX)
    # Following dependencies only build on UNIX platforms currently
    set(ENABLE_INTERNAL_CROSSGUID ON)
    set(ENABLE_INTERNAL_DAV1D ON)
    set(ENABLE_INTERNAL_FFMPEG ON)
    set(ENABLE_INTERNAL_FLATBUFFERS ON)
    set(ENABLE_INTERNAL_FSTRCMP ON)
    set(ENABLE_INTERNAL_GTEST ON)
    set(ENABLE_INTERNAL_LIBXML2 ON)
    set(ENABLE_INTERNAL_MARIADBCLIENT ON)
    set(ENABLE_INTERNAL_PCRE ON)
    set(ENABLE_INTERNAL_RapidJSON ON)
    set(ENABLE_INTERNAL_TAGLIB ON)
    set(ENABLE_INTERNAL_UDFREAD OFF)
  endif()
endif()