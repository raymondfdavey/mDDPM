import os
import sys
import subprocess
from pathlib import Path

def main(input_dir, data_dir):
    # Resample
    print("Resample")
    output_dir = os.path.join(data_dir, "v1resampled", "IXI", "t2")
    Path(output_dir).mkdir(parents=True, exist_ok=True)
    resample_command = [
        "python", "resample.py",
        "-i", os.path.join(input_dir, "t2"),
        "-o", output_dir,
        "-r", "1.0", "1.0", "1.0"
    ]
    subprocess.run(resample_command, check=True)

    # Rename files for standard naming
    for file in os.listdir(output_dir):
        old_path = os.path.join(output_dir, file)
        new_path = os.path.join(output_dir, f"{file[:-9]}_t2.nii.gz")
        os.rename(old_path, new_path)

    # Generate masks
    print("Generate masks")
    os.environ["CUDA_VISIBLE_DEVICES"] = "0"
    skullstripped_dir = os.path.join(data_dir, "v2skullstripped", "IXI", "t2")
    Path(skullstripped_dir).mkdir(parents=True, exist_ok=True)
    subprocess.run(["hd-bet", "-i", output_dir, "-o", skullstripped_dir], check=True)

    mask_dir = os.path.join(data_dir, "v2skullstripped", "IXI", "mask")
    Path(mask_dir).mkdir(parents=True, exist_ok=True)
    extract_masks_command = [
        "python", "extract_masks.py",
        "-i", skullstripped_dir,
        "-o", mask_dir
    ]
    subprocess.run(extract_masks_command, check=True)

    replace_command = [
        "python", "replace.py",
        "-i", mask_dir,
        "-s", " _t2", ""
    ]
    subprocess.run(replace_command, check=True)

    # Register t2
    print("Register t2")
    registered_dir = os.path.join(data_dir, "v3registered_non_iso", "IXI", "t2")
    Path(registered_dir).mkdir(parents=True, exist_ok=True)
    registration_command = [
        "python", "registration.py",
        "-i", skullstripped_dir,
        "-o", registered_dir,
        "--modality=_t2",
        "-trans", "Affine",
        "-templ", "sri_atlas/templates/T1_brain.nii"
    ]
    subprocess.run(registration_command, check=True)

    # Cut to brain
    print("Cut to brain")
    cut_dir = os.path.join(data_dir, "v3registered_non_iso_cut", "IXI", "t2")
    Path(cut_dir).mkdir(parents=True, exist_ok=True)
    cut_command = [
        "python", "cut.py",
        "-i", registered_dir,
        "-m", os.path.join(data_dir, "v3registered_non_iso", "IXI", "mask"),
        "-o", cut_dir,
        "-mode", "t2"
    ]
    subprocess.run(cut_command, check=True)

    # Bias Field Correction
    print("Bias Field Correction")
    corrected_dir = os.path.join(data_dir, "v4correctedN4_non_iso_cut", "IXI", "t2")
    Path(corrected_dir).mkdir(parents=True, exist_ok=True)
    n4filter_command = [
        "python", "n4filter.py",
        "-i", cut_dir,
        "-o", corrected_dir,
        "-m", os.path.join(cut_dir, "mask")
    ]
    subprocess.run(n4filter_command, check=True)

    # Copy mask files
    corrected_mask_dir = os.path.join(data_dir, "v4correctedN4_non_iso_cut", "IXI", "mask")
    Path(corrected_mask_dir).mkdir(parents=True, exist_ok=True)
    mask_files = os.listdir(os.path.join(data_dir, "v3registered_non_iso", "IXI", "mask"))
    for file in mask_files:
        src_path = os.path.join(data_dir, "v3registered_non_iso", "IXI", "mask", file)
        dst_path = os.path.join(corrected_mask_dir, file)
        subprocess.run(["cp", src_path, dst_path], check=True)

    print("Done")

if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Usage: python prepare_IXI.py <input_dir> <data_dir>")
        sys.exit(1)

    input_dir = sys.argv[1]
    data_dir = sys.argv[2]

    if not os.path.isabs(input_dir):
        print("Please use absolute paths for input_dir")
        sys.exit(1)

    main(input_dir, data_dir)