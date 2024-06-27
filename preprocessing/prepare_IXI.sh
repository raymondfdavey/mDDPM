#!/bin/bash
# cli arguments: 
# 1. path to data directory
# 2. path to output directory
INPUT_DIR=$1
DATA_DIR=$2

# make the arguments mandatory and that the data dir is not a relative path
if [ -z "$INPUT_DIR" ] || [ -z "$DATA_DIR" ] 
then
  echo "Usage: ./prepare_IXI.sh <input_dir> <output_dir>"
  exit 1
fi

if [ "$INPUT_DIR" == "." ] || [ "$INPUT_DIR" == ".." ]
then
  echo "Please use absolute paths for input_dir"
  exit 1
fi

echo "Resample"
mkdir -p $DATA_DIR/v1resampled/IXI/t2
python3 resample.py -i $INPUT_DIR/t2 -o $DATA_DIR/v1resampled/IXI/t2 -r 1.0 1.0 1.0 
# rename files for standard naming
for file in $DATA_DIR/v1resampled/IXI/t2/*
do
  mv "$file" "${file%-T2.nii.gz}_t2.nii.gz"
done

echo "Generate masks"
# cpu
# hd-bet -i $DATA_DIR/v1resampled/IXI/t2 -o $DATA_DIR/v2skullstripped/IXI/t2 -device cpu -mode fast -tta 0

# mps
PYTORCH_ENABLE_MPS_FALLBACK=1 hd-bet -i $DATA_DIR/v1resampled/IXI/t2 -o $DATA_DIR/v2skullstripped/IXI/t2 -device mps -mode fast -tta 0

# gpu
# CUDA_VISIBLE_DEVICES=0 hd-bet -i $DATA_DIR/v1resampled/IXI/t2 -o $DATA_DIR/v2skullstripped/IXI/t2 -device 0

python3 extract_masks.py -i $DATA_DIR/v2skullstripped/IXI/t2 -o $DATA_DIR/v2skullstripped/IXI/mask
python3 replace.py -i $DATA_DIR/v2skullstripped/IXI/mask -s " _t2" ""

echo "Register t2"
python3 registration.py -i $DATA_DIR/v2skullstripped/IXI/t2 -o $DATA_DIR/v3registered_non_iso/IXI/t2 --modality=_t2 -trans Affine -templ sri_atlas/templates/T1_brain.nii

echo "Cut to brain"
python3 cut.py -i $DATA_DIR/v3registered_non_iso/IXI/t2 -m $DATA_DIR/v3registered_non_iso/IXI/mask/ -o $DATA_DIR/v3registered_non_iso_cut/IXI/ -mode t2

echo "Bias Field Correction"
python3 n4filter.py -i $DATA_DIR/v3registered_non_iso_cut/IXI/t2 -o $DATA_DIR/v4correctedN4_non_iso_cut/IXI/t2 -m $DATA_DIR/v3registered_non_iso_cut/IXI/mask

mkdir $DATA_DIR/v4correctedN4_non_iso_cut/IXI/mask
cp $DATA_DIR/v3registered_non_iso_cut/IXI/mask/* $DATA_DIR/v4correctedN4_non_iso_cut/IXI/mask
echo "Done"

# # now, you should copy the files in the output directory to the data directory of the project









