# Use try-catch block to handle curl errors
try {
    # Invoke the web request to download main museum archive and convert the response from JSON
    $archivedAppData = (curl "https://raw.githubusercontent.com/webOSArchive/webos-catalog-backend/main/archivedAppData.json" | ConvertFrom-Json)
}
catch {
    # Write the error message to the console
    Write-Error $_.Exception.Message
    # Exit the script with a non-zero exit code
    exit 1
}

Write-Host "Generating Preware feed: "
$preware_feed = ($archivedAppData | ForEach-Object -ThrottleLimit 8 -Parallel {
    # Define the WOSA archive URLs and device variables
    $catalog_metadata_url = "http://weboslives.eu/feeds/wosa/webos-catalog-metadata"
    $museum_app_url = "http://museum.weboslives.eu/AppPackages/"
    $museum_img_url = "http://museum.weboslives.eu/AppImages/"
    $devices = "Pixi","Pre","Pre2","Pre3","Veer","TouchPad","LuneOS"
    # Define App ID variable as a string
    $archivedAppData_id = $_.id.ToString()
    # Construct the full URL to the app metadata json file
    $app_metadata_url = ($catalog_metadata_url + "/" + $archivedAppData_id + ".json")
    try {
        # Retrieve the app metadata from the catalog metadata url
        $app_metadata = (Invoke-WebRequest $app_metadata_url | Select-Object -ExpandProperty Content | ConvertFrom-Json)
    }
    catch {
        # Handle the error if metadata retrieval fails
        $error_message = "Failed to retrieve metadata for AppID: $archivedAppData_id. Error: $($_.Exception.Message)"
        Write-Error $error_message
        continue
    }
    
    # Use try-catch block to handle last modified date errors
    try {
        # Get the last modified time from the app metadata
        $lastmodified = ($app_metadata | Select-Object -ExpandProperty lastModifiedTime)
        # Check if the last modified time is empty or not a valid date
        if ([string]::IsNullOrEmpty($lastmodified) -or -not (Get-Date -Date $lastmodified -UFormat %s -ErrorAction SilentlyContinue)) {
            # Set a dummy date as the last modified time
            $lastmodified = "01/01/1970"
            # Write a warning message to the console
            Write-Progress -Activity "  Processing" -Status "The last modified time is empty or invalid. Setting a dummy date. AppID: $archivedAppData_id"
        }
        # Convert the last modified time to Unix timestamp
        $lastupdated = (Get-Date -Date $lastmodified -UFormat %s)
    }
    catch {
        # Write the error message to the console
        $error_message = ($_.Exception.Message + " AppID: " + $archivedAppData_id)
        Write-Error $error_message
    }
    # Construct the source location URL
    if ($app_metadata.filename -like "*//*") {
        if($app_metadata.filename -like "*.ipk"){
            $source_location = $app_metadata.filename
        } Else {
            $source_location = "NO_IPK"
        }
    } Else {
        $source_location = ($museum_app_url + $app_metadata.filename)
    }
    # Construct the icon URL
    $iconurl = ($museum_img_url + $_.appIcon)
    # Construct screenshot URLs
    $images = ($app_metadata | Select-Object -ExpandProperty images)
    $screenshots = ($images.PSObject.Properties.Value.screenshot | ForEach-Object{ $museum_img_url + $_ })
    # Construct device compatibility
    $archivedAppData_all = $_
    $devicecompatibility = ($devices | foreach-object {
        $device = $archivedAppData_all
        If($device.$_ -eq "True") { $_ }
    })
    # Define a function to remove special characters
    function Remove-SpecialChars {
        param (
          [string]$InputString
        )
        # Use regular expression to remove special characters
        $OutputString = $InputString -replace "'", "``" -replace '[^\w .,:/;`-]', ' '
        # Return the output string
        return $OutputString
    }
    # Remove special characters from the description
    $description = Remove-SpecialChars -InputString $app_metadata.description

    # Ensure Screenshots is always an array
    if ($screenshots -is [string]) {
        $ScreenshotsArray = @($screenshots.Replace("/","\/"))
    } elseif ($screenshots -is [array]) {
        $ScreenshotsArray = $screenshots | ForEach-Object { $_.Replace("/","\/") }
    } else {
        # If it's not a string or array, convert it to an array with one element
        $ScreenshotsArray = @($screenshots.ToString().Replace("/","\/"))
    }

    # Construct the source table
    $Source_Table = @{
        Title = $_.title
        Location = $source_location
        Source = $source_location
        Type = "Application"
        Feed = "WOSA"
        LastUpdated = $lastupdated
        Category = $_.category
        Homepage = $app_metadata.homeURL
        Icon = $iconurl.Replace("/","\/")
        FullDescription = $description
        Screenshots = $ScreenshotsArray
        Countries = @($app_metadata.locale)
        Languages = @($app_metadata.locale)
        License = $app_metadata.licenseURL
        DeviceCompatibility = $devicecompatibility
    }
    $Source = ($Source_Table | ConvertTo-Json -Compress)

    # Replace double backslashes with single backslashes
    $Source = $Source -replace '\\\\', '\\'

    # Output all information obtained above
    Write-Output ("Package: " + $archivedAppData_id + "`nVersion: " + $app_metadata.Version + "`nSection: " + $_.Category + "`nArchitecture: all" + "`nMaintainer: " + $_.Author + "`nSize: " + $app_metadata.appSize + "`nFilename: " + $app_metadata.originalFileName + "`nSource: " + $Source + "`nDescription: " + $_.title + "`n")
    # Display progress on screen
    Write-Progress -Activity "  Processing" -Status $_.title
})

# Write the Preware feed to the Packages file
$preware_feed | Out-File Packages

# Check if gzip exists as an executable
$gzip = Get-Command -Name gzip -ErrorAction SilentlyContinue

# If gzip exists, launch it
if ($gzip) {
    gzip -kf Packages
} else {
    Write-Warning "gzip not found, you may need to run gzip -k Packages manually"
}
