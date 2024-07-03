import os
import shutil


# initial reorg
data = 'BRATS' # or MSLUB

if data == 'BRATS':
    # Define source and destination directories
    source_dir = r'C:\Users\rd81\OneDrive - University of Sussex\Desktop\diss_git\RAW_DATA\BraTS21\ASNR-MICCAI-BraTS2023-GLI-Challenge-TrainingData'
    destination_dir = r'C:\Users\rd81\OneDrive - University of Sussex\Desktop\diss_git\RAW_DATA\BraTS21_clean'
    destination_sub_dirs = ['t2', 'seg']

    # Create the destination directory if it doesn't exist
    os.makedirs(destination_dir, exist_ok=True)

    # Create subdirectories in the destination directory
    for sub_dir in destination_sub_dirs:
        os.makedirs(os.path.join(destination_dir, sub_dir), exist_ok=True)
    
    # Walk through the source directory and its subdirectories
    for root, dirs, files in os.walk(source_dir):
        for file in files:
            if 't2w' in file:
                print(file)
                file_path = os.path.join(root, file)
                print(f'File path: {file_path}')
                destination_path = os.path.join(destination_dir, 't2')
                shutil.copy(file_path, destination_path)
                print(f'Copied: {file_path} to {destination_path}')
                
            if 'seg' in file:             
                print(file)
                file_path = os.path.join(root, file)
                print(f'File path: {file_path}')
                destination_path = os.path.join(destination_dir, 'seg')
                shutil.copy(file_path, destination_path)
                print(f'Copied: {file_path} to {destination_path}')

        
        
        
        
        
else:
    # Define source and destination directories
    source_dir = r'C:\Users\rd81\OneDrive - University of Sussex\Desktop\diss_git\RAW_DATA\MSLUB'
    destination_dir = r'C:\Users\rd81\OneDrive - University of Sussex\Desktop\diss_git\RAW_DATA\MSLUB_clean'
    destination_sub_dirs = ['t2', 'seg']

    # Create the destination directory if it doesn't exist
    os.makedirs(destination_dir, exist_ok=True)

    # Create subdirectories in the destination directory
    for sub_dir in destination_sub_dirs:
        os.makedirs(os.path.join(destination_dir, sub_dir), exist_ok=True)

    # Walk through the source directory and its subdirectories
    for root, dirs, files in os.walk(source_dir):
        for file in files:
            if 'T2W.n' in file:
                print(file)
                file_path = os.path.join(root, file)
                print(f'File path: {file_path}')
                destination_path = os.path.join(destination_dir, 't2')
                shutil.copy(file_path, destination_path)
                print(f'Copied: {file_path} to {destination_path}')
                
            if 'consensus' in file:             
                print(file)
                file_path = os.path.join(root, file)
                print(f'File path: {file_path}')
                destination_path = os.path.join(destination_dir, 'seg')
                shutil.copy(file_path, destination_path)
                print(f'Copied: {file_path} to {destination_path}')


