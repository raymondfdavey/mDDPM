import os
import sys
import subprocess
from pathlib import Path

def main(input_dir, output_dir):
    # Create the output directory if it doesn't exist
    Path(output_dir).mkdir(parents=True, exist_ok=True)

    # Resample the images
    resample_command = [
        "python", "resample.py",
        "-i", input_dir,
        "-o", output_dir,
        "-r", "1.0", "1.0", "1.0",
        "-or", "RAI"
    ]
    subprocess.run(resample_command, check=True)

    # Normalize the images
    normalize_command = [
        "python", "normalize.py",
        "-i", output_dir
    ]
    subprocess.run(normalize_command, check=True)

    print("Preprocessing completed successfully!")

if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Usage: python prepare_IXI.py <input_dir> <output_dir>")
        sys.exit(1)

    input_dir = sys.argv[1]
    output_dir = sys.argv[2]

    main(input_dir, output_dir)