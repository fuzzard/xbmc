#!/bin/bash

set -x

codesign_func () {
  # $1 BUNDLEID
  # $2 target to be signed
  CODESIGNOPTIONS="-o runtime --timestamp --entitlements ${ENTITLEMENTS}"

  codesign ${CODESIGNOPTIONS} -s "${CODE_SIGN_IDENTITY_FOR_ITEMS}" -fvvv -i "$1" "$2"
}

find_files () {
  # $1 BUNDLEID
  # $2 findoutput to search
  if [ `echo $2 | wc -l` != 0 ]; then
    for singlefile in $2; do
      codesign_func "$1" "${singlefile}"
    done
  fi
}

#this is the list of binaries we have to sign for being able to run un-jailbroken
LIST_BINARY_EXTENSIONS="dylib so 0 vis pvr app egg"

# Jenkins Keychain Unlock
if [ -f "/Users/Shared/buildslave/keychain_unlock.sh" ]; then
  /Users/Shared/buildslave/keychain_unlock.sh
fi

CONTENTS_PATH="${CODESIGNING_FOLDER_PATH}/Contents"

# pull the CFBundleIdentifier out of the built xxx.app
BUNDLEID=`mdls -raw -name kMDItemCFBundleIdentifier "${CODESIGNING_FOLDER_PATH}"`
if [ "${BUNDLEID}" == "(null)" ] ; then
  BUNDLEID=`/usr/libexec/PlistBuddy -c 'Print CFBundleIdentifier' "${CONTENTS_PATH}/Info.plist"`
fi

echo "CFBundleIdentifier is ${BUNDLEID}"

# Prefer the expanded name, if available.
CODE_SIGN_IDENTITY_FOR_ITEMS="${EXPANDED_CODE_SIGN_IDENTITY_NAME}"
if [ "${CODE_SIGN_IDENTITY_FOR_ITEMS}" = "" ] ; then
  # Fall back to old behavior.
  CODE_SIGN_IDENTITY_FOR_ITEMS="${CODE_SIGN_IDENTITY}"
fi
echo "${CODE_SIGN_IDENTITY_FOR_ITEMS}"

# delete existing codesigning
if [ -d "${CONTENTS_PATH}/_CodeSignature" ]; then
  rm -r "${CONTENTS_PATH}/_CodeSignature"
fi

#if user has set a code_sign_identity different from iPhone Developer we do a real codesign (for deployment on non-jailbroken devices)
if ! [ -z "${CODE_SIGN_IDENTITY_FOR_ITEMS}" ]; then
  if echo ${CODE_SIGN_IDENTITY_FOR_ITEMS} | grep -cim1 -e "Apple Development" -e "Developer ID Application" &>/dev/null; then
    echo "Doing a full bundle sign using genuine identity ${CODE_SIGN_IDENTITY_FOR_ITEMS}"

    #sign and repackage python eggs
    EGGS=`find "${CONTENTS_PATH}" -name "*.egg" -type f`
    echo "Signing Eggs"
    for i in $EGGS; do
      echo $i
      mkdir del
      unzip -q $i -d del
      for binext in $LIST_BINARY_EXTENSIONS
      do
        # check if at least 1 file with the extension exists to sign, otherwise do nothing
        FINDOUTPUT=`find ./del/ -name "*.$binext" -type f`
        find_files "${BUNDLEID}" "$FINDOUTPUT"
      done
      rm $i
      cd del && zip -qr $i ./* &&  cd ..
      rm -r ./del/
    done

    # sign any targets with "binary" extensions as set by LIST_BINARY_EXTENSIONS
    for binext in $LIST_BINARY_EXTENSIONS
    do
      echo "Signing binary: $binext"
      # check if at least 1 file with the extension exists to sign, otherwise do nothing
      FINDOUTPUT=`find "${CONTENTS_PATH}" -name "*.$binext" -type f`
      find_files "${BUNDLEID}" "$FINDOUTPUT"
    done
    echo "In case your app crashes with SIG_SIGN check the variable LIST_BINARY_EXTENSIONS in tools/darwin/Support/Codesign.command"

    # sign frameworks - Not required currently
    for FRAMEWORK_PATH in `find "${CONTENTS_PATH}" -name "*.framework" -type d`
    do
      DYLIB_BASENAME=$(basename "${FRAMEWORK_PATH%.framework}")
      echo "Signing Framework: ${DYLIB_BASENAME}.framework"
      FRAMEWORKBUNDLEID="${BUNDLEID}.framework.${DYLIB_BASENAME}"
      codesign_func "${FRAMEWORKBUNDLEID}" "${FRAMEWORK_PATH}/${DYLIB_BASENAME}"
      codesign_func "${FRAMEWORKBUNDLEID}" "${FRAMEWORK_PATH}"
    done

    # signs ExtraTargets build items - currently preflight and XBMCHelper
    TOOLS=`find "${CONTENTS_PATH}/Resources/${APP_NAME}/tools" -type f -perm -a=x`
    find_files "${BUNDLEID}" "$TOOLS"

    # final sign main executable after everything else is signed
    APPBINARY=`find "${CONTENTS_PATH}/MacOS" -type f -perm -a=x`
    find_files "${BUNDLEID}" "$APPBINARY"

  fi
fi

