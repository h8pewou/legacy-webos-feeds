# Read the Packages file and separate it using `r as a delimeter
$Packages = (Get-Content Packages -Delimiter "`r")

$preware_feed = ($Packages | foreach-Object -ThrottleLimit 8 -Parallel {
    # Broken URL checker
    function Test-BrokenUrl ($url) {
        # Use Invoke-WebRequest with -Method Head to send a HEAD request and get only the headers
        $response = Invoke-WebRequest -Uri $url -Method Head -SkipHttpErrorCheck
        if ($response.StatusCode -eq 404) {
            # Return true if 404
            return $true
        } else {
            # Return false for any other status code
            return $false
        }
        # Stop execution if any 500 code is received
        if ($response.StatusCode -match '^5') {
            Write-Error "Server internal issue while accessing $url"
            Pause
            exit 1
        }
    }

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

    $package = $_
    foreach ($line in $package -split "`n") {
        if ($line -match "^Source:") {
            $json = $line.Replace("Source: ", "")
            $source = ($json | ConvertFrom-Json)
            # Remove special characters from the description
            $source.FullDescription = Remove-SpecialChars -InputString $source.FullDescription
            # Check if the file is available, update the title if not
            if($source.Location -like "*//*") {
                $urlbroken = Test-BrokenUrl $source.Location
            } Else {
                $urlbroken = $true
            }
            if ($urlbroken) { $source.Title = $source.Title + " - Missing IPK"}
            $newjson = ($source | ConvertTo-Json -Compress)
            Write-Output "Source: $newjson"
        } else {
            $line
        }
    }
    Write-Progress -Activity "  Processing:" -Status $source.Title
})

# Get the current date and time in ISO format
$now = Get-Date -Format "yyyy-MM-ddTHHmmss"

# Create a backup file name with the date and time
$backup = "Packages.bak-$now"

# Copy the original file to the backup file
Copy-Item "Packages" $backup

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

Write-Host "Missing IPKs:"
$missing = ($preware_feed | Select-String "Missing IPK")
foreach($line in $missing){
    $json = $line -replace ".*Source: "
    $json = $json.Trim()
    $source = ($json | convertfrom-json)
    Write-Host $source.Title + $source.Location
}