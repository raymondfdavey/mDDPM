import os
import sys
import re

def rename_files(data_dir):
    for root, dirs, files in os.walk(data_dir):
        for file in files:
            if file.endswith('.nii.gz'):
                full_path = os.path.join(root, file)
                dir_name = os.path.basename(root)
                parent_dir = os.path.basename(os.path.dirname(root))

                if dir_name == 't2':
                    new_name = re.sub(r'[-_]?T2W?\.nii\.gz$', '.nii.gz', file, flags=re.IGNORECASE)
                elif dir_name == 'seg':
                    if parent_dir == 'MSLUB_clean':
                        new_name = re.sub(r'_consensus_gt\.nii\.gz$', '_seg.nii.gz', file)
                    else:
                        new_name = re.sub(r'[-_]?seg\.nii\.gz$', '_seg.nii.gz', file)
                else:
                    continue

                new_path = os.path.join(root, new_name)
                os.rename(full_path, new_path)
                print(f"Renamed: {full_path} -> {new_path}")

def rename_directories(data_dir):
    for root, dirs, files in os.walk(data_dir, topdown=False):
        for dir in dirs:
            full_path = os.path.join(root, dir)
            new_name = dir

            # Remove '_clean' suffix
            if dir.endswith('_clean'):
                if dir == 'BraTS21_clean':
                    new_name = 'Brats21'
                else:
                    new_name = dir[:-6]  # Remove last 6 characters ('_clean')
            
            # Rename 'IXI-T2' to 't2'
            elif dir == 'IXI-T2':
                new_name = 't2'
                
            if new_name != dir:
                new_path = os.path.join(root, new_name)
                os.rename(full_path, new_path)
                print(f"Renamed directory: {full_path} -> {new_path}")

if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: python rename_script.py <DATA_DIR>")
        sys.exit(1)

    data_dir = sys.argv[1]
    if not os.path.isdir(data_dir):
        print(f"Error: {data_dir} is not a valid directory")
        sys.exit(1)

    rename_files(data_dir)
    rename_directories(data_dir)
    print("Renaming complete.")