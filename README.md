# Recreating Preware feeds on legacy webOS devices

## Feeds hosted on weboslives.eu

### Precentral Feed (Fixed)
A new Precentral feed for Preware. All the files are hosted on HTTP, so it works on any legacy webOS device. No ssl proxy required.

Here is the feed URL: http://weboslives.eu/feeds/precentral

Detailed steps to add it:

1. Launch Preware
2. Tap Manage Feeds
3. Unselect precentral (move the slider to off)
4. Go back
5. Let it update the Feeds
6. Tap Manage Feeds again
7. Scroll down to New Feed, enter a unique name (e.g., precentral-fixed) and the following URL: http://weboslives.eu/feeds/precentral
8. Read the warning message and if you are fine with the risks hit OK
9. Go back and let Preware update the Feeds again

The new feed is an almost exact replica of the original feed. None of the IPKs are modified, only the Packages + Packages.gz were updated with the new HTTP URLs.

### WOSA Feed
The App Museum II is also available as a Preware feed, so you can enjoy it on older devices as well.

How to add this feed?

1. Launch Preware
2. Tap Manage Feeds
3. Scroll down to New Feed, enter a unique name (e.g., wosa) and the following URL: http://weboslives.eu/feeds/wosa
4. Read the warning message and if you are fine with the risks hit Ok
5. Go back and let Preware update the Feeds

### palm-catalog feed
A resurrected palm-catalog feed for Preware. Similarly to the other feed, all the files are hosted on HTTP, so it works on any legacy webOS device. No ssl proxy required.

> Caveats:
> 
> - There are missing apps. The feed is linked to files recovered by @codepoet, but it is missing apps released after the demise of Palm and plenty of others.
> - Icons and screenshots are not included.


Here is the feed URL: http://weboslives.eu/feeds/palm-catalog

Detailed steps to add it:

1. Launch Preware
2. Tap Manage Feeds
3. Scroll down to New Feed, enter a unique name (e.g., palm-catalog) and the following URL: http://weboslives.eu/feeds/palm-catalog
4. Read the warning message and if you are fine with the risks hit Ok
5. Go back and let Preware update the Feeds

The new feed is an almost exact replica of the original feed. IPKs are the same as in the WebOS App Museum II, Packages + Packages.gz were updated with the new HTTP URLs.


## Bash script to create a webOS App Museum feed for Preware

This script converts the webOS App Museum JSONs to a Preware feed. 

> This should work fine on macOS. In order to make it work on Linux, you may need to update the following line:
>
> ```modified_date=`date -j -f "%Y-%m-%dT%H:%M:%S" "'lastModifiedTime_appjson'" +%s 2>/dev/null` ```
>to:
>	```modified_date=`date -d "'lastModifiedTime_appjson'" +%s 2>/dev/null` ```

All in all, this is a horrible script, the whole thing will need to be rewritten.
### Pre-requisites

 - Install jq, sed, awk, git, wget and grep
 - Obtain the necesary files
   - ```wget https://raw.githubusercontent.com/webOSArchive/webos-catalog-backend/main/archivedAppData.json```
   - ```git clone https://github.com/webOSArchive/webos-catalog-metadata.git```
 - Ensure that the webOS Catalog Metadata files are in the following directory: webos-catalog-metadata
 - Ensure that the archivedAppData.json is in the same directory as this script

### Usage:

1. Modify the Location and Source base URLs in the script in case if you want to use a different host (not the files hosted on weboslives.eu)
2. Generate the Packages file
   - ```bash convert.sh > Packages```
3. Create a compressed version of the Packages file
   - ```gzip -k Packages```
4. Host the files on an HTTP server (avoid modern TLS/SSL)
