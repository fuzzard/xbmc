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

---

```
-DCMAKE_INSTALL_PREFIX=STRING
```
Installation location of the built program

---

```
-DCORE_PLATFORM_NAME=STRING
```
Core platform name is a subname for some platform specific targets

Linux: X11 WAYLAND GBM  
Apple IOS/TVOS: tvos ios

---

```
CMAKE_TOOLCHAIN_FILE=STRING
```
Provide Toolchain file for cross compilation options for cmake

Apple Platforms will set this to the generated Toolchain file from tools/depends build.  
Android will set this to the generated Toolchain file from tools/depends build.

---

```
-DCMAKE_BUILD_TYPE=STRING
```
Build type options. See [CMAKE_BUILD_TYPE](https://cmake.org/cmake/help/latest/variable/CMAKE_BUILD_TYPE.html)  
Options: Debug/Release/RelWithDebInfo/MinSizeRel  
Default: Release

---

```
-DBUILD_DIR=/path/to/builddir
```
Path to build the project in.

---

## 3. Enable Kodi Features

```
-DENABLE_UPNP=BOOL
```
This enables UPNP support in kodi.  
Default: ON

---

```
-DENABLE_AIRTUNES=BOOL
```
Enable AirTunes support via shairplay library  
Default: ON

---

```
-DENABLE_OPTICAL=BOOL
```
Enables Optical Drive support via libcdio  
Default: ON

IOS and TVOS platforms force this off due to no ability to have optical drives attached currently

---

```
-DENABLE_PYTHON=BOOL
```
Enables Python Language Invoker for Addons using Python  
Default: ON

---

```
-DENABLE_DVDCSS=BOOL
```
Enable dvd css decryption via libdvdcss  
Default: ON

---

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
---

```
-DENABLE_INTERNAL_KISSFFT=BOOL
```
Build KissFFT as part of the build. This wont use system installed versions  
Default: ON

---

```
-DENABLE_INTERNAL_FFMPEG=BOOL
```
Build FFMPEG as part of the build. This wont use system installed versions  
Default: OFF

---

### 4.1. Unix General

```
-DFFMPEG_PATH=/path/to/ffmpeglibs
```
Path to external ffmpeg. Using this flag will do a version check for minimum version requirements

```
-DWITH_FFMPEG=/path/to/ffmpeglibs
```
Path to external ffmpeg. This flag will NOT check for any minimum version requirements

---

```
-DENABLE_INTERNAL_CROSSGUID=BOOL
```
Enable building internal crossguid library  
Default: ON

---

```
-DENABLE_INTERNAL_DAV1D=BOOL
```
Enable building internal dav1d library  
Default: OFF

---

```
-DENABLE_INTERNAL_FMT=BOOL
```
Enable building internal fmt library  
Default: OFF

---

```
-DENABLE_INTERNAL_FSTRCMP=BOOL
```
Enable building internal fstrcmp library  
Default: OFF

---

```
-DENABLE_INTERNAL_FLATBUFFERS=BOOL
```
Enable building internal flatbuffers library and executable  
Default: OFF

---

```
-DENABLE_INTERNAL_GTEST=BOOL
```
Enable building internal googletest library  
Default: OFF

---

```
-DENABLE_INTERNAL_RapidJSON=BOOL
```
Enable building internal rapidjson library  
Default: OFF

---

```
-DENABLE_INTERNAL_SPDLOG=BOOL
```
Enable building internal spdlog library  
Default: OFF

---

```
-DENABLE_INTERNAL_UDFREAD=BOOL
```
Enable building internal udfread library  
Default: OFF

---

## 5. Platform Specific Option

### 5.1. Unix General

  option(WITH_ARCH              "build with given arch" OFF)
  option(WITH_CPU               "build with given cpu" OFF)

### 5.2. Linux

```
-DAPP_RENDER_SYSTEM=STRING
```
Set renderer type for linux platforms  
Options: GL GLES

---

```
-DENABLE_EVENTCLIENTS=BOOL
```

Enable event clients support  
Default: OFF

---

### 5.2.1. Linkers

```
-DENABLE_GOLD=BOOL
```

Enable gnu gold linker  
Default: ON

---

```
-DENABLE_LLD=BOOL
```

Enable llvm lld linker  
Default: OFF

---

```
-DENABLE_MOLD=BOOL
```

Enable mold linker  
Default: OFF

---

### 5.2.2. LTO

```
-DUSE_LTO=BOOL
```
Enable LTO  
Default: OFF

---

```
-DCLANG_LTO_CACHE=/path/to/lto.cache
```
Provide path for CLANG LTO Cache  
Requires to be using clang compiler tools


---

### 5.3. Apple

```
-DPROVISIONING_PROFILE_APP=STRING
```

---

```
-DPROVISIONING_PROFILE_TOPSHELF=STRING
```

---

```
-DENABLE_XCODE_ADDONBUILD=BOOL
```

---

```
-DADDONS_TO_BUILD=STRING
```

---

```
-DDEVELOPMENT_TEAM=STRING
```

---

```
-DCODE_SIGN_IDENTITY=STRING
```

---

```
-DDEV_ACCOUNT=STRING
```

---

```
-DDEV_ACCOUNT_PASSWORD=STRING
```

---

```
-DDEV_TEAM=STRING
```

---

### 5.4. Windows

### 5.5. Android

## 6. Developer Utilities

```
-DENABLE_CLANGTIDY=BOOL
```
Enable [clang-tidy](https://clang.llvm.org/extra/clang-tidy/) support  
Default: OFF

---

```
-DENABLE_CPPCHECK=BOOL
```
Enable [cppcheck](https://cppcheck.sourceforge.io/) support  
Default: OFF

---

```
-DENABLE_TESTING
```
Enable testing support. This has a requirement that the Host cpu/arch is the same as the Target cpu/arch  
Default: ON

---

```
-DENABLE_INCLUDEWHATYOUUSE
```
Enable [include-what-you-use](https://include-what-you-use.org/) support  
Default: OFF

