#!/bin/bash

#set -x

function check_dyloaded_depends
{
  b=$(find "$EXTERNAL_LIBS" -name $1 -print)
  if [ -f "$b" ]; then
    #echo "Processing $b"
    if [ ! -f  "$TARGET_FRAMEWORKS/$(basename $b)" ]; then
      echo "    Packaging $b"
      cp -f "$b" "$TARGET_FRAMEWORKS/"
      chmod u+w "$TARGET_FRAMEWORKS/$(basename $b)"
    fi
    for a in $(otool -LX "$b"  | grep "$EXTERNAL_LIBS" | awk ' { print $1 } ') ; do
      if [ -f "$a" ]; then
        if [ ! -f  "$TARGET_FRAMEWORKS/$(basename $a)" ]; then
          echo "    Packaging $a"
          cp -f "$a" "$TARGET_FRAMEWORKS/"
          chmod u+w "$TARGET_FRAMEWORKS/$(basename $a)"
          install_name_tool -change "$a" "$DYLIB_NAMEPATH/$(basename $a)" "$TARGET_FRAMEWORKS/$(basename $b)"
        fi
      fi
    done
  fi
}

function check_xbmc_dylib_depends
{
  REWIND="1"
  while [ $REWIND = "1" ]
  do
    let REWIND="0"
    for b in $(find "$1" -type f -name "$2" -print) ; do
      #echo "Processing $b"
      install_name_tool -id "$(basename $b)" "$b"
      for a in $(otool -LX "$b"  | grep "$EXTERNAL_LIBS" | awk ' { print $1 } ') ; do
        #echo "    Packaging $a"
        if [ ! -f  "$TARGET_FRAMEWORKS/$(basename $a)" ]; then
          echo "    Packaging $a"
          cp -f "$a" "$TARGET_FRAMEWORKS/"
          chmod u+w "$TARGET_FRAMEWORKS/$(basename $a)"
          let REWIND="1"
        fi
        install_name_tool -change "$a" "$DYLIB_NAMEPATH/$(basename $a)" "$b"
      done
    done
  done
}

EXTERNAL_LIBS=$XBMC_DEPENDS

TARGET_NAME=$FULL_PRODUCT_NAME
TARGET_CONTENTS=$TARGET_BUILD_DIR/$TARGET_NAME/Contents

TARGET_BINARY=$TARGET_CONTENTS/MacOS/$APP_NAME
TARGET_FRAMEWORKS=$TARGET_CONTENTS/Libraries
DYLIB_NAMEPATH=@executable_path/../Libraries
XBMC_HOME=$TARGET_CONTENTS/Resources/$APP_NAME

mkdir -p "$TARGET_CONTENTS/MacOS"
mkdir -p "$TARGET_CONTENTS/Resources"

echo "Checking $XBMC_HOME/system *.so for dylib dependencies"
check_xbmc_dylib_depends "$XBMC_HOME"/system "*.so"

echo "Checking $XBMC_HOME/addons *.so for dylib dependencies"
check_xbmc_dylib_depends "$XBMC_HOME"/addons "*.so"

echo "Checking $XBMC_HOME/addons *.pvr for dylib dependencies"
check_xbmc_dylib_depends "$XBMC_HOME"/addons "*.pvr"

echo "Checking $XBMC_HOME/addons *.xbs for dylib dependencies"
check_xbmc_dylib_depends "$XBMC_HOME"/addons "*.xbs"

echo "Checking xbmc/DllPaths_generated.h for dylib dependencies"
for a in $(grep .dylib "$SRCROOT"/xbmc/DllPaths_generated.h | awk '{print $3}' | sed s/\"//g) ; do
  check_dyloaded_depends $a
done
