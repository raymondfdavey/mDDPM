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
# For BRATS, we already have resampled, skull-stripped data 
mkdir -p $DATA_DIR/v2skullstripped/Brats21/
mkdir -p $DATA_DIR/v2skullstripped/Brats21/mask
cp -r  $INPUT_DIR/t2  $INPUT_DIR/seg $DATA_DIR/v2skullstripped/Brats21/

echo "extract masks"
python3 get_mask.py -i $DATA_DIR/v2skullstripped/Brats21/t2 -o $DATA_DIR/v2skullstripped/Brats21/t2 -mod t2 
python3 extract_masks.py -i $DATA_DIR/v2skullstripped/Brats21/t2 -o $DATA_DIR/v2skullstripped/Brats21/mask
python3 replace.py -i $DATA_DIR/v2skullstripped/Brats21/mask -s " _t2" ""

# rename t2 and seg files so in correct format for registration (as brats pipeline misses the resampling step that does this in others)
for file in $DATA_DIR/v2skullstripped/Brats21/t2/*.nii.gz; do
    mv "$file" "${file%.nii.gz}.nii.gz_t2.nii.gz"
done

for file in $DATA_DIR/v2skullstripped/Brats21/seg/*_seg.nii.gz; do
    mv "$file" "${file%_seg.nii.gz}.nii.gz_seg.nii.gz"
done

echo "Register t2"
python3 registration.py -i $DATA_DIR/v2skullstripped/Brats21/t2 -o $DATA_DIR/v3registered_non_iso/Brats21/t2 --modality=_t2 -trans Affine -templ sri_atlas/templates/T1_brain.nii

echo "Cut to brain"
python3 cut.py -i $DATA_DIR/v3registered_non_iso/Brats21/t2 -m $DATA_DIR/v3registered_non_iso/Brats21/mask/ -o $DATA_DIR/v3registered_non_iso_cut/Brats21/ -mode t2

echo "Bias Field Correction"
python3 n4filter.py -i $DATA_DIR/v3registered_non_iso_cut/Brats21/t2 -o $DATA_DIR/v4correctedN4_non_iso_cut/Brats21/t2 -m $DATA_DIR/v3registered_non_iso_cut/Brats21/mask

mkdir $DATA_DIR/v4correctedN4_non_iso_cut/Brats21/mask
cp $DATA_DIR/v3registered_non_iso_cut/Brats21/mask/* $DATA_DIR/v4correctedN4_non_iso_cut/Brats21/mask
mkdir $DATA_DIR/v4correctedN4_non_iso_cut/Brats21/seg
cp $DATA_DIR/v3registered_non_iso_cut/Brats21/seg/* $DATA_DIR/v4correctedN4_non_iso_cut/Brats21/seg
echo "Done"

# now, you should copy the files in the output directory to the data directory of the project
