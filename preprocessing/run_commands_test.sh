#!/bin/bash

# Define variables
original_data_dir="/Users/rd81/Documents/MINI_DATA_FOR_PLAY/MINI_ORIGINAL"
processed_data_dir="/Users/rd81/Documents/MINI_DATA_FOR_PLAY/MINI_PROCESSED"

# # Run prepare_IXI.sh - WORKING!
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

