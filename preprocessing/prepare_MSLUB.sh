#!/bin/bash
# cli arguments: 
# 1. path to data directory
# 2. path to output directory
INPUT_DIR=$1
DATA_DIR=$2

# make the arguments mandatory and that the data dir is not a relative path
if [ -z "$INPUT_DIR" ] || [ -z "$DATA_DIR" ] 
then
  echo "Usage: ./prepare_MSLUB.sh <input_dir> <output_dir>"
  exit 1
fi

if [ "$INPUT_DIR" == "." ] || [ "$INPUT_DIR" == ".." ]
then
  echo "Please use absolute paths for input_dir"
  exit 1
fi  

echo "Resample"
mkdir -p $DATA_DIR/v1resampled/MSLUB/t2
python3 resample.py -i $INPUT_DIR/t2 -o $DATA_DIR/v1resampled/MSLUB/t2 -r 1.0 1.0 1.0 
## rename files for standard naming
for file in $DATA_DIR/v1resampled/MSLUB/t2/*
do
  mv "$file" "${file%_T2W.nii.gz}_t2.nii.gz"
done

echo "Generate masks"

# cpu
# hd-bet -i $DATA_DIR/v1resampled/MSLUB/t2 -o $DATA_DIR/v2skullstripped/MSLUB/t2 -device cpu -mode fast -tta 0
# mps
PYTORCH_ENABLE_MPS_FALLBACK=1 hd-bet -i $DATA_DIR/v1resampled/MSLUB/t2 -o $DATA_DIR/v2skullstripped/MSLUB/t2 -device mps -mode fast -tta 0
# gpu
# CUDA_VISIBLE_DEVICES=0 hd-bet -i $DATA_DIR/v1resampled/MSLUB/t2 -o $DATA_DIR/v2skullstripped/MSLUB/t2 -device 0

python3 extract_masks.py -i $DATA_DIR/v2skullstripped/MSLUB/t2 -o $DATA_DIR/v2skullstripped/MSLUB/mask
python3 replace.py -i $DATA_DIR/v2skullstripped/MSLUB/mask -s " _t2" ""

# copy segmentation masks to the data directory
mkdir -p $DATA_DIR/v2skullstripped/MSLUB/seg
cp -r $INPUT_DIR/seg/* $DATA_DIR/v2skullstripped/MSLUB/seg/

for file in $DATA_DIR/v2skullstripped/MSLUB/seg/*
do
  # Remove the trailing "_seg.nii.gz" if it already exists to avoid appending it twice
  base_name="${file%_seg.nii.gz}"
  mv "$file" "${base_name}.nii.gz_seg.nii.gz"
done

echo "Register t2"
# automatically registers the segmentation files as well
python3 registration.py -i $DATA_DIR/v2skullstripped/MSLUB/t2 -o $DATA_DIR/v3registered_non_iso/MSLUB/t2 --modality=_t2 -trans Affine -templ sri_atlas/templates/T1_brain.nii

echo "Cut to brain"
# automatically cuts the segmentation files as well
python3 cut.py -i $DATA_DIR/v3registered_non_iso/MSLUB/t2 -m $DATA_DIR/v3registered_non_iso/MSLUB/mask/ -o $DATA_DIR/v3registered_non_iso_cut/MSLUB/ -mode t2

echo "Bias Field Correction"
python3 n4filter.py -i $DATA_DIR/v3registered_non_iso_cut/MSLUB/t2 -o $DATA_DIR/v4correctedN4_non_iso_cut/MSLUB/t2 -m $DATA_DIR/v3registered_non_iso_cut/MSLUB/mask

mkdir $DATA_DIR/v4correctedN4_non_iso_cut/MSLUB/mask
cp $DATA_DIR/v3registered_non_iso_cut/MSLUB/mask/* $DATA_DIR/v4correctedN4_non_iso_cut/MSLUB/mask

mkdir $DATA_DIR/v4correctedN4_non_iso_cut/MSLUB/seg
cp $DATA_DIR/v3registered_non_iso_cut/MSLUB/seg/* $DATA_DIR/v4correctedN4_non_iso_cut/MSLUB/seg

echo "Done"


# # now, you should copy the files in the output directory to the data directory of the project









