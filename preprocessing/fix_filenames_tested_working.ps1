param (
    [string]$root_dir
)

if (-not $root_dir) {
    Write-Host "Usage: .\fix_filenames.ps1 <root_directory>"
    exit 1
}

# Print a start message
Write-Host "Starting to fix filenames in directory: $root_dir"

# Get all files recursively from the root directory, including hidden files
Get-ChildItem -Path $root_dir -File -Recurse -Force | ForEach-Object {
    $file = $_
    $dir = $file.DirectoryName
    $filename = $file.Name

    # Print current filename
    Write-Host "Processing file: $filename"

    # Check if the filename matches the BraTS-GLI pattern (including files starting with ._)
    if ($filename -match '^(\.?_?)BraTS-GLI-(\d{5})-(\d{3})_(mask|seg|t2)\.nii\.gz$') {
        $prefix = $matches[1]
        $number = $matches[2]
        $suffix = $matches[3]
        $type = $matches[4]
        $new_filename = "${prefix}BraTS2021_${number}_${type}.nii.gz"

        # Rename the file
        $new_path = Join-Path -Path $dir -ChildPath $new_filename
        try {
            Rename-Item -Path $file.FullName -NewName $new_path
            Write-Host "Renamed: $filename -> $new_filename"
        } catch {
            Write-Host "Failed to rename: $filename. $_"
        }
    }
    # Check if the filename contains '.nii.gz' and is followed by another '.nii.gz' (or more)
    elseif ($filename -match '\.nii\.gz') {
        # Remove the first instance of '.nii.gz' from the filename
        $new_filename = $filename -replace '\.nii\.gz', ''

        # Ensure the correct format is preserved
        if ($new_filename -match '\.(mask|seg|t2)$') {
            $new_filename = $new_filename -replace '\.', '_'
            $new_filename += '.nii.gz'
        } else {
            $new_filename += '.nii.gz'
        }

        # Rename the file if the new name is different
        if ($filename -ne $new_filename) {
            $new_path = Join-Path -Path $dir -ChildPath $new_filename
            try {
                Rename-Item -Path $file.FullName -NewName $new_path
                Write-Host "Renamed: $filename -> $new_filename"
            } catch {
                Write-Host "Failed to rename: $filename. $_"
            }
        }
    }
}

# Print a completion message
Write-Host "Finished fixing filenames in directory: $root_dir"