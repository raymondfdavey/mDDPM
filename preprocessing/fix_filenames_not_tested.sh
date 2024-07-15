#!/bin/bash

# Check if a root directory is provided
if [ -z "$1" ]; then
  echo "Usage: $0 <root_directory>"
  exit 1
fi

ROOT_DIR="$1"

# Print a start message
echo "Starting to fix filenames in directory: $ROOT_DIR"

# Function to fix filenames
fix_filename() {
  local file="$1"
  local dir
  dir=$(dirname "$file")
  local filename
  filename=$(basename "$file")

  # Print current filename
  echo "Processing file: $filename"

  # Check if the filename contains '.nii.gz' and is followed by another '.nii.gz' (or more)
  if [[ "$filename" == *".nii.gz"* ]]; then
    # Remove the first instance of '.nii.gz' from the filename
    new_filename="${filename/.nii.gz/}"

    # Ensure the correct format is preserved
    if [[ "$new_filename" =~ \.(mask|seg|t2)$ ]]; then
      new_filename="${new_filename/.}_"
      new_filename+="_${BASH_REMATCH[1]}.nii.gz"
    else
      new_filename+='.nii.gz'
    fi

    # Rename the file if the new name is different
    if [ "$filename" != "$new_filename" ]; then
      new_path="$dir/$new_filename"
      if mv "$file" "$new_path"; then
        echo "Renamed: $filename -> $new_filename"
      else
        echo "Failed to rename: $filename"
      fi
    fi
  fi
}

export -f fix_filename

# Find all files recursively from the root directory, including hidden files, and fix filenames
find "$ROOT_DIR" -type f -exec bash -c 'fix_filename "$0"' {} \;

# Print a completion message
echo "Finished fixing filenames in directory: $ROOT_DIR"


# TO RUN:
# chmod +x fix_filenames.sh
# ./fix_filenames.sh /path/to/root_directory
