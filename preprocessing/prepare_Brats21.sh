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
mkdir -p $DATA_DIR/v1resampled/Brats21/t2
python3 resample.py -i $INPUT_DIR/t2 -o $DATA_DIR/v1resampled/Brats21/t2 -r 1.0 1.0 1.0 
## rename files for standard naming
for file in $DATA_DIR/v1resampled/Brats21/t2/*
do
  mv "$file" "${file%_T2W.nii.gz}_t2.nii.gz"
done

echo "Generate masks"
hd-bet -i $DATA_DIR/v1resampled/Brats21/t2 -o $DATA_DIR/v2skullstripped/Brats21/t2 -device cpu -mode fast -tta 0

# CUDA_VISIBLE_DEVICES=0 hd-bet -i $DATA_DIR/v1resampled/IXI/t2 -o $DATA_DIR/v2skullstripped/IXI/t2 

python3 extract_masks.py -i $DATA_DIR/v2skullstripped/Brats21/t2 -o $DATA_DIR/v2skullstripped/Brats21/mask
python3 replace.py -i $DATA_DIR/v2skullstripped/Brats21/mask -s " _t2" ""



# copy segmentation masks to the data directory
mkdir -p $DATA_DIR/v2skullstripped/Brats21/seg
cp -r $INPUT_DIR/seg/* $DATA_DIR/v2skullstripped/Brats21/seg/

for file in $DATA_DIR/v2skullstripped/Brats21/seg/*
do
  # Remove the trailing "_seg.nii.gz" if it already exists to avoid appending it twice
  base_name="${file%_seg.nii.gz}"
  mv "$file" "${base_name}.nii.gz_seg.nii.gz"
done


echo "Register t2"
python3 registration.py -i $DATA_DIR/v2skullstripped/Brats21/t2 -o $DATA_DIR/v3registered_non_iso/Brats21/t2 --modality=_t2 -trans Affine -templ sri_atlas/templates/T1_brain.nii


echo "Cut to brain"
python3 cut.py -i $DATA_DIR/v3registered_non_iso/Brats21/t2 -m $DATA_DIR/v3registered_non_iso/Brats21/mask/ -o $DATA_DIR/v3registered_non_iso_cut/Brats21/ -mode t2

echo "Bias Field Correction"
python3 n4filter.py -i $DATA_DIR/v3registered_non_iso_cut/Brats21/t2 -o $DATA_DIR/v4correctedN4_non_iso_cut/Brats21/t2 -m $DATA_DIR/v4correctedN4_non_iso_cut/Brats21/mask
mkdir $DATA_DIR/v4correctedN4_non_iso_cut/Brats21/mask
cp $DATA_DIR/v3registered_non_iso_cut/Brats21/mask/* $DATA_DIR/v4correctedN4_non_iso_cut/Brats21/mask
mkdir $DATA_DIR/v4correctedN4_non_iso_cut/Brats21/seg
cp $DATA_DIR/v3registered_non_iso_cut/Brats21/seg/* $DATA_DIR/v4correctedN4_non_iso_cut/Brats21/seg
echo "Done"

# now, you should copy the files in the output directory to the data directory of the project
