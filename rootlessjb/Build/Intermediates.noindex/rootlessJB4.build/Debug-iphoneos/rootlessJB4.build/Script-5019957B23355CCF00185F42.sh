#!/bin/sh
# Type a script or drag a script file from your workspace to insert its path.

buildNumber=$(/usr/libexec/PlistBuddy -c "Print CFBundleVersion" "${INFOPLIST_FILE}");
buildNumber=$(($buildNumber + 1));
/usr/libexec/PlistBuddy -c "Set CFBundleVersion $buildNumber" "${INFOPLIST_FILE}";

sh $SRCROOT/../unSignIPA.sh

