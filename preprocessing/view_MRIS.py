# Import all the necessary packages
import numpy as np
import nibabel as nib
import itk
import itkwidgets
from ipywidgets import interact, interactive, IntSlider, ToggleButtons
import matplotlib.pyplot as plt
%matplotlib inline
import seaborn as sns
sns.set_style('darkgrid')
import random
import os
import sys

import torch 
print(torch.backends.mps.is_available())

def explore_3dimage(image_data, layer, image_path):
    plt.figure(figsize=(10, 5))
    plt.imshow(image_data[:, :, layer], cmap='gray');
    plt.title(f'{image_path[2:-7]}', fontsize=20)
    plt.axis('off')
    return layer

def viz_interactive_3D_image(image_path):
    image_obj = nib.load(image_path)
    image_data = image_obj.get_fdata()
    print('image_data pixels data type: ',  image_data.dtype)
    print('image_data type: ',  type(image_data))
    print('image_obj type: ',  type(image_obj))
    height, width, depth = image_data.shape
    print(f"({height}, {width}, {depth})")
    interact(lambda layer: explore_3dimage(image_data, layer, image_path), layer=(0, image_data.shape[2] - 1))

def get_random_file(directory):
    """
    Returns a random filename from the specified directory as a full path.
    
    Args:
    directory (str): The path to the directory.
    
    Returns:
    str: The full path to a random file in the directory.
         Returns None if the directory is empty or doesn't exist.
    """
    try:
        # Get all files in the directory
        files = [f for f in os.listdir(directory) if os.path.isfile(os.path.join(directory, f))]
        
        # If there are no files, return None
        if not files:
            return None
        
        # Select a random file
        random_file = random.choice(files)
        
        # Return the full path
        return os.path.join(directory, random_file)
    
    except FileNotFoundError:
        print(f"Directory not found: {directory}")
        return None
    except PermissionError:
        print(f"Permission denied to access directory: {directory}")
        return None




def main(passed_directory):
    exit = False
    while exit == False:  
        path = get_random_file(passed_directory)    
        viz_interactive_3D_image(path)

if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: python script_name.py /path/to/mri/directory")
    else:
        main(sys.argv[1])