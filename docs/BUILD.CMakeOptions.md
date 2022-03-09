![Kodi Logo](resources/banner_slim.png)

# Kodi CMake Build Options
This guide is to document the various Cmake build options available to a user to enable/disable

The available options are quite extensive for a number of areas of the build system. There are also
options that are platform specific

## Table of Contents
1. **[Document conventions](#1-document-conventions)**
2. **[General Build Options](#2-general-build-options)**
3. **[Enable Kodi Features](#3-enable-kodi-features)**
4. **[Build Dependencies](#4-build-dependencies)**  
  4.1. **[Unix General](#41-unix-general)**
5. **[Platform Specific Options](#3-platform-specific-options)**  
  5.1. **[Unix General](#51-unix-general)**  
  5.2. **[Linux](#52-linux)**  
    5.2.1. **[Linkers](#521-linkers)**  
    5.2.2. **[LTO](#522-lto)**  
  5.3. **[Apple](#53-apple)**  
  5.4. **[Windows](#54-windows)**  
  5.5. **[Android](#55-android)**
5. **[Dependencies](#4-Dependencies)**
6. **[Developer Utilities](#5-developer-utilities)**

## 1. Document conventions
This guide assumes you are using `terminal`, also known as `console`, `command-line` or simply `cli`. Commands need to be run at the terminal, one at a time and in the provided order.

Options are shown with the following style
```
-DENABLE_FEATURE=BOOL
```
BOOL is a placeholder for any of the following ON/OFF/YES/NO

```
-DWITH_PATH=/path/to/lib
```
Options with paths

```
-DOPTION='STRING'
-DOPTION=STRING
```
A String with spaces is to be enclosed in ''.

To use these, add the Options to your cmake command as described in your platforms build guide.
```
cmake ../kodi -DCMAKE_INSTALL_PREFIX=/usr/local -DCORE_PLATFORM_NAME=x11 -DAPP_RENDER_SYSTEM=gl -DENABLE_UPNP=ON -DENABLE_OPTICAL=OFF
```

Apple users, look for the usage of CMAKE_EXTRA_ARGUMENTS to add the options to cmakebuildsys
```
make -C tools/depends/target/cmakebuildsys CMAKE_EXTRA_ARGUMENTS="-DENABLE_UPNP=ON -DENABLE_OPTICAL=OFF"
```

## 2. General Build Options

```
-DVERBOSE=BOOL
```
Enable verbose Cmake output
Default: OFF

```
-DCMAKE_INSTALL_PREFIX=STRING
```
Installation location of the built program

```
-DCORE_PLATFORM_NAME=STRING
```
Core platform name is a subname for some platform specific targets

Linux: X11 WAYLAND GBM
Apple IOS/TVOS: tvos ios

```
CMAKE_TOOLCHAIN_FILE=STRING
```
Provide Toolchain file for cross compilation options for cmake

Apple Platforms will set this to the generated Toolchain file from tools/depends build.
Android will set this to the generated Toolchain file from tools/depends build.

```
-DCMAKE_BUILD_TYPE=STRING
```
Build type options. See https://cmake.org/cmake/help/latest/variable/CMAKE_BUILD_TYPE.html
Options: Debug/Release/RelWithDebInfo/MinSizeRel
Default: Release

```
-DBUILD_DIR=/path/to/builddir
```
Path to build the project in.


## 3. Enable Kodi Features

```
-DENABLE_UPNP=BOOL
```
This enables UPNP support in kodi.
Default: ON

```
-DENABLE_AIRTUNES=BOOL
```
Enable AirTunes support via shairplay library
Default: ON

```
-DENABLE_OPTICAL=BOOL
```
Enables Optical Drive support via libcdio
Default: ON

IOS and TVOS platforms force this off due to no ability to have optical drives attached currently

```
-DENABLE_PYTHON=BOOL
```
Enables Python Language Invoker for Addons using Python
Default: ON

```
-DENABLE_DVDCSS=BOOL
```
Enable dvd css decryption via libdvdcss
Default: ON

## 4. Build Dependencies

```
-DTARBALL_DIR=/path/to/tarballs
```
This allows you to set where tarballs (source/library archives) are downloaded and saved.
If a tarball exists already, the build system will use the already downloaded tarball instead of downloading again.
Source tarballs can be shared across different platforms (eg Apple Macos, Android)

Apple systems have a fallback of set if not provided
```
/Users/Shared/xbmc-depends/xbmc-tarballs
```

Windows will fallback to
```
${CMAKE_SOURCE_DIR}/project/BuildDependencies/downloads
```

All other platforms fallback to
```
${CMAKE_BINARY_DIR}/${CORE_BUILD_DIR}/download
```

```
-DENABLE_INTERNAL_KISSFFT=BOOL
```
Build KissFFT as part of the build. This wont use system installed versions
Default: ON

```
-DENABLE_INTERNAL_FFMPEG=BOOL
```
Build FFMPEG as part of the build. This wont use system installed versions
Default: OFF

### 4.1. Unix General

  option(FFMPEG_PATH        "Path to external ffmpeg?" "")
  option(ENABLE_INTERNAL_CROSSGUID "Enable internal crossguid?" ON)
  option(ENABLE_INTERNAL_RapidJSON "Enable internal rapidjson?" OFF)
  option(ENABLE_INTERNAL_FMT "Enable internal fmt?" OFF)
  option(ENABLE_INTERNAL_FSTRCMP "Enable internal fstrcmp?" OFF)
  option(ENABLE_INTERNAL_FLATBUFFERS "Enable internal flatbuffers?" OFF)
  option(ENABLE_INTERNAL_DAV1D "Enable internal dav1d?" OFF)
  option(ENABLE_INTERNAL_GTEST "Enable internal gtest?" OFF)
  option(ENABLE_INTERNAL_UDFREAD "Enable internal udfread?" OFF)
  option(ENABLE_INTERNAL_SPDLOG "Enable internal spdlog?" OFF)

## 5. Platform Specific Option

### 5.1. Unix General

  option(WITH_ARCH              "build with given arch" OFF)
  option(WITH_CPU               "build with given cpu" OFF)

### 5.2. Linux

APP_RENDER_SYSTEM
  option(ENABLE_EVENTCLIENTS    "Enable event clients support?" OFF)

### 5.2.1. Linkers

  option(ENABLE_GOLD    "Enable gnu gold linker?" ON)
  option(ENABLE_LLD     "Enable llvm lld linker?" OFF)
  option(ENABLE_MOLD    "Enable mold linker?" OFF)

### 5.2.2. LTO

USE_LTO
CLANG_LTO_CACHE


### 5.3. Apple

-DPROVISIONING_PROFILE_APP='string'
-DPROVISIONING_PROFILE_TOPSHELF='string'
-DENABLE_XCODE_ADDONBUILD=ON
-DADDONS_TO_BUILD='addonname'
-DDEVELOPMENT_TEAM='string'
-DCODE_SIGN_IDENTITY='string'
-DDEV_ACCOUNT='string'
-DDEV_ACCOUNT_PASSWORD=string
-DDEV_TEAM='string' 

### 5.4. Windows

### 5.5. Android

## 6. Developer Utilities

option(ENABLE_CLANGTIDY   "Enable clang-tidy support?" OFF)
option(ENABLE_CPPCHECK    "Enable cppcheck support?" OFF)
option(ENABLE_TESTING     "Enable testing support?" ON)
option(ENABLE_INCLUDEWHATYOUUSE "Enable include-what-you-use support?" OFF)

