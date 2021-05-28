#!/bin/bash

EXTERNAL_LIBS=$XBMC_DEPENDS

TARGET_BINARY=$TARGET_CONTENTS_DIR/MacOS/$APP_NAME
TARGET_LIBRARIES=$TARGET_CONTENTS_DIR/Libraries
DYLIB_NAMEPATH=@executable_path/../Libraries

rm -rf "$TARGET_LIBRARIES"
mkdir -p "$TARGET_LIBRARIES"

# Copy all dylib dependencies and rename their locations to inside the App bundle as a Library
echo "Checking $TARGET_BINARY dylib dependencies"
for a in $(otool -LX "$TARGET_BINARY"  | grep "$EXTERNAL_LIBS" | awk ' { print $1 } ') ; do
	echo "    Packaging $a"
	cp -f "$a" "$TARGET_LIBRARIES/"
	chmod u+w "$TARGET_LIBRARIES/$(basename $a)"
	install_name_tool -change "$a" "$DYLIB_NAMEPATH/$(basename $a)" "$TARGET_BINARY"
done

echo "Package $EXTERNAL_LIBS/lib/python$PYTHON_VERSION"
mkdir -p "$TARGET_LIBRARIES/lib"
PYTHONSYNC="rsync -aq --exclude .DS_Store --exclude *.a --exclude *.o --exclude *.exe --exclude test --exclude tests"
${PYTHONSYNC} "$EXTERNAL_LIBS/lib/python$PYTHON_VERSION" "$TARGET_LIBRARIES/lib/"
rm -rf "$TARGET_LIBRARIES/lib/python$PYTHON_VERSION/config-$PYTHON_VERSION-darwin"

echo "Checking $TARGET_LIBRARIES for missing dylib dependencies"
REWIND="1"
while [ $REWIND = "1" ]
do
	let REWIND="0"
	for b in "$TARGET_LIBRARIES/"*dylib* ; do
		#echo "  Processing $b"
		for a in $(otool -LX "$b"  | grep "$EXTERNAL_LIBS" | awk ' { print $1 } ') ; do
			#echo "Processing $a"
			if [ ! -f  "$TARGET_LIBRARIES/$(basename $a)" ]; then
				echo "    Packaging $a"
				cp -f "$a" "$TARGET_LIBRARIES/"
				chmod u+w "$TARGET_LIBRARIES/$(basename $a)"
				let REWIND="1"
			fi
			install_name_tool -change "$a" "$DYLIB_NAMEPATH/$(basename $a)" "$TARGET_LIBRARIES/$(basename $b)"
		done
	done
done

