#!/bin/bash

# update_version_numbers.sh
# @desc Auto-increment the build number every time code is committed.
# @usage
# 1. Select: your Target in Xcode
# 2. Select: Build Phases Tab
# 3. Select: Add Build Phase -> Add Run Script
# 4. Paste code: `$SRCROOT/Scripts/update_version_numbers.sh`
# 5. Drag the "Run Script" below "Link Binaries With Libraries"
# 6. Insure that your starting build number is set to a whole integer and not a float (e.g. 1, not 1.0)
 
# Current branch
branch=$(git rev-parse --abbrev-ref HEAD)
# Current tag
tag=$(git describe --tags $(git rev-list master --tags --max-count=1))

# Check if in release branch within Git flow
if [[ $branch =~ ^release\/([0-9]+)\.([0-9]+)(\.([0-9]+))? ]]; then 
  tagMajorNumber="${BASH_REMATCH[1]}"
  tagMinorNumber="${BASH_REMATCH[2]}"
  tagPatchNumber="${BASH_REMATCH[4]}"
  [[ -z "$tagPatchNumber" ]] && VersionString="${tagMajorNumber}.${tagMinorNumber}" || VersionString="${tagMajorNumber}.${tagMinorNumber}.${tagPatchNumber}"
  echo "You are currently on a release branch. Version: ${VersionString}"

# Check if in hotfix branch within Git flow
elif [[ $branch =~ ^hotfix\/([0-9]+)\.([0-9]+)(\.([0-9]+))? ]]; then
  tagMajorNumber="${BASH_REMATCH[1]}"
  tagMinorNumber="${BASH_REMATCH[2]}"
  tagPatchNumber="${BASH_REMATCH[4]}"
  [[ -z "$tagPatchNumber" ]] && VersionString="${tagMajorNumber}.${tagMinorNumber}" || VersionString="${tagMajorNumber}.${tagMinorNumber}.${tagPatchNumber}"
  echo "You are currently on an hotfix branch. Version: ${VersionString}"

# Check if in feature branch within Git flow
elif [[ $branch =~ ^feature ]] && [[ $tag =~ ^([0-9]+)\.([0-9]+)(\.([0-9]+))? ]]; then
  tagMajorNumber="${BASH_REMATCH[1]}"
  tagMinorNumber="${BASH_REMATCH[2]}"
  tagPatchNumber="${BASH_REMATCH[4]}"
  [[ -z "$tagPatchNumber" ]] && VersionString="${tagMajorNumber}.${tagMinorNumber}" || VersionString="${tagMajorNumber}.${tagMinorNumber}.${tagPatchNumber}+"
  echo "You are currently on an feature branch. Version: ${VersionString}"

# We are most likely on developer branch. Use tag name as version.
elif [[ $branch =~ ^develop$ ]] && [[ $tag =~ ^([0-9]+)\.([0-9]+)(\.([0-9]+))? ]]; then
  tagMajorNumber="${BASH_REMATCH[1]}"
  tagMinorNumber="${BASH_REMATCH[2]}"
  tagPatchNumber="${BASH_REMATCH[4]}"
  [[ -z "$tagPatchNumber" ]] && VersionString="${tagMajorNumber}.${tagMinorNumber}" || VersionString="${tagMajorNumber}.${tagMinorNumber}.${tagPatchNumber}+"
  echo "You are on a developer branch. Version (from last tag name): ${VersionString}"

# We are most likely on master branch. Use tag name as version.
elif [[ $branch =~ ^master$ ]] && [[ $tag =~ ^([0-9]+)\.([0-9]+)(\.([0-9]+))? ]]; then
  tagMajorNumber="${BASH_REMATCH[1]}"
  tagMinorNumber="${BASH_REMATCH[2]}"
  tagPatchNumber="${BASH_REMATCH[4]}"
  [[ -z "$tagPatchNumber" ]] && VersionString="${tagMajorNumber}.${tagMinorNumber}" || VersionString="${tagMajorNumber}.${tagMinorNumber}.${tagPatchNumber}"
  echo "You are on a master branch. Version (from last tag name): ${VersionString}"

else
  echo "Version cannot be extracted from git. Neither tag name (${tag}) nor branch (${branch}) provides the respective version information. Are you using Git-flow or the proper semantic versioning? Make also sure that you are on a developer branch, if not on release or hotfix branch." 1>&2
  exit 4
fi

# Current build number
buildNumber=$(expr $(git rev-list develop --count) - $(git rev-list HEAD..develop --count))
#buildNumber=$(git log -n 1 --pretty=format:"%h")
#buildNumber=$(git describe --tags --always --dirty)

# Update Info.plist
echo "Updating marketing version number '${VersionString}' to ${PROJECT_DIR}/${INFOPLIST_FILE}."
#xcrun agvtool new-marketing-version "${VersionString}"
/usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $VersionString" "${PROJECT_DIR}/${INFOPLIST_FILE}"
echo "Updating build number '${buildNumber}' to ${TARGET_BUILD_DIR}/${INFOPLIST_PATH}."
/usr/libexec/PlistBuddy -c "Set :CFBundleVersion $buildNumber" "${TARGET_BUILD_DIR}/${INFOPLIST_PATH}"
if [ -f "${BUILT_PRODUCTS_DIR}/${WRAPPER_NAME}.dSYM/Contents/Info.plist" ]; then
  echo "Will execute: Set :CFBundleVersion $buildNumber" "${BUILT_PRODUCTS_DIR}/${WRAPPER_NAME}.dSYM/Contents/Info.plist"
  echo "Updating build number '${buildNumber}' to ${BUILT_PRODUCTS_DIR}/${WRAPPER_NAME}.dSYM/Contents/Info.plist"
  /usr/libexec/PlistBuddy -c "Set :CFBundleVersion $buildNumber" "${BUILT_PRODUCTS_DIR}/${WRAPPER_NAME}.dSYM/Contents/Info.plist"
fi

# Update podspec
set +e
podspec-bump --write "${VersionString}" > /dev/null 2>&1 || echo "Podspec update skipped - file not found."
set -e
