import SimpleITK as sitk
import pandas as pd
import matplotlib.pyplot as plt
import numpy as np 
from tqdm import tqdm 
import argparse
import os
import sys
from pathlib import Path
import ants
import logging
import psutil

# Set up logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

def arg_parser():
    parser = argparse.ArgumentParser(
        description='Resample 3D volumes in NIfTI format')
    parser.add_argument('-i', '--img-dir', type=str, required=True,
                        help='path to directory with images to be processed')
    parser.add_argument('-modal', '--modality', type=str, required=False, default='_t1',
                    help='t1, t2, FLAIR, ...')
    parser.add_argument('-o', '--out-dir', type=str, required=False, default='tmp',
                        help='output directory for preprocessed files')
    parser.add_argument('-r', '--resolution', type=float, required=False, nargs=3, default=[1.0, 1.0, 1.0],
                        help='target resolution')
    parser.add_argument('-or', '--orientation', type=str, required=False, default='RAS',
                        help='target orientation')
    parser.add_argument('-inter', '--interpolation', type=int, required=False, default=4,
                        help='target orientation')
    parser.add_argument('-nomask', '--nomaskandseg', type=int, required=False, default=0,
                        help='set to one if you can reuse the masks and segmentations of other modalities')
    parser.add_argument('-trans', '--transform', type=str, required=False, default='Rigid',
                        help='specify the transformation')
    parser.add_argument('-templ', '--template', type=str, required=True,
                        help='path to template')
    parser.add_argument('--overwrite', action='store_true', help='Overwrite existing files')
    return parser

def log_system_info():
    logger.info(f"CPU usage: {psutil.cpu_percent()}%")
    logger.info(f"Memory usage: {psutil.virtual_memory().percent}%")
    logger.info(f"Disk usage: {psutil.disk_usage('/').percent}%")

def main(args=None):
    args = arg_parser().parse_args(args)
    logger.info(f"Starting registration process with args: {args}")
    log_system_info()

    src_basepath = args.img_dir
    dest_basepath = args.out_dir

    if not os.path.isdir(args.img_dir):
        logger.error(f"Input directory does not exist: {args.img_dir}")
        raise ValueError('(-i / --img-dir) argument needs to be a directory of NIfTI images.')

    Path(args.out_dir).mkdir(parents=True, exist_ok=True)
    logger.info(f"Created output directory: {args.out_dir}")

    try:
        fixed_im = ants.image_read(args.template)
        fixed_im = fixed_im.reorient_image2(args.orientation)
        logger.info(f"Successfully read and reoriented template image: {args.template}")
    except Exception as e:
        logger.error(f"Failed to read or reorient template image: {str(e)}")
        return

    if os.path.isdir(os.path.join(Path(args.img_dir).parents[0],'seg')) and args.nomaskandseg !=1:
        seg_path = os.path.join(Path(args.img_dir).parents[0],'seg')
        seg_out = os.path.join(Path(args.out_dir).parents[0],'seg')
        Path(seg_out).mkdir(parents=True, exist_ok=True)
    else: 
        seg_path = None

    if os.path.isdir(os.path.join(Path(args.img_dir).parents[0],'mask')) and args.nomaskandseg !=1:
        mask_path = os.path.join(Path(args.img_dir).parents[0],'mask')
        mask_out = os.path.join(Path(args.out_dir).parents[0],'mask')
        Path(mask_out).mkdir(parents=True, exist_ok=True)
    else: 
        mask_path = None

    for i, file in tqdm(enumerate(os.listdir(args.img_dir))):
        if file == '.DS_Store':
            continue
        
        if not args.overwrite and os.path.isfile(os.path.join(dest_basepath, file)):
            logger.info(f"Skipping existing file: {file}")
            continue

        try:
            path_img = os.path.join(args.img_dir, file)
            if not os.path.isfile(path_img):
                logger.warning(f"Input file not found: {path_img}")
                continue

            moving_im = ants.image_read(path_img)
            logger.info(f"Successfully read image: {path_img}")

            im_tx = ants.registration(fixed=fixed_im, moving=moving_im, type_of_transform=args.transform)
            moved_im = im_tx['warpedmovout']
            ants.image_write(moved_im, os.path.join(dest_basepath, file))
            logger.info(f"Successfully registered and saved image: {file}")

            if mask_path is not None:
                path_mask = os.path.join(mask_path, file.replace(args.modality,'_mask'))
                if os.path.isfile(path_mask):
                    moving_mask = ants.image_read(path_mask)
                    moved_mask = ants.apply_transforms(fixed=fixed_im, moving=moving_mask,
                                               transformlist=im_tx['fwdtransforms'])
                    ants.image_write(moved_mask, os.path.join(mask_out, file.replace(args.modality,'_mask')))
                    logger.info(f"Successfully processed mask for: {file}")
                else:
                    logger.warning(f"Mask file not found: {path_mask}")

            if seg_path is not None:
                path_seg = os.path.join(seg_path, file.replace(args.modality,'_seg'))
                if os.path.isfile(path_seg):
                    moving_seg = ants.image_read(path_seg)
                    moving_seg = moving_seg.reorient_image2(args.orientation)
                    moved_seg = ants.apply_transforms(fixed=fixed_im, moving=moving_seg,
                                               transformlist=im_tx['fwdtransforms'])
                    ants.image_write(moved_seg, os.path.join(seg_out, file.replace(args.modality,'_seg')))
                    logger.info(f"Successfully processed segmentation for: {file}")
                else:
                    logger.warning(f"Segmentation file not found: {path_seg}")

        except Exception as e:
            logger.error(f"Error processing {file}: {str(e)}")
            continue

        log_system_info()

    logger.info("Registration process completed")

if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))

# import SimpleITK as sitk
# import pandas as pd
# import matplotlib.pyplot as plt
# import numpy as np 
# from tqdm import tqdm 
# import argparse
# import os
# import sys
# from pathlib import Path
# import ants

# def arg_parser():
#     parser = argparse.ArgumentParser(
#         description='Resample 3D volumes in NIfTI format')
#     parser.add_argument('-i', '--img-dir', type=str, required=True,
#                         help='path to directory with images to be processed')
#     parser.add_argument('-modal', '--modality', type=str, required=False, default='_t1',
#                     help='t1, t2, FLAIR, ...')
#     parser.add_argument('-o', '--out-dir', type=str, required=False, default='tmp',
#                         help='output directory for preprocessed files')
#     parser.add_argument('-r', '--resolution', type=float, required=False, nargs=3, default=[1.0, 1.0, 1.0],
#                         help='target resolution')
#     parser.add_argument('-or', '--orientation', type=str, required=False, default='RAS',
#                         help='target orientation')
#     parser.add_argument('-inter', '--interpolation', type=int, required=False, default=4,
#                         help='target orientation')
#     parser.add_argument('-nomask', '--nomaskandseg', type=int, required=False, default=0,
#                         help='set to one if you can reuse the masks and segmentations of other modalities')
#     parser.add_argument('-trans', '--transform', type=str, required=False, default='Rigid',
#                         help='specify the transformation')
#     parser.add_argument('-templ', '--template', type=str, required=True,
#                         help='path to template')
#     return parser

# def main(args=None):
#     args = arg_parser().parse_args(args)
#     src_basepath = args.img_dir #
#     dest_basepath =  args.out_dir #


#     if not os.path.isdir(args.img_dir):
#         raise ValueError('(-i / --img-dir) argument needs to be a directory of NIfTI images.')

#     Path(args.out_dir).mkdir(parents=True,exist_ok=True)

#     fixed_im = ants.image_read(args.template)
#     fixed_im = fixed_im.reorient_image2('RAI')

#     if os.path.isdir(os.path.join(Path(args.img_dir).parents[0],'seg')) and args.nomaskandseg !=1:
#         seg_path = os.path.join(Path(args.img_dir).parents[0],'seg')
#         seg_out = os.path.join(Path(args.out_dir).parents[0],'seg')
#         Path(seg_out).mkdir(parents=True,exist_ok=True)
#     else: 
#         seg_path = None

#     if  os.path.isdir(os.path.join(Path(args.img_dir).parents[0],'mask')) and args.nomaskandseg !=1:
#         mask_path = os.path.join(Path(args.img_dir).parents[0],'mask')
#         mask_out = os.path.join(Path(args.out_dir).parents[0],'mask')
#         Path(mask_out).mkdir(parents=True,exist_ok=True)
#     else: 
#         mask_path = None

#     for i, file in tqdm(enumerate(os.listdir(args.img_dir))):
#         if file == '.DS_Store':
#             continue
#         if not os.path.isfile(os.path.join(dest_basepath, file)) or not os.path.isfile(os.path.join(mask_out, file.replace(args.modality,'_mask'))) or not os.path.isfile(os.path.join(seg_out, file.replace(args.modality,'_seg'))):
#             path_img = os.path.join(args.img_dir, file)
#             moving_im = ants.image_read(path_img)
#             # register to template
#             im_tx = ants.registration(fixed=fixed_im, moving=moving_im, type_of_transform = args.transform )
#             moved_im = im_tx['warpedmovout']
#             ants.image_write(moved_im, os.path.join(dest_basepath, file))

#             if mask_path is not None:
#                 path_mask = os.path.join(mask_path, file.replace(args.modality,'_mask'))
#                 moving_mask = ants.image_read(path_mask)
#                 # transform the mask in the same way as the volume
#                 moved_mask = ants.apply_transforms( fixed=fixed_im, moving=moving_mask,
#                                            transformlist=im_tx['fwdtransforms'] )
#                 ants.image_write(moved_mask, os.path.join(mask_out, file.replace(args.modality,'_mask')))

#             if seg_path is not None:
#                 path_seg = os.path.join(seg_path, file.replace(args.modality,'_seg'))
#                 moving_seg = ants.image_read(path_seg)
#                 moving_seg = moving_seg.reorient_image2('RAI') # reorient to standard orientation
#                 # transform the segmentation in the same way as the volume
#                 moved_seg = ants.apply_transforms( fixed=fixed_im, moving=moving_seg,
#                                            transformlist=im_tx['fwdtransforms'] )
#                 ants.image_write(moved_seg, os.path.join(seg_out, file.replace(args.modality,'_seg')))

        




# if __name__ == "__main__":
#     sys.exit(main(sys.argv[1:]))


