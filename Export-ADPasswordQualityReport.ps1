<#
.SYNOPSIS
    Extracts data from an Active Directory Password Quality Report and exports it to CSV files.
.DESCRIPTION
    This script reads an Active Directory Password Quality Report file, extracts the data for each section,
    and exports each section's data to a separate CSV file.
.PARAMETER InputFilePath
    The path to the Active Directory Password Quality Report file.
.PARAMETER OutputDir
    The directory where the CSV files will be saved.
.EXAMPLE
    .\Export-ADPasswordQualityReport.ps1 -InputFilePath "C:\Reports\ADPasswordQualityReport.txt" -OutputDir "C:\Reports\CSV"
#>

param (
    [Parameter(Mandatory=$true)]
    [string]$InputFilePath,
    
    [Parameter(Mandatory=$true)]
    [string]$OutputDir
)

# Validate the input file exists
if (-not (Test-Path -Path $InputFilePath)) {
    Write-Error "Input file '$InputFilePath' not found."
    exit 1
}

# Ensure the output directory exists
if (-not (Test-Path -Path $OutputDir)) {
    try {
        New-Item -Path $OutputDir -ItemType Directory | Out-Null
        Write-Host "Created output directory: $OutputDir"
    } catch {
        Write-Error "Failed to create output directory '$OutputDir': $_"
        exit 1
    }
}

# Read the file content
try {
    $lines = Get-Content -Path $InputFilePath
    Write-Host "Successfully read input file: $InputFilePath"
} catch {
    Write-Error "Failed to read input file '$InputFilePath': $_"
    exit 1
}

# Initialize variables
$sections = @{}
$currentSection = ""
$currentGroup = ""

# Process each line
foreach ($line in $lines) {
    $trimmedLine = $line.Trim()
    
    # Skip empty lines
    if ([string]::IsNullOrWhiteSpace($trimmedLine)) {
        continue
    }
    
    # Skip the header lines
    if ($trimmedLine -eq "Active Directory Password Quality Report" -or $trimmedLine -match "^-+$") {
        continue
    }
    
    # Check if this line is a section heading
    if ($trimmedLine -match ":$") {
        if ($trimmedLine -match "^Group \d+:$" -and $currentSection -eq "These groups of accounts have the same passwords:") {
            # This is a group heading within the groups section
            $currentGroup = $trimmedLine -replace ":$", ""
        } else {
            # This is a main section heading
            $currentSection = $trimmedLine
            $currentGroup = ""
            if (-not $sections.ContainsKey($currentSection)) {
                $sections[$currentSection] = @()
            }
        }
    }
    # This is a data line
    elseif ($currentSection -ne "") {
        if ($currentSection -eq "These groups of accounts have the same passwords:" -and $currentGroup -ne "") {
            # Add the account with its group information
            $sections[$currentSection] += [PSCustomObject]@{
                Account = $trimmedLine
                Group = $currentGroup
            }
        } else {
            # Add the account without group information
            $sections[$currentSection] += [PSCustomObject]@{
                Account = $trimmedLine
            }
        }
    }
}

# Export each section's data to a separate CSV file
foreach ($section in $sections.Keys) {
    # Create a clean filename from the section heading
    $fileName = $section -replace ":", ""         # Remove the colon
    $fileName = $fileName -replace "[^\w\s]", ""  # Remove other non-word characters
    $fileName = $fileName.Trim() -replace "\s+", "_"  # Replace spaces with underscores
    
    # Create the output file path
    $outputFilePath = Join-Path -Path $OutputDir -ChildPath "$fileName.csv"
    
    # Export the data to a CSV file
    try {
        $sections[$section] | Export-Csv -Path $outputFilePath -NoTypeInformation -Encoding UTF8
        Write-Host "Exported data to: $outputFilePath"
    } catch {
        Write-Error "Failed to export data to '$outputFilePath': $_"
    }
}

Write-Host "Processing completed."
