#!/bin/bash
# PATHS FOR USING

# Define variables
# original_data_dir="/Users/rd81/Documents/MINI_DATA_FOR_PLAY/MINI_ORIGINAL"
# processed_data_dir="/Users/rd81/Documents/MINI_DATA_FOR_PLAY/MINI_PROCESSED"
# final_data_target_dir="/Users/rd81/Documents/MINI_DATA_FOR_PLAY/MINI_FINAL"
# splits_data="/Users/rd81/Library/CloudStorage/OneDrive-UniversityofSussex/Desktop/diss_git/mDDPM/Data/splits"
#  eg: ./run_commands_test.sh /Users/rd81/Documents/MINI_DATA_FOR_PLAY/MINI_ORIGINAL /Users/rd81/Documents/MINI_DATA_FOR_PLAY/MINI_PROCESSED /Users/rd81/Documents/MINI_DATA_FOR_PLAY/MINI_FINAL /Users/rd81/Library/CloudStorage/OneDrive-UniversityofSussex/Desktop/diss_git/mDDPM/Data/splits
# Check if the correct number of arguments is provided
if [ "$#" -ne 4 ]; then
    echo "Usage: $0 <ORIGINAL_DATA_DIR> <PROCESSED_DATA_DIR> <FINAL_DATA_TARGET_DIR> <SPLITS_DATA_DIR>"
    exit 1
fi

# Define variables from command-line arguments
original_data_dir="$1"
processed_data_dir="$2"
final_data_target_dir="$3"
splits_data="$4"

# Run prepare_IXI.sh
echo "RUNNING IXI PREPROCESSING"
bash prepare_IXI.sh "$original_data_dir/IXI" "$processed_data_dir"
echo "IXI PREPROCESSING...DONE!"

# Run prepare_MSLUB.sh
echo "RUNNING MSLUB PREPROCESSING"
bash prepare_MSLUB.sh "$original_data_dir/MSLUB" "$processed_data_dir"
echo "MSLUB PREPROCESSING...DONE!"

# Run prepare_Brats21.sh
echo "RUNNING BRATS PREPROCESSING"
bash prepare_Brats21.sh "$original_data_dir/Brats21" "$processed_data_dir"
echo "BRATS PREPROCESSING...DONE!"

echo "CREATING TARGET DIRECTORIES"
mkdir -p "$final_data_target_dir/Train"
mkdir -p "$final_data_target_dir/Test" 

echo "MOVING TO FINAL LOCATIONS"
cp -r "$processed_data_dir/v4correctedN4_non_iso_cut/IXI" "$final_data_target_dir/Train"
cp -r "$processed_data_dir/v4correctedN4_non_iso_cut/MSLUB" "$final_data_target_dir/Test"
cp -r "$processed_data_dir/v4correctedN4_non_iso_cut/Brats21" "$final_data_target_dir/Test"
cp -r "$splits_data" "$final_data_target_dir/"
echo "MOVING COMPLETE, DATA FOR TRAINING IN $final_data_target_dir"
