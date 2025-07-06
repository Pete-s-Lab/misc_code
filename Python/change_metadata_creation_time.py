# ********************************************************
# Calibrates image according to underlying mesh.
# 
# Peter T. Rühr, June 2025
# v. 0.0.9008
# *******************************************************/

import os
import sys
import time
import piexif
import re
from datetime import datetime
from PIL import Image

def extract_datetime_from_filename(filename):
    """Extracts datetime from filenames like xyz_YYYYMMDD_HHMMSS.jpg, YYYYMMDD_HHMMSS.jpg, or YYYYMMDDHHMMSS.jpg."""
    basename = os.path.basename(filename)
    name, ext = os.path.splitext(basename)

    try:
        if name.startswith("IMG_"):  # Format: IMG_YYYYMMDD_HHMMSS
            date_str, time_str = name[4:].split("_")
        elif re.match(r"PTR-\w{2}-\d{3}_\d{8}_\d{6}$", name):  # Format: PTR-XX-000_YYYYMMDD_HHMMSS
            date_str, time_str = name[-15:-7], name[-6:]
        elif "_" in name:  # Format: YYYYMMDD_HHMMSS
            date_str, time_str = name.split("_")
        else:  # Format: YYYYMMDDHHMMSS
            date_str, time_str = name[:8], name[8:14]
        
        formatted_datetime = datetime.strptime(date_str + time_str, "%Y%m%d%H%M%S")
        return formatted_datetime
    except ValueError:
        return None  # Return None if the format is incorrect

def update_exif_date(image_path):
    """Updates the EXIF metadata timestamps of an image."""
    new_datetime = extract_datetime_from_filename(image_path)
    if not new_datetime:
        print(f"Skipping {image_path}: Filename format is incorrect.")
        return

    new_exif_date = new_datetime.strftime("%Y:%m:%d %H:%M:%S")  # EXIF format

    try:
        img = Image.open(image_path)

        # Load existing EXIF data or create a new dictionary if missing
        exif_data = img.info.get("exif", None)
        if exif_data:
            exif_dict = piexif.load(exif_data)
        else:
            exif_dict = {"0th": {}, "Exif": {}, "GPS": {}, "Interop": {}, "1st": {}, "thumbnail": None}

        # Update the relevant EXIF fields
        exif_dict["Exif"][piexif.ExifIFD.DateTimeOriginal] = new_exif_date.encode()
        exif_dict["Exif"][piexif.ExifIFD.DateTimeDigitized] = new_exif_date.encode()
        exif_dict["0th"][piexif.ImageIFD.DateTime] = new_exif_date.encode()

        # Save the updated EXIF data
        exif_bytes = piexif.dump(exif_dict)
        img.save(image_path, "jpeg", exif=exif_bytes)

        # print(f"Updated EXIF metadata: {image_path} -> {new_exif_date}")

    except Exception as e:
        print(f"Error updating EXIF metadata for {image_path}: {e}")

def update_file_timestamps(image_path):
    """Updates the file system timestamps (created & modified) based on filename."""
    new_datetime = extract_datetime_from_filename(image_path)
    if not new_datetime:
        return

    new_timestamp = time.mktime(new_datetime.timetuple())  # Convert to Unix timestamp

    try:
        # Set "Date modified" and "Date accessed"
        os.utime(image_path, (new_timestamp, new_timestamp))

        # Set "Date created" (Windows only)
        if os.name == 'nt':  # Windows
            import ctypes
            from ctypes import wintypes

            FILETIME = wintypes.LARGE_INTEGER
            kernel32 = ctypes.windll.kernel32

            handle = kernel32.CreateFileW(
                image_path, 256, 0, None, 3, 128, None
            )
            if handle == -1:
                raise Exception("Could not open file for date modification")

            new_filetime = int(new_timestamp * 10000000) + 116444736000000000
            ctime = FILETIME(new_filetime)

            kernel32.SetFileTime(handle, ctypes.byref(ctime), None, ctypes.byref(ctime))
            kernel32.CloseHandle(handle)

        print(f"Updated Updated EXIF metadata and file timestamps: {image_path} -> {new_datetime}")

    except Exception as e:
        print(f"Error updating timestamps for {image_path}: {e}")

def process_directory(directory):
    """Processes all JPEG images in a directory."""
    if not os.path.exists(directory):
        print(f"Error: Directory '{directory}' does not exist.")
        return
    
    for filename in os.listdir(directory):
        if filename.lower().endswith(('.jpg', '.jpeg')):
            image_path = os.path.join(directory, filename)
            update_exif_date(image_path)  # Update EXIF metadata
            update_file_timestamps(image_path)  # Update file system timestamps

# Check if a directory was provided via command line
if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python '2025-02-15 - change_file_date.py' 'C:\\path\\to\\your\\images'")
    else:
        process_directory(sys.argv[1])
