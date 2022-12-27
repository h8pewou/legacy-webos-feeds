#!/bin/bash
#
# Script to generate a Preware feed from a directory of patches. 
#
# All in all, this is a horrible script, the whole thing will need to be rewritten.
#
# Pre-requisites:
#
#  - Install sed awk grep
#
# Usage:
#
#  - cd /path/to/patches
#  - bash convert_patches.sh > Packages
#  - gzip -k Packages
#

for patch in *.patch; do 
        publicApplicationId_appjson=$patch
        version_appjson=`grep ^Version $patch | sed 's/Version\:\ //g'`
        category="WOSA Patches"
        author=`grep ^Author $patch | sed 's/Author\:\ //g'`
        appSize_appjson=`du $patch | awk '{ print $1 }'`
        filename_appjson=$patch
        title=`grep ^Name $patch | sed 's/Name\:\ //g'`
	lastModifiedTime_appjson=`date '+%s' -d "@$( stat -c '%Y' "$patch"; )"`
	modified_date=$lastModifiedTime_appjson
        appIcon=''
        description_appjson=`grep ^Description $patch | sed 's/^Description\:\ //g'`
        screenshot_appjson=''
        locale_appjson='en'
        licenseURL_appjson=''
        devices=''
        echo "Package: $publicApplicationId_appjson"
        echo "Version: $version_appjson"
        echo "Section: $category"
        echo "Architecture: all"
        echo "Maintainer: $author"
        echo "Size: $appSize_appjson"
        echo "Filename: $filename_appjson"
        echo 'Source: {"Title":"'$title'","Location":"http://stacks.webosarchive.com/patches/2.2.4/'$filename_appjson'","Source":"http://stacks.webosarchive.com/patches/2.2.4/'$filename_appjson'","Type":"Patch","Feed":"WOSA Patches","LastUpdated":"'$modified_date'","Category":"'$category'","Homepage":"'$homeURL_appjson'","Icon":"http://appimages.webosarchive.com/'$appIcon'","FullDescription":"'$description_appjson'","Screenshots":['$screenshot_appjson'],"Countries":["'$locale_appjson'"],"Languages":["'$locale_appjson'"],"License":"'$licenseURL_appjson'","DeviceCompatibility":['$devices']}'
        echo "Description: $title"
        echo ""
done
