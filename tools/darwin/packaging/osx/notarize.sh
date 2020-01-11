#!/usr/bin/env bash

# credits: https://scriptingosx.com/2019/09/notarize-a-command-line-tool/

if [ -z "$CODE_SIGN_IDENTITY" -o -z "$DEV_ACCOUNT" -o -z "$DEV_ACCOUNT_PASSWORD" ]; then
  exit 0
fi

notarizefile() { # $1: path to file to notarize, $2: identifier
  filepath=${1:?"need a filepath"}
  identifier=${2:?"need an identifier"}

  # upload file
  echo "## uploading $filepath for notarization"
  altoolOutput=$(xcrun altool \
    --notarize-app \
    --type osx \
    --file "$filepath" \
    --primary-bundle-id "$identifier" \
    --username "$DEV_ACCOUNT" \
    --password "$DEV_ACCOUNT_PASSWORD" \
    ${DEV_TEAM:+--asc-provider "$DEV_TEAM"} 2>&1)

  requestUUID=$(echo "$altoolOutput" | awk '/RequestUUID/ { print $NF; }')

  if [[ $requestUUID == "" ]]; then
    echo "Failed to upload:"
    echo "$altoolOutput"
    exit 1
  fi
  echo "requestUUID: $requestUUID, waiting..."

  # wait for status to be not "in progress" any more
  request_status="in progress"
  while [[ "$request_status" == "in progress" ]]; do
    sleep 60
    altoolOutput=$(xcrun altool \
      --notarization-info "$requestUUID" \
      --username "$DEV_ACCOUNT" \
      --password "$DEV_ACCOUNT_PASSWORD" 2>&1)
    request_status=$(echo "$altoolOutput" | awk -F ': ' '/Status:/ { print $2; }' )
  done

  # print status information
  echo "$altoolOutput"

  if [[ $request_status != "success" ]]; then
    echo "## could not notarize $filepath"
    exit 1
  fi

  echo -e "\nnotarization details:"
  LogFileURL=$(echo "$altoolOutput" | awk -F ': ' '/LogFileURL:/ { print $2; }')
  curl "$LogFileURL"
  echo
}

dmg="$(ls *.dmg)"
notarizefile "$dmg" $(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$1")
xcrun stapler staple "$dmg"
