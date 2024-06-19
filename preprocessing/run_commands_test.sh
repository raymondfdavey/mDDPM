#!/bin/bash

# Run prepare_IXI.sh
echo "RUNNING IXI PREPROCESSING"
bash prepare_IXI.sh /Users/rd81/Downloads/MINI_DATA/IXI /Users/rd81/Downloads/MINI_DATA/MINI_PROCESSED

# Run prepare_MSLUB.sh
echo "running MSLIB PREPROCESSING"
bash prepare_MSLUB.sh /Users/rd81/Downloads/MINI_DATA/MSLUB /Users/rd81/Downloads/MINI_DATA/MINI_PROCESSED

# Run prepare_Brats21.sh
echo "running BRATS PREPROCESSING"
bash prepare_Brats21.sh /Users/rd81/Downloads/MINI_DATA/Brats21 /Users/rd81/Downloads/MINI_DATA/MINI_PROCESSED