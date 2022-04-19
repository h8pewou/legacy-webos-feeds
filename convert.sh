#!/bin/bash

#
# Script to convert the webOS App Museum JSONs to a Preware feed. 
# This should work fine on macOS. In order to make it work on Linux, you may need to update the following line.
#       modified_date=`date -j -f "%Y-%m-%dT%H:%M:%S" "'lastModifiedTime_appjson'" +%s 2>/dev/null`
#
#
# All in all, this is a horrible script, the whole thing will need to be rewritten.
#
# Pre-requisites:
#
#  - Install jq sed awk grep
#  - Obtain the following files:
#      wget https://raw.githubusercontent.com/codepoet80/webos-catalog-backend/main/archivedAppData.json
#      git clone https://github.com/codepoet80/webos-catalog-metadata.git
#  - Ensure that the webOS Catalog Metadata files are in the following directory: webos-catalog-metadata-main
#  - Ensure that the archivedAppData.json is in the same directory as this script
#
# Usage:
#
#  - bash convert.sh > Packages
#  - gzip -k Packages
#

for id in `jq '.[].id' archivedAppData.json`; do 
        publicApplicationId_appjson=`jq .publicApplicationId webos-catalog-metadata-main/$id.json | sed 's/\"//g'`
        version_appjson=`jq .version webos-catalog-metadata-main/$id.json | sed 's/\"//g'`
        category=`jq '.[] | select(.id=='$id') | .category' archivedAppData.json | sed 's/\"//g' | tail -1`
        author=`jq '.[] | select(.id=='$id') | .author' archivedAppData.json | sed 's/\"//g' | tail -1`
        appSize_appjson=`jq .appSize webos-catalog-metadata-main/$id.json | sed 's/\"//g'`
        filename_appjson=`jq .filename webos-catalog-metadata-main/$id.json | sed 's/\"//g'`
        title=`jq '.[] | select(.id=='$id') | .title' archivedAppData.json | sed 's/\"//g' | tail -1`
        homeURL_appjson=`jq .homeURL webos-catalog-metadata-main/$id.json | sed 's/\"//g'`
	lastModifiedTime_appjson=`jq .lastModifiedTime webos-catalog-metadata-main/$id.json | sed 's/\"//g'`
	modified_date=`date -j -f "%Y-%m-%dT%H:%M:%S" $lastModifiedTime_appjson +%s 2>/dev/null`
        appIcon=`jq '.[] | select(.id=='$id') | .appIcon' archivedAppData.json | sed 's/\"//g' | tail -1`
        description_appjson=`jq .description webos-catalog-metadata-main/$id.json | sed 's/\"//g' | head -1`
        screenshot_appjson=`jq .[] webos-catalog-metadata-main/$id.json | jq .[].screenshot 2>/dev/null | grep -v ^null | sed 's/^\"/\"http\:\/\/appimages.webosarchive.com\//g' | tr '\n' ',' | sed 's/,$//g'`
        locale_appjson=`jq .locale webos-catalog-metadata-main/$id.json | sed 's/\"//g'`
        licenseURL_appjson=`jq .licenseURL webos-catalog-metadata-main/$id.json | sed 's/\"//g'`
        devices=`jq '.[] | select(.id=='$id') | "\(.Pixi) \(.Pre) \(.Pre2) \(.Pre3) \(.Veer) \(.TouchPad)"' archivedAppData.json | sed 's/\"//g' | awk 'BEGIN {FS=IFS=OFS=" "} {if ($1=="true") {$1="\"Pixi\""} ; if ($2=="true") {$2="\"Pre\""} ;  if ($3=="true") {$3="\"Pre2\""} ; if ($4=="true") {$4="\"Pre3\""} ; if ($5=="true") {$5="\"Veer\""} ; if ($6=="true") {$6="\"TouchPad\""} ; print $0}' | sed 's/false\ //g' | sed 's/\ /,/g' | sed 's/,$//g'`
        echo "Package: $publicApplicationId_appjson"
        echo "Version: $version_appjson"
        echo "Section: $category"
        echo "Architecture: all"
        echo "Maintainer: $author"
        echo "Size: $appSize_appjson"
        echo "Filename: $filename_appjson"
        echo 'Source: {"Title":"'$title'","Location":"http://weboslives.eu/AppPackages/'$filename_appjson'","Source":"http://weboslives.eu/AppPackages/'$filename_appjson'","Type":"Application","Feed":"WOSA","LastUpdated":"'$modified_date'","Category":"'$category'","Homepage":"'$homeURL_appjson'","Icon":"http://appimages.webosarchive.com/'$appIcon'","FullDescription":"'$description'","Screenshots":['$screenshot_appjson'],"Countries":["'$locale_appjson'"],"Languages":["'$locale_appjson'"],"License":"'$licenseURL_appjson'","DeviceCompatibility":['$devices']}'
        echo "Description: $title"
        echo ""
done
